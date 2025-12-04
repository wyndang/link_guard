/// Theme configuration and app constants
import 'package:flutter/material.dart';

class AppTheme {
  /// Primary cyan color
  static const Color primary = Color(0xFF00E5FF);

  /// Secondary pink color
  static const Color secondary = Color(0xFFD500F9);

  /// Main background color
  static const Color background = Color(0xFF0B1120);

  /// Surface color
  static const Color surface = Color(0xFF1E293B);

  /// Dark background
  static const Color darkBg = Color(0xFF0F172A);

  /// Error red color
  static const Color error = Color(0xFF1E0505);

  /// Success green color
  static const Color success = Colors.green;

  /// Danger red color
  static const Color danger = Colors.red;

  /// Light text color (primary)
  static const Color textLight = Colors.white;

  /// Secondary text color
  static const Color textSecondary = Colors.white54;

  /// Tertiary text color
  static const Color textTertiary = Colors.white30;

  /// Get Material theme
  static ThemeData getTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      useMaterial3: true,
    );
  }

  /// Get background gradient
  static const BoxDecoration backgroundGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [darkBg, surface, Color(0xFF000000)],
    ),
  );
}

class AppConstants {
  static const String appName = "LINKGUARD";
  static const String appVersion = "1.0";

  /// Google Safe Browsing API key
  static const String gsb_api_key = "AIzaSyCblqIrEpozkWbxDj9emCqGbiPe1Oe0MG8";

  /// Duplicate link detection time window (seconds)
  static const int duplicateCheckWindow = 2;

  /// Radar animation duration
  static const Duration radarDuration = Duration(seconds: 4);

  /// Glass box blur amount
  static const double glassBlurSigma = 10.0;

  /// Glass box opacity
  static const double glassOpacity = 0.05;
}

class AppDimensions {
  static const double defaultPadding = 20.0;
  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 12.0;
  static const double largeBorderRadius = 35.0;

  static const double radarSize = 220.0;
  static const double scanButtonSize = 180.0;

  static const double navBarHeight = 70.0;
  static const double topBarHeight = 60.0;

  /// Breakpoint for wide screen (tablet/desktop)
  static const double wideScreenBreakpoint = 800.0;

  /// Horizontal padding multiplier for wide screens
  static const double wideScreenPaddingMultiplier = 0.2;
}
