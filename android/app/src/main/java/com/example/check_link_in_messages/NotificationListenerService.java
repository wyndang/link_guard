package com.example.check_link_in_messages;

import android.os.Build;
import android.service.notification.StatusBarNotification;
import android.content.Context;
import android.content.SharedPreferences;
import android.app.Notification;
import android.os.Bundle;
import android.content.Intent;

import androidx.annotation.RequiresApi;

/**
 * Service to listen for notifications from Zalo and Messenger
 * Requires user to manually enable this app as a notification listener in system settings
 */
@RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
public class NotificationListenerService extends android.service.notification.NotificationListenerService {
    private static final String TAG = "LinkGuardNotifListener";
    private static final String PREFS_NAME = "link_guard_prefs";
    private static final String KEY_LAST_NOTIFICATIONS = "last_notifications";
    private static final String ACTION_NOTIFICATION = "com.example.check_link_in_messages.NOTIFICATION_RECEIVED";
    
    // Package names of apps we want to monitor
    private static final String[] MONITORED_APPS = {
        "com.zalo",              // Zalo
        "com.zing.zalo",         // Zalo (alternate)
        "com.facebook.orca",     // Messenger
        "com.facebook.katana",   // Facebook
        "com.whatsapp",          // WhatsApp
        "com.telegram.messenger" // Telegram
    };

    static {
        android.util.Log.d("LinkGuardNotifListener", "✓ NotificationListenerService class loaded");
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        if (sbn == null) {
            return;
        }

        String packageName = sbn.getPackageName();
        
        // Log EVERY SINGLE notification to a file/logcat
        try {
            android.util.Log.i(TAG, ">>> NOTIFICATION: " + packageName);
        } catch (Exception e) {
            android.util.Log.e(TAG, "Error logging: " + e.getMessage());
        }
        
        // Check if this notification is from a monitored app
        if (!isMonitoredApp(packageName)) {
            return;
        }

        android.util.Log.i(TAG, ">>> MATCHED MONITORED: " + packageName);

        try {
            Notification notification = sbn.getNotification();
            if (notification == null) {
                android.util.Log.d(TAG, "❌ Notification object is null");
                return;
            }

            // Extract message content from notification
            Bundle extras = notification.extras;
            if (extras == null) {
                android.util.Log.d(TAG, "❌ Notification extras is null");
                return;
            }

            String messageContent = extractMessageContent(extras);
            String sender = extractSender(extras);

            android.util.Log.d(TAG, "📝 Extracted - Sender: " + sender + ", Content: " + messageContent);

            if (messageContent != null && !messageContent.isEmpty()) {
                String source = getSourceFromPackage(packageName);
                
                // Try to send to MainActivity directly
                MainActivity mainActivity = MainActivity.getInstance();
                if (mainActivity != null) {
                    android.util.Log.d(TAG, "✓ MainActivity available - calling directly");
                    mainActivity.onNotificationReceived(
                        sender != null ? sender : packageName,
                        messageContent,
                        source
                    );
                } else {
                    android.util.Log.d(TAG, "⚠ MainActivity not available");
                }

                android.util.Log.d(TAG, "✓ Notification processed - Source: " + source);
            } else {
                android.util.Log.d(TAG, "⚠ No message content extracted");
            }
        } catch (Exception e) {
            android.util.Log.e(TAG, "❌ Error processing notification: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        // Handle notification removal if needed
    }

    /**
     * Check if the app package is in our monitored list
     */
    private boolean isMonitoredApp(String packageName) {
        for (String app : MONITORED_APPS) {
            if (packageName.equals(app)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Extract message content from notification extras
     */
    private String extractMessageContent(Bundle extras) {
        // Try different keys that Zalo and Messenger use
        String[] contentKeys = {
            "android.text",           // Generic Android key
            "android.bigText",        // Large text content
            "android.summaryText",    // Summary text
            "com.facebook.messaging_intent_text",  // Messenger specific
            "text",
            "title",
            "message"
        };

        for (String key : contentKeys) {
            Object value = extras.get(key);
            if (value != null && !value.toString().isEmpty()) {
                return value.toString();
            }
        }

        return null;
    }

    /**
     * Extract sender name from notification extras
     */
    private String extractSender(Bundle extras) {
        String[] senderKeys = {
            "android.title",
            "android.subText",
            "com.facebook.messaging_intent_from",
            "sender",
            "from"
        };

        for (String key : senderKeys) {
            Object value = extras.get(key);
            if (value != null && !value.toString().isEmpty()) {
                return value.toString();
            }
        }

        return null;
    }

    /**
     * Get the source (Zalo, Messenger, etc.) from package name
     */
    private String getSourceFromPackage(String packageName) {
        if (packageName.contains("zalo")) {
            return "zalo";
        } else if (packageName.contains("facebook") || packageName.contains("messenger")) {
            return "messenger";
        }
        return "unknown";
    }
}
