/// Statistics card widget
import 'package:flutter/material.dart';
import 'glass_box.dart';

/// Displays a stat with label, count and color
class StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "$count",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
