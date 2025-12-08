/// Dashboard view showing protection status and recent logs
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';
import '../config/theme.dart';
import '../widgets/index.dart';

/// Main dashboard showing scanner status, stats and recent logs
class DashboardView extends StatelessWidget {
  final bool isRunning;
  final List<ScanLog> logs;
  final AnimationController radarController;
  final VoidCallback onToggle;
  final VoidCallback? onSimulate;
  final bool isWide;

  const DashboardView({
    super.key,
    required this.isRunning,
    required this.logs,
    required this.radarController,
    required this.onToggle,
    this.onSimulate,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    int safeCount = logs.where((l) => l.status == ScanStatus.safe).length;
    int badCount = logs.where((l) => l.status == ScanStatus.malicious).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildRadarButton(),
          const SizedBox(height: 10),
          _buildStatusText(),
          if (kIsWeb && onSimulate != null) ...[
            const SizedBox(height: 20),
            _buildSimulateButton(),
          ],
          const SizedBox(height: 30),
          _buildStatsRow(safeCount, badCount),
          const SizedBox(height: 20),
          _buildLogsList(),
        ],
      ),
    );
  }

  Widget _buildRadarButton() {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isRunning) _buildRadarAnimation(),
          _buildScanButton(),
        ],
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return RotationTransition(
      turns: radarController,
      child: Container(
        width: AppDimensions.radarSize,
        height: AppDimensions.radarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              AppTheme.primary.withOpacity(0),
              AppTheme.primary.withOpacity(0.5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    Color borderColor =
        isRunning ? AppTheme.primary : AppTheme.danger;
    Color iconColor = borderColor;
    String statusText = isRunning ? "SCANNING" : "INACTIVE";
    IconData icon = isRunning ? Icons.radar : Icons.power_settings_new;

    return Container(
      width: AppDimensions.scanButtonSize,
      height: AppDimensions.scanButtonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: iconColor),
          const SizedBox(height: 10),
          Text(
            statusText,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return Text(
      isRunning ? "Tap to STOP" : "Tap to ACTIVATE",
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
    );
  }

  Widget _buildSimulateButton() {
    return ElevatedButton.icon(
      onPressed: onSimulate,
      icon: const Icon(Icons.bug_report),
      label: const Text("SIMULATE MESSAGE (WEB TEST)"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatsRow(int safeCount, int badCount) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: "SAFE",
            count: safeCount,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: StatCard(
            label: "THREATS",
            count: badCount,
            color: AppTheme.danger,
          ),
        ),
      ],
    );
  }

  Widget _buildLogsList() {
    if (logs.isNotEmpty) {
      return Column(
        children: logs.take(3).map((l) => LogTile(log: l)).toList(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.white30),
          SizedBox(width: 10),
          Text(
            "No recent events",
            style: TextStyle(color: Colors.white30),
          ),
        ],
      ),
    );
  }
}
