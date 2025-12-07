/// Notification listener service for background scanning
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'url_scan_service.dart';

/// Callback function signature for notification events
typedef NotificationCallback = void Function(
    String sender, String content, String link, AppSource source);

/// Service to handle notifications from Zalo and Messenger
/// Uses Android NotificationListenerService to capture system notifications
class NotificationService {
  static late NotificationCallback _onLinkDetected;
  static const platform =
      MethodChannel('com.example.check_link_in_messages/notifications');
  static bool _isInitialized = false;

  /// Initialize notification system
  static Future<void> initialize(NotificationCallback onLinkDetected) async {
    if (kIsWeb || _isInitialized) return;

    _onLinkDetected = onLinkDetected;
    _isInitialized = true;

    try {
      // Setup method channel to receive notifications from native Android
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onNotificationReceived') {
          _handleNotificationFromNative(call.arguments);
        }
      });

      print('✓ NotificationService initialized');
    } catch (e) {
      print("❌ Notification Service Init Error: $e");
    }
  }

  /// Handle notification received from native Android service
  static void _handleNotificationFromNative(dynamic arguments) {
    try {
      final String sender = arguments['sender'] ?? 'Unknown';
      final String content = arguments['content'] ?? '';
      final String source = arguments['source'] ?? 'unknown';
      
      print('📬 [NATIVE] Notification caught from $source:');
      print('   - Sender: $sender');
      print('   - Content: $content');

      // Convert source string to AppSource enum
      AppSource appSource = _parseAppSource(source);

      // Extract link from message
      String? link = UrlScanService.extractLink(content);

      if (link != null && link.isNotEmpty) {
        print('✓ [CAUGHT] Valid link detected: $link');
        _onLinkDetected(sender, content, link, appSource);

        // Show local notification
        _showLinkDetectedNotification(sender, link);
      } else {
        print('⚠️ [WARNING] No link found in message content');
      }
    } catch (e) {
      print("❌ Error handling native notification: $e");
    }
  }

  /// Show local notification when link is detected (placeholder)
  static Future<void> _showLinkDetectedNotification(
      String sender, String link) async {
    try {
      print('📢 Link detected from $sender: $link');
      // Local notifications removed to eliminate permission requirement
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  /// Parse source string to AppSource enum
  static AppSource _parseAppSource(String source) {
    switch (source.toLowerCase()) {
      case 'zalo':
        return AppSource.zalo;
      case 'messenger':
        return AppSource.messenger;
      default:
        return AppSource.manual;
    }
  }

  /// Request notification listener permission
  static Future<bool> requestNotificationListenerPermission() async {
    if (kIsWeb) return false;

    try {
      await platform.invokeMethod('requestNotificationListenerPermission');
      print('✓ Notification listener permission requested');
      return true;
    } catch (e) {
      print("Error requesting permission: $e");
      return false;
    }
  }

  /// Check if notification listener is enabled
  static Future<bool> isNotificationListenerEnabled() async {
    if (kIsWeb) return false;

    try {
      final bool isEnabled =
          await platform.invokeMethod('isNotificationListenerEnabled');
      return isEnabled;
    } catch (e) {
      print("Error checking notification listener status: $e");
      return false;
    }
  }

  /// Start notification monitoring service
  static Future<void> startService() async {
    if (kIsWeb) return;

    try {
      final bool isEnabled = await isNotificationListenerEnabled();
      if (!isEnabled) {
        print("⚠️ Notification listener is not enabled");
        print("Opening notification listener settings...");
        await requestNotificationListenerPermission();
      } else {
        print("✓ Notification listener is already enabled");
      }
    } catch (e) {
      print("Error starting service: $e");
    }
  }

  /// Stop notification monitoring service
  static Future<void> stopService() async {
    if (kIsWeb) return;
    print("Notification service stopped");
  }

  /// Open permission settings
  static Future<void> openPermissionSettings() async {
    if (kIsWeb) return;
    await requestNotificationListenerPermission();
  }

  /// Simulate receiving a notification with a link (for testing)
  static Future<void> simulateNotification(
    String sender,
    String messageContent,
    AppSource source,
  ) async {
    if (kIsWeb) return;

    try {
      print('📬 [DEBUG] Attempting to simulate notification:');
      print('   - Sender: $sender');
      print('   - Content: $messageContent');
      print('   - Source: $source');

      // Extract link from message
      String? link = UrlScanService.extractLink(messageContent);

      print('   - Link extracted: ${link ?? "NOT FOUND"}');

      if (link != null && link.isNotEmpty) {
        print('✓ [CAUGHT] Valid link detected! Calling callback...');

        // Call the callback
        _onLinkDetected(sender, messageContent, link, source);

        print('✓ [CALLBACK] Callback executed');

        // Show local notification
        await _showLinkDetectedNotification(sender, link);

        print('✓ [NOTIFICATION] Notification displayed');
      } else {
        print('⚠️ [WARNING] No link found in message content');
      }
    } catch (e) {
      print("❌ [ERROR] Error simulating notification: $e");
    }
  }
}
    

