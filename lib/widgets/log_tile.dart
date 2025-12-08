/// Log tile widget for displaying scan results
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'glass_box.dart';

/// Displays a single scan log entry
class LogTile extends StatelessWidget {
  final ScanLog log;

  const LogTile({super.key, required this.log});

  Color _getStatusColor() {
    return log.status == ScanStatus.safe
        ? Colors.green
        : (log.status == ScanStatus.malicious ? Colors.red : Colors.orange);
  }

  IconData _getStatusIcon() {
    return log.status == ScanStatus.safe
        ? Icons.check_circle
        : (log.status == ScanStatus.malicious ? Icons.warning : Icons.sync);
  }

  String _getSourceText() {
    return log.source.toString().split('.').last.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Color color = _getStatusColor();
    IconData icon = _getStatusIcon();
    String sourceText = _getSourceText();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassBox(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.sender,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    log.link,
                    style: TextStyle(
                      color: Colors.blue[200],
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              sourceText,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
