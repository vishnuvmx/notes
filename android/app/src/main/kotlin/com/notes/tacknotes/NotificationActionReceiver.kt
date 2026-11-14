package com.notes.tacknotes

import android.app.NotificationManager
import android.app.RemoteInput
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject

/**
 * BroadcastReceiver handling background notification actions:
 * - UNPIN_NOTE: cancels the pinned note notification immediately and records unpin.
 * - COMPLETE_NEXT_TODO: marks the next unchecked task done (live or queued).
 * - QUICK_REPLY_NOTE: captures inline RemoteInput text for a pinned note or Quick Capture.
 */
class NotificationActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_UNPIN_NOTE = "com.notes.tacknotes.UNPIN_NOTE"
        const val ACTION_COMPLETE_NEXT_TODO = "com.notes.tacknotes.COMPLETE_NEXT_TODO"
        const val ACTION_COMPLETE_TASK_LINE = "com.notes.tacknotes.COMPLETE_TASK_LINE"
        const val ACTION_QUICK_REPLY_NOTE = "com.notes.tacknotes.QUICK_REPLY_NOTE"
        const val KEY_QUICK_REPLY_TEXT = "key_quick_note_text"
        private const val PREF_QUEUE = "tack_native_notif_queue"
        private const val KEY_ACTIONS = "pending_actions"

        fun drainQueuedActions(context: Context): List<Map<String, String>> {
            val prefs = context.getSharedPreferences(PREF_QUEUE, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_ACTIONS, null) ?: return emptyList()
            prefs.edit().remove(KEY_ACTIONS).apply()

            val list = mutableListOf<Map<String, String>>()
            try {
                val arr = JSONArray(raw)
                for (i in 0 until arr.length()) {
                    val obj = arr.optJSONObject(i) ?: continue
                    list.add(
                        mapOf(
                            "type" to obj.optString("type", ""),
                            "noteId" to obj.optString("noteId", ""),
                            "text" to obj.optString("text", ""),
                            "lineIndex" to obj.optString("lineIndex", "")
                        )
                    )
                }
            } catch (_: Exception) {
                // Ignore malformed JSON gracefully
            }
            return list
        }

        private fun enqueueAction(
            context: Context,
            type: String,
            noteId: String,
            text: String = "",
            lineIndex: Int? = null
        ) {
            val prefs = context.getSharedPreferences(PREF_QUEUE, Context.MODE_PRIVATE)
            val existing = prefs.getString(KEY_ACTIONS, null)
            val arr = try {
                if (existing != null) JSONArray(existing) else JSONArray()
            } catch (_: Exception) {
                JSONArray()
            }
            val obj = JSONObject().apply {
                put("type", type)
                put("noteId", noteId)
                put("text", text)
                if (lineIndex != null) {
                    put("lineIndex", lineIndex.toString())
                }
            }
            arr.put(obj)
            prefs.edit().putString(KEY_ACTIONS, arr.toString()).apply()
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val noteId = intent.getStringExtra("noteId") ?: ""
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        when (action) {
            ACTION_UNPIN_NOTE -> {
                if (noteId.isNotBlank()) {
                    notificationManager.cancel(noteId.hashCode())
                    val channel = MainActivity.activeNotificationChannel
                    if (channel != null) {
                        channel.invokeMethod("onNotificationUnpin", mapOf("noteId" to noteId))
                    } else {
                        enqueueAction(context, "unpin", noteId)
                    }
                }
            }

            ACTION_COMPLETE_NEXT_TODO -> {
                if (noteId.isNotBlank()) {
                    val channel = MainActivity.activeNotificationChannel
                    if (channel != null) {
                        channel.invokeMethod("onNotificationCompleteTodo", mapOf("noteId" to noteId))
                    } else {
                        enqueueAction(context, "complete_todo", noteId)
                        // Refresh notification subtitle so user gets immediate feedback
                        MainActivity.showFallbackStatusNotification(
                            context,
                            noteId,
                            "Task marked done • Tap to view"
                        )
                    }
                }
            }

            ACTION_COMPLETE_TASK_LINE -> {
                val notifId = intent.getIntExtra("notifId", 0)
                val lineIndex = intent.getIntExtra("lineIndex", -1)
                if (notifId != 0) {
                    notificationManager.cancel(notifId)
                }
                if (noteId.isNotBlank() && lineIndex >= 0) {
                    val channel = MainActivity.activeNotificationChannel
                    if (channel != null) {
                        channel.invokeMethod(
                            "onNotificationCompleteTaskLine",
                            mapOf("noteId" to noteId, "lineIndex" to lineIndex)
                        )
                    } else {
                        enqueueAction(
                            context = context,
                            type = "complete_task_line",
                            noteId = noteId,
                            lineIndex = lineIndex
                        )
                    }
                }
            }

            ACTION_QUICK_REPLY_NOTE -> {
                val results = RemoteInput.getResultsFromIntent(intent)
                val typedText = results?.getCharSequence(KEY_QUICK_REPLY_TEXT)?.toString()?.trim()
                if (!typedText.isNullOrBlank()) {
                    val channel = MainActivity.activeNotificationChannel
                    if (channel != null) {
                        channel.invokeMethod(
                            "onNotificationQuickAdd",
                            mapOf("noteId" to noteId, "text" to typedText)
                        )
                    } else {
                        enqueueAction(context, "quick_add", noteId, typedText)
                    }
                }

                // Re-post notification to clear Android's RemoteInput loading spinner
                if (noteId.isBlank()) {
                    MainActivity.showQuickCaptureNotificationOn(context)
                } else if (MainActivity.activeNotificationChannel == null) {
                    MainActivity.showFallbackStatusNotification(
                        context,
                        noteId,
                        "Added: ${typedText ?: ""}".trim()
                    )
                }
            }
        }
    }
}
