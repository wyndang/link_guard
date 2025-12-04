/// Notification listener service for background scanning
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../models/models.dart';
import 'url_scan_service.dart';

/// Callback function signature for notification events
typedef NotificationCallback = void Function(
    String sender, String content, String link, AppSource source);

/// Service to listen for notifications and extract links
class NotificationService {
  /// Initialize notification listener
  /// Only works on native platforms (not Web)
  static Future<void> initialize(NotificationCallback onLinkDetected) async {
    if (kIsWeb) return;

    try {
      NotificationsListener.initialize(
        callbackHandle: _onBackgroundNotification,
      );
      NotificationsListener.receivePort?.listen((evt) {
        _handleNotification(evt, onLinkDetected);
      });
    } catch (e) {
      print("Notification Listener Init Error: $e");
    }
  }

  /// Start notification monitoring service
  static Future<void> startService() async {
    if (kIsWeb) return;

    try {
      await NotificationsListener.startService(
        foreground: false,
        title: "LinkGuard Active",
        description: "Scanning...",
      );
    } catch (e) {
      print("Start Service Error: $e");
    }
  }

  /// Stop notification monitoring service
  static Future<void> stopService() async {
    if (kIsWeb) return;

    try {
      await NotificationsListener.stopService();
    } catch (e) {
      print("Stop Service Error: $e");
    }
  }

  /// Check if notification permission is granted
  static Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    return await NotificationsListener.hasPermission ?? false;
  }

  /// Open permission settings
  static Future<void> openPermissionSettings() async {
    if (kIsWeb) return;
    await NotificationsListener.openPermissionSettings();
  }

  /// Handle notification events
  static void _handleNotification(
      NotificationEvent event, NotificationCallback onLinkDetected) {
    AppSource? source;
    String? packageName = event.packageName;

    if (packageName != null) {
      if (packageName.contains("zalo")) source = AppSource.zalo;
      if (packageName.contains("orca") || packageName.contains("messenger")) {
        source = AppSource.messenger;
      }
    }

    if (source == null || event.message == null) return;

    String? link = UrlScanService.extractLink(event.message!);
    if (link != null) {
      onLinkDetected(event.title ?? "Unknown", event.message!, link, source);
    }
  }
}

/// Background notification handler
@pragma('vm:entry-point')
void _onBackgroundNotification(NotificationEvent event) {
  print("Background Event: ${event.packageName} - ${event.title}");
}
