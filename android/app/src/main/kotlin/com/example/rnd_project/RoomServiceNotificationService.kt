package com.example.rnd_project

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.media.RingtoneManager
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.DocumentChange
import com.google.firebase.firestore.QuerySnapshot
import com.google.firebase.firestore.FirebaseFirestoreException

class RoomServiceNotificationService : Service() {
    private var isFirstRun = true

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            if (FirebaseApp.getApps(applicationContext).isEmpty()) {
                FirebaseApp.initializeApp(applicationContext)
            }
            val db = FirebaseFirestore.getInstance()
            db.collection("CleaningRoom")
                .addSnapshotListener { snapshots: QuerySnapshot?, e: FirebaseFirestoreException? ->
                    if (e != null) {
                        return@addSnapshotListener
                    }

                    if (snapshots != null) {
                        if (!isFirstRun) {
                            for (dc in snapshots.documentChanges) {
                                if (dc.type == DocumentChange.Type.ADDED) {
                                    playSound()
                                    break
                                }
                            }
                        }
                        isFirstRun = false
                    }
                }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return START_STICKY
    }

    private fun playSound() {
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
            ringtone.play()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
