package com.example.check_link_in_messages;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;
import android.provider.Settings;
import android.os.Build;

/**
 * Main activity for LinkGuard app
 * Handles communication between native Android notification listener and Flutter UI
 */
public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.check_link_in_messages/notifications";
    private static final String TAG = "MainActivity";
    private static MainActivity instance;
    private MethodChannel methodChannel;

    public MainActivity() {
        instance = this;
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        methodChannel = new MethodChannel(
            flutterEngine.getDartExecutor().getBinaryMessenger(),
            CHANNEL
        );

        // Handle method calls from Flutter
        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "startNotificationListener":
                    startNotificationListener();
                    result.success(null);
                    break;

                case "requestNotificationListenerPermission":
                    openNotificationListenerSettings();
                    result.success(null);
                    break;

                case "isNotificationListenerEnabled":
                    boolean isEnabled = isNotificationListenerEnabled();
                    result.success(isEnabled);
                    break;

                default:
                    result.notImplemented();
            }
        });

        android.util.Log.d(TAG, "MethodChannel configured");
    }

    /**
     * Called from NotificationListenerService when a notification is received
     * Sends the message data to Flutter
     */
    public static void onNotificationReceived(String sender, String content, String source) {
        if (instance != null && instance.methodChannel != null) {
            instance.methodChannel.invokeMethod("onNotificationReceived", new java.util.HashMap<String, Object>() {{
                put("sender", sender);
                put("content", content);
                put("source", source);
                put("timestamp", System.currentTimeMillis());
            }});

            android.util.Log.d(TAG, "Notification forwarded to Flutter: " + sender);
        }
    }

    /**
     * Start the notification listener service
     */
    private void startNotificationListener() {
        try {
            Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
            startActivity(intent);
            android.util.Log.d(TAG, "Notification listener settings opened");
        } catch (Exception e) {
            android.util.Log.e(TAG, "Error starting notification listener", e);
        }
    }

    /**
     * Open notification listener settings
     */
    private void openNotificationListenerSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
                startActivity(intent);
            } else {
                Intent intent = new Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS");
                startActivity(intent);
            }
        } catch (Exception e) {
            android.util.Log.e(TAG, "Error opening notification listener settings", e);
        }
    }

    /**
     * Check if notification listener is enabled for this app
     */
    private boolean isNotificationListenerEnabled() {
        String enabledNotificationListeners = Settings.Secure.getString(
            getContentResolver(),
            "enabled_notification_listeners"
        );

        String packageName = getPackageName();
        String componentName = packageName + "/" + NotificationListenerService.class.getName();

        if (enabledNotificationListeners == null) {
            return false;
        }

        return enabledNotificationListeners.contains(componentName);
    }

    /**
     * Get singleton instance for static access
     */
    public static MainActivity getInstance() {
        return instance;
    }
}
