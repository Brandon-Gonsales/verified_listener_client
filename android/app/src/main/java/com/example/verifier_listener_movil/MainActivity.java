package com.example.verifier_listener_movil;

import android.content.Intent;
import android.provider.Settings;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "notification_listener";
    private MethodChannel methodChannel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        
        // Configurar el canal en el NotificationListener
        NotificationListener.setMethodChannel(methodChannel);
        
        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "hasNotificationPermission":
                    result.success(hasNotificationPermission());
                    break;
                    
                case "requestNotificationPermission":
                    requestNotificationPermission();
                    result.success(null);
                    break;
                    
                case "startListening":
                    result.success(true); // El servicio se inicia automáticamente con los permisos
                    break;
                    
                case "stopListening":
                    result.success(true);
                    break;
                    
                default:
                    result.notImplemented();
                    break;
            }
        });
    }

    private boolean hasNotificationPermission() {
        try {
            return Settings.Secure.getString(getContentResolver(), "enabled_notification_listeners")
                    .contains(getPackageName());
        } catch (Exception e) {
            return false;
        }
    }

    private void requestNotificationPermission() {
        Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
        startActivity(intent);
    }
}