import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/index.dart';

void main() {
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
