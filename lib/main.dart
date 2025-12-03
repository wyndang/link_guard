import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // UI Blur
import 'dart:math'; // Thêm lại thư viện này để dùng Random()
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'; // Để bắt lỗi PlatformException
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // REAL QR SCANNER
import 'package:image_picker/image_picker.dart';     // REAL IMAGE PICKER
// ĐÃ XÓA import 'dart:io'; vì nó gây lỗi trên Web

// --- 1. BACKGROUND SERVICE (REAL DATA) ---
@pragma('vm:entry-point')
void onNotificationEvent(NotificationEvent event) {
  print("Background Event: ${event.packageName} - ${event.title}");
}

// --- 2. APP ENTRY ---
void main() {
  runApp(const LinkScannerApp());
}

class LinkScannerApp extends StatelessWidget {
  const LinkScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinkGuard',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFD500F9),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// --- 3. MODELS ---
enum AppSource { zalo, messenger, manual, qr, image }
enum ScanStatus { safe, malicious, scanning, unknown }

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

// --- 4. MAIN SCREEN ---
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
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 4));

    // Tự động chạy giả lập nếu là Web để test UI
    if (kIsWeb) {
      _isRunning = true;
      _radarController.repeat();
    }

    _initListener();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  // Init Real Notification Listener
  Future<void> _initListener() async {
    if (kIsWeb) return; // Web không hỗ trợ lắng nghe thông báo nền
    try {
      NotificationsListener.initialize(callbackHandle: onNotificationEvent);
      NotificationsListener.receivePort?.listen((evt) => _onNotification(evt));
    } catch (e) {
      print("Listener Init Error: $e");
    }
  }

  void _onNotification(NotificationEvent event) {
    if (!_isRunning) return;
    AppSource? src;
    String? pkg = event.packageName;

    if (pkg != null) {
      if (pkg.contains("zalo")) src = AppSource.zalo;
      if (pkg.contains("orca") || pkg.contains("messenger")) src = AppSource.messenger;
    }

    if (src == null || event.message == null) return;

    String? link = _extractLink(event.message!);
    if (link != null) {
      if (logs.isNotEmpty && logs.first.link == link &&
          DateTime.now().difference(logs.first.time).inSeconds < 2) return;
      _addLog(event.title ?? "Unknown", event.message!, link, src);
    }
  }

  String? _extractLink(String text) {
    RegExp exp = RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    return exp.firstMatch(text)?.group(0);
  }

  Future<ScanStatus> checkUrlWithGoogleSafeBrowsing(String url) async {
    // TODO: Connect Real API Here
    await Future.delayed(const Duration(seconds: 1));
    bool isBad = url.contains("virus") || url.contains("hack") || url.contains("http://");
    return isBad ? ScanStatus.malicious : ScanStatus.safe;
  }

  void _addLog(String sender, String content, String link, AppSource src) {
    final newLog = ScanLog(
      id: DateTime.now().toString(),
      sender: sender,
      content: content,
      link: link,
      source: src,
      time: DateTime.now(),
      status: ScanStatus.scanning,
    );

    setState(() => logs.insert(0, newLog));

    checkUrlWithGoogleSafeBrowsing(link).then((status) {
      if (!mounted) return;
      setState(() => newLog.status = status);
      if (status == ScanStatus.malicious) {
        _showAlert(newLog);
      } else {
        if (src == AppSource.manual || src == AppSource.qr || src == AppSource.image) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link Safe!"), backgroundColor: Colors.green));
        }
      }
    });
  }

  void _toggleService() async {
    if (kIsWeb) {
      // Trên Web chỉ giả lập bật tắt
      setState(() {
        _isRunning = !_isRunning;
        if (_isRunning) _radarController.repeat(); else _radarController.stop();
      });
      return;
    }

    if (!_isRunning) {
      bool granted = await NotificationsListener.hasPermission ?? false;
      if (!granted) {
        await NotificationsListener.openPermissionSettings();
        return;
      }
      await NotificationsListener.startService(
          foreground: false,
          title: "LinkGuard Active",
          description: "Scanning..."
      );
      _radarController.repeat();
    } else {
      await NotificationsListener.stopService();
      _radarController.stop();
    }
    setState(() => _isRunning = !_isRunning);
  }

  // Giả lập tin nhắn trên Web để test
  void _simulateMessage() {
    if (!_isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enable protection first!")));
      return;
    }
    bool isBad = Random().nextBool();
    String link = isBad ? "http://hack-acc.com/login" : "https://youtube.com";
    _addLog("Test User (Web)", "Check this link: $link", link,
        Random().nextBool() ? AppSource.zalo : AppSource.messenger);
  }

  void _showAlert(ScanLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DangerAlert(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWide = screenWidth > 800;
    double hPadding = isWide ? screenWidth * 0.2 : 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF000000)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: IndexedStack(
                    index: _tabIndex,
                    children: [
                      DashboardView(
                        isRunning: _isRunning,
                        logs: logs,
                        radarController: _radarController,
                        onToggle: _toggleService,
                        onSimulate: _simulateMessage, // Truyền hàm giả lập cho Web
                        isWide: isWide,
                      ),
                      ManualScanView(
                        isWide: isWide,
                        onScan: (link, src) {
                          _addLog("You", "Manual Scan", link, src);
                          setState(() => _tabIndex = 2);
                        },
                      ),
                      HistoryView(logs: logs),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
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
              const Icon(Icons.shield_moon, color: Color(0xFF00E5FF), size: 28),
              const SizedBox(width: 10),
              Text(
                "LINKGUARD",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: const Color(0xFF00E5FF).withOpacity(0.8), blurRadius: 10)]
                ),
              ),
            ],
          ),
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
              child: const Text("WEB MODE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }
}

