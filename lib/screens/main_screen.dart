/// Main screen with tab navigation
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';
import '../config/theme.dart';
import '../services/url_scan_service.dart';
import '../services/notification_service.dart';
import '../widgets/index.dart';
import 'index.dart';

/// Root screen with tab navigation and notification handling
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _tabIndex = 0;
  bool _isRunning = false;
  List<ScanLog> logs = [];
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: AppConstants.radarDuration,
    );

    // Auto-start on Web for testing
    if (kIsWeb) {
      _isRunning = true;
      _radarController.repeat();
    }

    _initNotificationListener();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  /// Initialize background notification listener
  Future<void> _initNotificationListener() async {
    await NotificationService.initialize((sender, content, link, source) {
      // Duplicate check: ignore same link within 2 seconds
      if (logs.isNotEmpty &&
          logs.first.link == link &&
          DateTime.now().difference(logs.first.time).inSeconds <
              AppConstants.duplicateCheckWindow) {
        return;
      }
      _addLog(sender, content, link, source);
    });
  }

  /// Add new scan log and check URL
  void _addLog(String sender, String content, String link, AppSource source) {
    final newLog = ScanLog(
      id: DateTime.now().toString(),
      sender: sender,
      content: content,
      link: link,
      source: source,
      time: DateTime.now(),
      status: ScanStatus.scanning,
    );

    setState(() => logs.insert(0, newLog));

    // Check URL safety
    UrlScanService.checkUrl(link).then((status) {
      if (!mounted) return;
      setState(() => newLog.status = status);

      if (status == ScanStatus.malicious) {
        _showDangerAlert(newLog);
      } else if (source == AppSource.manual ||
          source == AppSource.qr ||
          source == AppSource.image) {
        _showSafeNotification();
      }
    });
  }

  /// Toggle background scanning service
  Future<void> _toggleService() async {
    if (kIsWeb) {
      setState(() {
        _isRunning = !_isRunning;
        if (_isRunning) {
          _radarController.repeat();
        } else {
          _radarController.stop();
        }
      });
      return;
    }

    if (!_isRunning) {
      bool granted = await NotificationService.hasPermission();
      if (!granted) {
        await NotificationService.openPermissionSettings();
        return;
      }
      await NotificationService.startService();
      _radarController.repeat();
    } else {
      await NotificationService.stopService();
      _radarController.stop();
    }

    setState(() => _isRunning = !_isRunning);
  }

  /// Simulate message for Web testing
  void _simulateMessage() {
    if (!_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable protection first!")),
      );
      return;
    }

    bool isBad = Random().nextBool();
    String link =
        isBad ? "http://hack-acc.com/login" : "https://youtube.com";
    _addLog(
      "Test User (Web)",
      "Check this link: $link",
      link,
      Random().nextBool() ? AppSource.zalo : AppSource.messenger,
    );
  }

  /// Show danger alert for malicious URL
  void _showDangerAlert(ScanLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DangerAlert(log: log),
    );
  }

  /// Show notification for safe URL
  void _showSafeNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Link Safe!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWide = screenWidth > AppDimensions.wideScreenBreakpoint;
    double horizontalPadding = isWide
        ? screenWidth * AppDimensions.wideScreenPaddingMultiplier
        : 0;

    return Container(
      decoration: AppTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildTabContent(isWide),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: GlassNavBar(
            currentIndex: _tabIndex,
            onTap: (i) => setState(() => _tabIndex = i),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_moon,
                color: AppTheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: AppTheme.primary.withOpacity(0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "WEB MODE",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isWide) {
    return IndexedStack(
      index: _tabIndex,
      children: [
        DashboardView(
          isRunning: _isRunning,
          logs: logs,
          radarController: _radarController,
          onToggle: _toggleService,
          onSimulate: _simulateMessage,
          isWide: isWide,
        ),
        ManualScanView(
          isWide: isWide,
          onScan: (link, source) {
            _addLog("You", "Manual Scan", link, source);
            setState(() => _tabIndex = 2);
          },
        ),
        HistoryView(logs: logs),
      ],
    );
  }
}
