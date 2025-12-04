/// History view screen showing all scanned URLs
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/log_tile.dart';

/// Displays complete history of all scanned links
class HistoryView extends StatelessWidget {
  final List<ScanLog> logs;

  const HistoryView({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          "No scan history",
          style: TextStyle(color: Colors.white30),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: logs.length,
      itemBuilder: (ctx, i) => LogTile(log: logs[i]),
    );
  }
}
