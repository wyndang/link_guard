/// Main screen with tab navigation
import 'dart:math';
import 'dart:async';
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
    print('📱 [LOG ADDED] New message caught:');
    print('   - From: $sender');
    print('   - Content: $content');
    print('   - Link: $link');
    print('   - Source: $source');

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

    print('   ✓ Log added to history (total: ${logs.length})');

    // Check URL safety
    print('   🔍 Checking URL with Google Safe Browsing...');
    UrlScanService.checkUrl(link).then((status) {
      if (!mounted) return;
      setState(() => newLog.status = status);

      print('   ✓ Check complete. Status: $status');

      if (status == ScanStatus.malicious) {
        print('   ⚠️ MALICIOUS link detected!');
        _showDangerAlert(newLog);
      } else if (source == AppSource.manual ||
          source == AppSource.qr ||
          source == AppSource.image) {
        print('   ✓ Safe link - user can proceed');
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
      // Check if notification listener is enabled
      try {
        bool isEnabled = await NotificationService.isNotificationListenerEnabled();
        
        if (!isEnabled) {
          print("⚠️ Notification listener not enabled");
          // Show dialog explaining the requirement
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Enable Notification Listener'),
                content: const Text(
                  'To detect messages from Zalo and Messenger, you need to enable '
                  'the notification listener for this app. '
                  '\n\nTap "Enable" to go to the settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      NotificationService.requestNotificationListenerPermission();
                    },
                    child: const Text('Enable'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        print("Error checking notification listener: $e");
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
    print('🧪 [TEST] Simulating message from Messenger/Zalo...');
    
    if (!_isRunning) {
      print('   ⚠️ Protection not enabled');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable protection first!")),
      );
      return;
    }

    // Generate random test message
    bool isBad = Random().nextBool();
    String link = isBad 
        ? "http://phishing-site.xyz/login?token=fake" 
        : "https://youtube.com/watch?v=dQw4w9WgXcQ";
    
    AppSource source = Random().nextBool() ? AppSource.zalo : AppSource.messenger;
    
    String senderName = source == AppSource.zalo ? "Zalo Bot" : "Facebook Messenger";
    String messageContent = isBad 
        ? "Hi! Verify your account: $link" 
        : "Check out this video: $link";

    print('   📨 Simulated message:');
    print('   - From: $senderName');
    print('   - Content: $messageContent');
    print('   - Link: $link');
    print('   - Type: ${isBad ? "MALICIOUS" : "SAFE"}');

    _addLog(
      senderName,
      messageContent,
      link,
      source,
    );
    
    print('   ✓ Message added to history');
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
