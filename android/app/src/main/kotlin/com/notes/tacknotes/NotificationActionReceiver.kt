package com.notes.tacknotes

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BroadcastReceiver handling background notification actions like "Unpin".
 */
class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.notes.tacknotes.UNPIN_NOTE") {
            val noteId = intent.getStringExtra("noteId")
            if (!noteId.isNullOrBlank()) {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.cancel(noteId.hashCode())
            }
        }
    }
}