// --- DASHBOARD ---
class DashboardView extends StatelessWidget {
  final bool isRunning;
  final List<ScanLog> logs;
  final AnimationController radarController;
  final VoidCallback onToggle;
  final VoidCallback? onSimulate; // Hàm này cần thiết cho Web
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
          GestureDetector(
            onTap: onToggle,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isRunning)
                  RotationTransition(
                    turns: radarController,
                    child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(colors: [const Color(0xFF00E5FF).withOpacity(0), const Color(0xFF00E5FF).withOpacity(0.5)]),
                      ),
                    ),
                  ),
                Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                    border: Border.all(color: isRunning ? const Color(0xFF00E5FF) : Colors.red, width: 2),
                    boxShadow: [BoxShadow(color: (isRunning ? const Color(0xFF00E5FF) : Colors.red).withOpacity(0.3), blurRadius: 30)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isRunning ? Icons.radar : Icons.power_settings_new, size: 50, color: isRunning ? const Color(0xFF00E5FF) : Colors.red),
                      const SizedBox(height: 10),
                      Text(isRunning ? "SCANNING" : "INACTIVE", style: TextStyle(color: isRunning ? const Color(0xFF00E5FF) : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(isRunning ? "Tap to STOP" : "Tap to ACTIVATE", style: const TextStyle(color: Colors.white54, fontSize: 12)),

          // Nút giả lập cho Web
          if (kIsWeb && onSimulate != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onSimulate,
              icon: const Icon(Icons.bug_report),
              label: const Text("SIMULATE MESSAGE (WEB TEST)"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            )
          ],

          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(child: _StatCard(label: "SAFE", count: safeCount, color: Colors.green)),
              const SizedBox(width: 15),
              Expanded(child: _StatCard(label: "THREATS", count: badCount, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 20),
          if (logs.isNotEmpty) Column(children: logs.take(3).map((l) => LogTile(log: l)).toList())
          else Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(15)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, color: Colors.white30), SizedBox(width: 10), Text("No recent events", style: TextStyle(color: Colors.white30))]),
          ),
        ],
      ),
    );
  }
}

// --- MANUAL SCAN (REAL CAMERA & GALLERY) ---
class ManualScanView extends StatefulWidget {
  final Function(String, AppSource) onScan;
  final bool isWide;
  const ManualScanView({super.key, required this.onScan, required this.isWide});

  @override
  State<ManualScanView> createState() => _ManualScanViewState();
}

