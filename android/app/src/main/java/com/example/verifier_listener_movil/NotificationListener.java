package com.example.verifier_listener_movil; // Cambia por tu package name

import android.app.Notification;
import android.content.Intent;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;

public class NotificationListener extends NotificationListenerService {
    private static final String TAG = "NotificationListener";
    private static MethodChannel channel;
    
    public static void setMethodChannel(MethodChannel methodChannel) {
        channel = methodChannel;
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        try {
            String packageName = sbn.getPackageName();
            Notification notification = sbn.getNotification();
            
            if (notification == null) return;

            // Extraer título y texto
            Bundle extras = notification.extras;
            String title = extras.getString(Notification.EXTRA_TITLE, "");
            String text = extras.getCharSequence(Notification.EXTRA_TEXT, "").toString();
            
            Log.d(TAG, "Notificación de: " + packageName + " - " + title + " - " + text);
            
            // Enviar a Flutter si hay un canal disponible
            if (channel != null) {
                Map<String, Object> data = new HashMap<>();
                data.put("packageName", packageName);
                data.put("title", title);
                data.put("text", text);
                data.put("timestamp", System.currentTimeMillis());
                
                channel.invokeMethod("onNotificationReceived", data);
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error procesando notificación: " + e.getMessage());
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        // Opcional: manejar notificaciones eliminadas
    }
}