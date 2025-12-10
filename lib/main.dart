import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/index.dart';
import 'services/url_scan_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables and services
  try {
    await UrlScanService.initialize();
  } catch (e) {
    print('⚠️ Failed to initialize services: $e');
  }
  
  runApp(const LinkGuardApp());
}

/// Main LinkGuard application
class LinkGuardApp extends StatelessWidget {
  const LinkGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.getTheme(),
      home: const MainScreen(),
    );
  }
}