class _ManualScanViewState extends State<ManualScanView> {
  final _ctrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void _openQRScanner() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RealQRScannerScreen()),
      );

      if (result != null && result is String) {
        widget.onScan(result, AppSource.qr);
      }
    } on MissingPluginException {
      _showRestartWarning();
    } catch (e) {
      _showError("Scanner Error: $e");
    }
  }

  void _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final controller = MobileScannerController();
      // analyzeImage might not work on Web without proper setup/cors
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? code = capture.barcodes.first.rawValue;
        if (code != null) {
          widget.onScan(code, AppSource.image);
        } else {
          _showError("QR Code found but empty.");
        }
      } else {
        _showError("No QR Code found in this image.");
      }
      controller.dispose();
    } on MissingPluginException {
      _showRestartWarning();
    } catch (e) {
      _showError("Error analyzing image: $e");
    }
  }

  void _showRestartWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Native Plugin Error: Please restart the app (Hot Restart doesn't load new plugins)."),
          backgroundColor: Colors.red,
        )
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: Colors.white24),
          const SizedBox(height: 20),
          const Text("MANUAL SCAN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("Enter URL, Scan QR or Import Image", style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 40),

          TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true, fillColor: Colors.white.withOpacity(0.1),
              hintText: "Enter URL (https://...)", hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.link, color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: widget.isWide ? 300 : double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_ctrl.text.isNotEmpty) {
                  widget.onScan(_ctrl.text, AppSource.manual);
                  _ctrl.clear();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("CHECK NOW", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openQRScanner, // CALL REAL FUNCTION
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("SCAN QR"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.white30)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery, // CALL REAL FUNCTION
                  icon: const Icon(Icons.image),
                  label: const Text("GALLERY"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.white30)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- REAL QR SCANNER SCREEN ---
class RealQRScannerScreen extends StatelessWidget {
  const RealQRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code"), backgroundColor: Colors.black),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          returnImage: false,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            Navigator.pop(context, code); // Return result
          }
        },
      ),
    );
  }
}

// --- HISTORY & WIDGETS ---
class HistoryView extends StatelessWidget {
  final List<ScanLog> logs;
  const HistoryView({super.key, required this.logs});
  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const Center(child: Text("No scan history", style: TextStyle(color: Colors.white30)));
    return ListView.builder(padding: const EdgeInsets.all(20), itemCount: logs.length, itemBuilder: (ctx, i) => LogTile(log: logs[i]));
  }
}

class LogTile extends StatelessWidget {
  final ScanLog log;
  const LogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    Color color = log.status == ScanStatus.safe ? Colors.green : (log.status == ScanStatus.malicious ? Colors.red : Colors.orange);
    IconData icon = log.status == ScanStatus.safe ? Icons.check_circle : (log.status == ScanStatus.malicious ? Icons.warning : Icons.sync);
    String sourceText = log.source.toString().split('.').last.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassBox(
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(log.sender, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(log.link, style: TextStyle(color: Colors.blue[200], fontSize: 12, decoration: TextDecoration.underline), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Text(sourceText, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class DangerAlert extends StatelessWidget {
  final ScanLog log;
  const DangerAlert({super.key, required this.log});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(color: Color(0xFF1E0505), borderRadius: BorderRadius.vertical(top: Radius.circular(30)), border: Border(top: BorderSide(color: Colors.red, width: 2))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.gpp_bad, color: Colors.red, size: 60),
        const SizedBox(height: 20),
        const Text("WARNING!", style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text("Malicious link detected.", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)), child: Text(log.link, style: const TextStyle(color: Colors.redAccent))),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(16)), child: const Text("GOT IT - BLOCK NOW", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))))
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label; final int count; final Color color;
  const _StatCard({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      const SizedBox(height: 5),
      Text("$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24))
    ]));
  }
}

class GlassBox extends StatelessWidget {
  final Widget child;
  const GlassBox({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))), child: child)));
  }
}

// --- CẬP NHẬT NAV BAR (SỬA LỖI TAB KHÔNG NHẠY) ---
class GlassNavBar extends StatelessWidget {
  final int currentIndex; final Function(int) onTap;
  const GlassNavBar({super.key, required this.currentIndex, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20), height: 70,
      decoration: BoxDecoration(color: const Color(0xFF1E293B).withOpacity(0.8), borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _item(0, Icons.dashboard, "HOME"),
        _item(1, Icons.qr_code_scanner, "MANUAL"),
        _item(2, Icons.history, "HISTORY"),
      ]),
    );
  }

  // Dùng Expanded để nút chiếm hết không gian, dễ bấm hơn
  Widget _item(int index, IconData icon, String label) {
    bool active = currentIndex == index;
    return Expanded(
      child: GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: active ? BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.2), borderRadius: BorderRadius.circular(20)) : null,
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: active ? const Color(0xFF00E5FF) : Colors.white54),
                          if (active) ...[const SizedBox(width: 8), Text(label, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12))]
                        ]
                    )
                )
              ]
          )
      ),
    );
  }
}