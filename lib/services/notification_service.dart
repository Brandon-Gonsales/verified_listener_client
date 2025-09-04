import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('notification_service');

  static Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } on PlatformException catch (e) {
      print("Error requesting permission: ${e.message}");
    }
  }

  static Future<bool> isNotificationPermissionGranted() async {
    try {
      final bool result =
          await _channel.invokeMethod('isNotificationPermissionGranted');
      return result;
    } on PlatformException catch (e) {
      print("Error checking permission: ${e.message}");
      return false;
    }
  }
}
