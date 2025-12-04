/// Models for LinkGuard application
/// Contains all data models and enums used across the app

enum AppSource { zalo, messenger, manual, qr, image }

enum ScanStatus { safe, malicious, scanning, unknown }

/// Represents a scan log entry with URL and metadata
class ScanLog {
  final String id;
  final String sender;
  final String content;
  final String link;
  final AppSource source;
  final DateTime time;
  ScanStatus status;

  ScanLog({
    required this.id,
    required this.sender,
    required this.content,
    required this.link,
    required this.source,
    required this.time,
    this.status = ScanStatus.scanning,
  });
}
