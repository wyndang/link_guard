package com.example.check_link_in_messages;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;
import android.provider.Settings;
import android.os.Build;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import android.app.NotificationChannel;

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

                case "showMaliciousNotification":
                    String sender = call.argument("sender");
                    String link = call.argument("link");
                    String title = call.argument("title");
                    String message = call.argument("message");
                    showMaliciousLinkNotification(sender, link, title, message);
                    result.success(null);
                    break;

                case "requestNotificationPermission":
                    requestNotificationPermissionRuntime();
                    result.success(true);
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
     * Show push notification for malicious link detected
     */
    private void showMaliciousLinkNotification(String sender, String link, String title, String message) {
        try {
            String channelId = "malicious_link_channel";
            
            // Create notification channel for Android 8+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel channel = new NotificationChannel(
                    channelId,
                    "Malicious Links",
                    android.app.NotificationManager.IMPORTANCE_HIGH
                );
                channel.setDescription("Notifications for detected malicious links");
                channel.enableVibration(true);
                channel.enableLights(true);
                
                android.app.NotificationManager notificationManager = 
                    getSystemService(android.app.NotificationManager.class);
                if (notificationManager != null) {
                    notificationManager.createNotificationChannel(channel);
                }
            }
            
            // Build notification
            NotificationCompat.Builder builder = new NotificationCompat.Builder(this, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(new NotificationCompat.BigTextStyle()
                    .bigText("Link: " + link + "\n\nFrom: " + sender))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setVibrate(new long[]{0, 500, 250, 500})
                .setLights(0xFFFF0000, 500, 500)
                .setTimeoutAfter(5000);  // Auto-dismiss after 5 seconds
            
            // Show notification
            NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
            int notificationId = (int) System.currentTimeMillis();
            notificationManager.notify(notificationId, builder.build());
            
            android.util.Log.d(TAG, "Malicious link notification shown: " + title);
            
            // Optional: Auto-cancel after 5 seconds programmatically
            new android.os.Handler(android.os.Looper.getMainLooper()).postDelayed(() -> {
                notificationManager.cancel(notificationId);
                android.util.Log.d(TAG, "Notification auto-dismissed after 5 seconds");
            }, 5000);
            
        } catch (Exception e) {
            android.util.Log.e(TAG, "Error showing malicious notification", e);
        }
    }

    /**
     * Request notification permission for Android 13+
     */
    private void requestNotificationPermissionRuntime() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            String[] permissions = {"android.permission.POST_NOTIFICATIONS"};
            requestPermissions(permissions, 123);
        }
    }

    /**
     * Get singleton instance for static access
     */
    public static MainActivity getInstance() {
        return instance;
    }
}
