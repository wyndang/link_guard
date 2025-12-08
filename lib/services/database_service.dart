/// Local SQLite database service for storing scan history
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// Manages local SQLite database for scan logs
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Get or create database
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocDir.path, 'link_guard.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createTables,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Scan logs table
    await db.execute('''
      CREATE TABLE scan_logs (
        id TEXT PRIMARY KEY,
        sender TEXT NOT NULL,
        content TEXT NOT NULL,
        link TEXT NOT NULL,
        source TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_timestamp ON scan_logs(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_source ON scan_logs(source)
    ''');

    await db.execute('''
      CREATE INDEX idx_status ON scan_logs(status)
    ''');

    print('✓ Database tables created');
  }

  /// Insert a scan log
  Future<int> insertScanLog(ScanLog log) async {
    final db = await database;
    try {
      final result = await db.insert(
        'scan_logs',
        {
          'id': log.id,
          'sender': log.sender,
          'content': log.content,
          'link': log.link,
          'source': _sourceToString(log.source),
          'status': _statusToString(log.status),
          'timestamp': log.time.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✓ Scan log inserted: ${log.link}');
      return result;
    } catch (e) {
      print('❌ Error inserting scan log: $e');
      return -1;
    }
  }

  /// Get all scan logs (sorted by newest first)
  Future<List<ScanLog>> getAllLogs() async {
    final db = await database;
    try {
      final results = await db.query(
        'scan_logs',
        orderBy: 'timestamp DESC',
      );

      return results
          .map((map) => _mapToScanLog(map))
          .toList();
    } catch (e) {
      print('❌ Error fetching logs: $e');
      return [];
    }
  }

  /// Get logs by date range
  Future<List<ScanLog>> getLogsByDateRange(DateTime from, DateTime to) async {
    final db = await database;
    try {
      final results = await db.query(
        'scan_logs',
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [
          from.millisecondsSinceEpoch,
          to.millisecondsSinceEpoch,
        ],
        orderBy: 'timestamp DESC',
      );

      return results
          .map((map) => _mapToScanLog(map))
          .toList();
    } catch (e) {
      print('❌ Error fetching logs by date range: $e');
      return [];
    }
  }

  /// Get logs by source (zalo, messenger, manual, etc)
  Future<List<ScanLog>> getLogsBySource(AppSource source) async {
    final db = await database;
    try {
      final results = await db.query(
        'scan_logs',
        where: 'source = ?',
        whereArgs: [_sourceToString(source)],
        orderBy: 'timestamp DESC',
      );

      return results
          .map((map) => _mapToScanLog(map))
          .toList();
    } catch (e) {
      print('❌ Error fetching logs by source: $e');
      return [];
    }
  }

  /// Get logs by status (malicious, safe, unknown)
  Future<List<ScanLog>> getLogsByStatus(ScanStatus status) async {
    final db = await database;
    try {
      final results = await db.query(
        'scan_logs',
        where: 'status = ?',
        whereArgs: [_statusToString(status)],
        orderBy: 'timestamp DESC',
      );

      return results
          .map((map) => _mapToScanLog(map))
          .toList();
    } catch (e) {
      print('❌ Error fetching logs by status: $e');
      return [];
    }
  }

  /// Get malicious logs
  Future<List<ScanLog>> getMaliciousLogs() async {
    return getLogsByStatus(ScanStatus.malicious);
  }

  /// Get safe logs
  Future<List<ScanLog>> getSafeLogs() async {
    return getLogsByStatus(ScanStatus.safe);
  }

  /// Search logs by sender or link
  Future<List<ScanLog>> searchLogs(String query) async {
    final db = await database;
    try {
      final results = await db.query(
        'scan_logs',
        where: 'sender LIKE ? OR link LIKE ? OR content LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'timestamp DESC',
      );

      return results
          .map((map) => _mapToScanLog(map))
          .toList();
    } catch (e) {
      print('❌ Error searching logs: $e');
      return [];
    }
  }

  /// Get total count of logs
  Future<int> getLogsCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM scan_logs');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Error getting logs count: $e');
      return 0;
    }
  }

  /// Get count of malicious logs
  Future<int> getMaliciousCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM scan_logs WHERE status = ?',
        [_statusToString(ScanStatus.malicious)],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Error getting malicious count: $e');
      return 0;
    }
  }

  /// Update log status
  Future<int> updateLogStatus(String logId, ScanStatus newStatus) async {
    final db = await database;
    try {
      final result = await db.update(
        'scan_logs',
        {'status': _statusToString(newStatus)},
        where: 'id = ?',
        whereArgs: [logId],
      );
      print('✓ Log status updated: $logId -> $newStatus');
      return result;
    } catch (e) {
      print('❌ Error updating log status: $e');
      return -1;
    }
  }

  /// Delete a log
  Future<int> deleteLog(String logId) async {
    final db = await database;
    try {
      final result = await db.delete(
        'scan_logs',
        where: 'id = ?',
        whereArgs: [logId],
      );
      print('✓ Log deleted: $logId');
      return result;
    } catch (e) {
      print('❌ Error deleting log: $e');
      return -1;
    }
  }

  /// Delete logs older than specified days
  Future<int> deleteOldLogs(int daysOld) async {
    final db = await database;
    try {
      final cutoffTime = DateTime.now().subtract(Duration(days: daysOld));
      final result = await db.delete(
        'scan_logs',
        where: 'timestamp < ?',
        whereArgs: [cutoffTime.millisecondsSinceEpoch],
      );
      print('✓ Old logs deleted (older than $daysOld days): $result rows');
      return result;
    } catch (e) {
      print('❌ Error deleting old logs: $e');
      return -1;
    }
  }

  /// Clear all logs
  Future<int> clearAllLogs() async {
    final db = await database;
    try {
      final result = await db.delete('scan_logs');
      print('✓ All logs cleared: $result rows');
      return result;
    } catch (e) {
      print('❌ Error clearing logs: $e');
      return -1;
    }
  }

  /// Export logs to JSON
  Future<List<Map<String, dynamic>>> exportLogsToJson() async {
    final db = await database;
    try {
      final results = await db.query('scan_logs', orderBy: 'timestamp DESC');
      print('✓ Exported ${results.length} logs to JSON');
      return results;
    } catch (e) {
      print('❌ Error exporting logs: $e');
      return [];
    }
  }

  /// Close database
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
    print('✓ Database closed');
  }

  /// Helper: Convert AppSource to string
  String _sourceToString(AppSource source) {
    return source.toString().split('.').last;
  }

  /// Helper: Convert ScanStatus to string
  String _statusToString(ScanStatus status) {
    return status.toString().split('.').last;
  }

  /// Helper: Convert string to AppSource
  AppSource _stringToSource(String source) {
    return AppSource.values.firstWhere(
      (s) => s.toString().split('.').last == source,
      orElse: () => AppSource.manual,
    );
  }

  /// Helper: Convert string to ScanStatus
  ScanStatus _stringToStatus(String status) {
    return ScanStatus.values.firstWhere(
      (s) => s.toString().split('.').last == status,
      orElse: () => ScanStatus.unknown,
    );
  }

  /// Helper: Map database row to ScanLog
  ScanLog _mapToScanLog(Map<String, dynamic> map) {
    return ScanLog(
      id: map['id'] as String,
      sender: map['sender'] as String,
      content: map['content'] as String,
      link: map['link'] as String,
      source: _stringToSource(map['source'] as String),
      time: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: _stringToStatus(map['status'] as String),
    );
  }
}
