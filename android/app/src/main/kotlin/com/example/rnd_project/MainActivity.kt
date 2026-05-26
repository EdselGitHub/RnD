package com.example.rnd_project

import android.media.RingtoneManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rnd_project/notification_sound"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "playNotificationSound") {
                try {
                    val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
                    ringtone.play()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to play notification sound", e.message)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
