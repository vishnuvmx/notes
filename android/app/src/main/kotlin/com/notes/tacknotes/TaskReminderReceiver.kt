package com.notes.tacknotes

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * BroadcastReceiver triggered by Android AlarmManager for Markdown `@due(...)` task reminders.
 * Supports posting interactive notifications ("Done" and "Snooze 1h") and rescheduling snoozes
 * cleanly even when the Flutter engine is not running.
 */
class TaskReminderReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_TASK_REMINDERS = "tack_task_reminders"
        const val ACTION_SHOW_REMINDER = "com.notes.tacknotes.SHOW_TASK_REMINDER"
        const val ACTION_SNOOZE_REMINDER = "com.notes.tacknotes.SNOOZE_TASK_REMINDER"
        private const val PREF_REMINDERS = "tack_scheduled_reminders"
        private const val KEY_IDS = "notif_ids"

        fun scheduleReminderAlarm(
            context: Context,
            notifId: Int,
            noteId: String,
            lineIndex: Int,
            title: String,
            body: String,
            triggerAtMillis: Long,
        ) {
            val intent = Intent(context, TaskReminderReceiver::class.java).apply {
                action = ACTION_SHOW_REMINDER
                putExtra("notifId", notifId)
                putExtra("noteId", noteId)
                putExtra("lineIndex", lineIndex)
                putExtra("title", title)
                putExtra("body", body)
            }
            val pending = PendingIntent.getBroadcast(
                context,
                notifId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val safeTrigger = maxOf(triggerAtMillis, System.currentTimeMillis() + 500L)
            try {
                val canExact =
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
                if (canExact) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        safeTrigger,
                        pending,
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        safeTrigger,
                        pending,
                    )
                }
            } catch (_: SecurityException) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    safeTrigger,
                    pending,
                )
            }
        }

        fun cancelReminderAlarm(context: Context, notifId: Int) {
            val intent = Intent(context, TaskReminderReceiver::class.java).apply {
                action = ACTION_SHOW_REMINDER
            }
            val pending = PendingIntent.getBroadcast(
                context,
                notifId,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            if (pending != null) {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                alarmManager.cancel(pending)
                pending.cancel()
            }
        }

        fun syncScheduledReminders(
            context: Context,
            reminders: List<Map<String, Any?>>,
        ) {
            val prefs = context.getSharedPreferences(PREF_REMINDERS, Context.MODE_PRIVATE)
            val previousIds = prefs.getStringSet(KEY_IDS, emptySet())?.toSet() ?: emptySet()
            val nextIds = mutableSetOf<String>()

            for (item in reminders) {
                val notifId = (item["notifId"] as? Number)?.toInt() ?: continue
                val noteId = item["noteId"] as? String ?: continue
                val lineIndex = (item["lineIndex"] as? Number)?.toInt() ?: continue
                val title = (item["title"] as? String)?.takeIf { it.isNotBlank() } ?: "Task reminder"
                val body = (item["body"] as? String) ?: ""
                val triggerAtMillis = (item["triggerAtMillis"] as? Number)?.toLong() ?: continue

                scheduleReminderAlarm(
                    context = context,
                    notifId = notifId,
                    noteId = noteId,
                    lineIndex = lineIndex,
                    title = title,
                    body = body,
                    triggerAtMillis = triggerAtMillis,
                )
                nextIds.add(notifId.toString())
            }

            // Cancel stale alarms that are no longer pending.
            for (oldIdStr in previousIds) {
                if (!nextIds.contains(oldIdStr)) {
                    oldIdStr.toIntOrNull()?.let { cancelReminderAlarm(context, it) }
                }
            }

            prefs.edit().putStringSet(KEY_IDS, nextIds).apply()
        }

        fun cancelAllScheduledReminders(context: Context) {
            val prefs = context.getSharedPreferences(PREF_REMINDERS, Context.MODE_PRIVATE)
            val previousIds = prefs.getStringSet(KEY_IDS, emptySet())?.toSet() ?: emptySet()
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            for (oldIdStr in previousIds) {
                oldIdStr.toIntOrNull()?.let {
                    cancelReminderAlarm(context, it)
                    nm.cancel(it)
                }
            }
            prefs.edit().remove(KEY_IDS).apply()
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val notifId = intent.getIntExtra("notifId", 0)
        val noteId = intent.getStringExtra("noteId") ?: ""
        val lineIndex = intent.getIntExtra("lineIndex", -1)
        val title = intent.getStringExtra("title") ?: "Task reminder"
        val body = intent.getStringExtra("body") ?: ""
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        when (action) {
            ACTION_SNOOZE_REMINDER -> {
                if (notifId != 0) {
                    notificationManager.cancel(notifId)
                    scheduleReminderAlarm(
                        context = context,
                        notifId = notifId,
                        noteId = noteId,
                        lineIndex = lineIndex,
                        title = title,
                        body = body,
                        triggerAtMillis = System.currentTimeMillis() + 60L * 60L * 1000L,
                    )
                }
            }

            ACTION_SHOW_REMINDER -> {
                if (notifId == 0 || noteId.isBlank()) return

                val openIntent = Intent(context, MainActivity::class.java).apply {
                    this.action = "com.notes.tacknotes.OPEN_NOTE"
                    putExtra("noteId", noteId)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openPending = PendingIntent.getActivity(
                    context,
                    notifId,
                    openIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

                val doneIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                    this.action = NotificationActionReceiver.ACTION_COMPLETE_TASK_LINE
                    putExtra("notifId", notifId)
                    putExtra("noteId", noteId)
                    putExtra("lineIndex", lineIndex)
                }
                val donePending = PendingIntent.getBroadcast(
                    context,
                    notifId + 1,
                    doneIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

                val snoozeIntent = Intent(context, TaskReminderReceiver::class.java).apply {
                    this.action = ACTION_SNOOZE_REMINDER
                    putExtra("notifId", notifId)
                    putExtra("noteId", noteId)
                    putExtra("lineIndex", lineIndex)
                    putExtra("title", title)
                    putExtra("body", body)
                }
                val snoozePending = PendingIntent.getBroadcast(
                    context,
                    notifId + 2,
                    snoozeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

                val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Notification.Builder(context, CHANNEL_TASK_REMINDERS)
                } else {
                    @Suppress("DEPRECATION")
                    Notification.Builder(context)
                }

                builder.setContentTitle(title)
                    .setContentText(body.ifBlank { "Task reminder from Tack" })
                    .setSmallIcon(R.drawable.ic_stat_tack)
                    .setContentIntent(openPending)
                    .setAutoCancel(true)
                    .addAction(
                        Notification.Action.Builder(
                            android.graphics.drawable.Icon.createWithResource(context, R.drawable.ic_stat_tack),
                            "Done",
                            donePending,
                        ).build(),
                    )
                    .addAction(
                        Notification.Action.Builder(
                            android.graphics.drawable.Icon.createWithResource(context, R.drawable.ic_stat_tack),
                            "Snooze 1h",
                            snoozePending,
                        ).build(),
                    )

                notificationManager.notify(notifId, builder.build())
            }
        }
    }
}
