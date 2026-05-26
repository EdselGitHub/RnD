import 'package:flutter/services.dart';

class NotificationSoundService {
  static const _channel = MethodChannel('com.rnd_project/notification_sound');

  static Future<void> playNotificationSound() async {
    try {
      await _channel.invokeMethod('playNotificationSound');
    } catch (e) {
      // Fallback: do nothing if the platform channel isn't available
      // This can happen on web or desktop
    }
  }
}
