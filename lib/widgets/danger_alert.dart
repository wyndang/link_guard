/// Danger alert dialog for malicious URLs
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../config/theme.dart';

/// Shows warning modal for detected malicious link
class DangerAlert extends StatelessWidget {
  final ScanLog log;

  const DangerAlert({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Color(0xFF1E0505),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: AppTheme.danger, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gpp_bad, color: AppTheme.danger, size: 60),
          const SizedBox(height: 20),
          const Text(
            "WARNING!",
            style: TextStyle(
              color: AppTheme.danger,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Malicious link detected.",
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              log.link,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                "GOT IT - BLOCK NOW",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
