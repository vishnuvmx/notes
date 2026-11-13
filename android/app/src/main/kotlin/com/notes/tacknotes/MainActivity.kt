package com.notes.tacknotes

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val QUICK_CAPTURE_NOTIF_ID = 7777
        private const val CHANNEL_QUICK_CAPTURE = "tack_quick_capture"
        private const val CHANNEL_PINNED_NOTES = "tack_pinned_notes"

        var activeNotificationChannel: MethodChannel? = null

        fun showQuickCaptureNotificationOn(context: Context) {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val quickIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.notes.tacknotes.QUICK_CAPTURE"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                QUICK_CAPTURE_NOTIF_ID,
                quickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val replyIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = NotificationActionReceiver.ACTION_QUICK_REPLY_NOTE
                putExtra("noteId", "")
            }
            val replyPendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val replyPendingIntent = PendingIntent.getBroadcast(
                context,
                QUICK_CAPTURE_NOTIF_ID + 1,
                replyIntent,
                replyPendingFlags
            )

            val remoteInput = RemoteInput.Builder(NotificationActionReceiver.KEY_QUICK_REPLY_TEXT)
                .setLabel("Jot a quick note or task...")
                .build()

            val quickAddAction = Notification.Action.Builder(
                android.graphics.drawable.Icon.createWithResource(context, R.drawable.ic_stat_tack),
                "Quick Add",
                replyPendingIntent
            ).addRemoteInput(remoteInput).build()

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_QUICK_CAPTURE)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }

            builder.setContentTitle("Quick Note")
                .setContentText("Tap to open or use Quick Add below")
                .setSmallIcon(R.drawable.ic_stat_tack)
                .setContentIntent(pendingIntent)
                .addAction(quickAddAction)
                .setOngoing(true)
                .setAutoCancel(false)

            notificationManager.notify(QUICK_CAPTURE_NOTIF_ID, builder.build())
        }

        fun showFallbackStatusNotification(context: Context, noteId: String, statusText: String) {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val openIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.notes.tacknotes.OPEN_NOTE"
                putExtra("noteId", noteId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPending = PendingIntent.getActivity(
                context,
                noteId.hashCode(),
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val unpinIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = NotificationActionReceiver.ACTION_UNPIN_NOTE
                putExtra("noteId", noteId)
            }
            val unpinPending = PendingIntent.getBroadcast(
                context,
                noteId.hashCode() + 1,
                unpinIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_PINNED_NOTES)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }

            builder.setContentTitle("Pinned Note")
                .setContentText(statusText)
                .setSmallIcon(R.drawable.ic_stat_tack)
                .setContentIntent(openPending)
                .addAction(
                    Notification.Action.Builder(
                        android.graphics.drawable.Icon.createWithResource(context, R.drawable.ic_stat_tack),
                        "Unpin",
                        unpinPending
                    ).build()
                )
                .setOngoing(true)
                .setAutoCancel(false)

            notificationManager.notify(noteId.hashCode(), builder.build())
        }
    }

    private val channelName = "com.notes.tacknotes/process_text"
    private val notifChannelName = "com.notes.tacknotes/notifications"
    private var methodChannel: MethodChannel? = null
    private var notificationMethodChannel: MethodChannel? = null
    private var pendingPayload: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialText" -> {
                    val payload = pendingPayload
                    pendingPayload = null
                    result.success(payload)
                }
                "showQuickCapture" -> {
                    showQuickCaptureNotification()
                    result.success(true)
                }
                "hideQuickCapture" -> {
                    hideQuickCaptureNotification()
                    result.success(true)
                }
                "updateShortcuts" -> {
                    val list = call.argument<List<Map<String, Any?>>>("shortcuts") ?: emptyList()
                    updateDynamicShortcuts(list)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Deliver any pending payload that arrived before the channel was ready
        pendingPayload?.let { payload ->
            methodChannel?.invokeMethod("onReceiveText", payload)
        }

        notificationMethodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notifChannelName)
        activeNotificationChannel = notificationMethodChannel
        notificationMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showQuickCapture" -> {
                    ensureNotificationPermission()
                    showQuickCaptureNotification()
                    result.success(true)
                }
                "hideQuickCapture" -> {
                    hideQuickCaptureNotification()
                    result.success(true)
                }
                "pinNoteNotification" -> {
                    ensureNotificationPermission()
                    val noteId = call.argument<String>("noteId") ?: ""
                    val title = call.argument<String>("title") ?: "Pinned Note"
                    val body = call.argument<String>("body") ?: ""
                    val hasNextTodo = call.argument<Boolean>("hasNextTodo") ?: false
                    if (noteId.isNotBlank()) {
                        showPinnedNoteNotification(
                            noteId = noteId,
                            title = title,
                            body = body,
                            hasNextTodo = hasNextTodo
                        )
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "unpinNoteNotification" -> {
                    val noteId = call.argument<String>("noteId") ?: ""
                    if (noteId.isNotBlank()) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        nm.cancel(noteId.hashCode())
                    }
                    result.success(true)
                }
                "drainPendingNotificationActions" -> {
                    result.success(NotificationActionReceiver.drainQueuedActions(this))
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        if (activeNotificationChannel === notificationMethodChannel) {
            activeNotificationChannel = null
        }
        super.onDestroy()
    }

    private fun ensureNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 9001)
            }
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            val quickCaptureChannel = NotificationChannel(
                CHANNEL_QUICK_CAPTURE,
                "Quick Capture",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "1-tap quick note capture in status bar"
                setShowBadge(false)
            }
            notificationManager?.createNotificationChannel(quickCaptureChannel)

            val pinnedNotesChannel = NotificationChannel(
                CHANNEL_PINNED_NOTES,
                "Pinned Notes & To-Dos",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Pinned notes and checklists in your notification shade"
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            }
            notificationManager?.createNotificationChannel(pinnedNotesChannel)
        }
    }

    private fun showQuickCaptureNotification() {
        showQuickCaptureNotificationOn(this)
    }

    private fun hideQuickCaptureNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(QUICK_CAPTURE_NOTIF_ID)
    }

    private fun showPinnedNoteNotification(
        noteId: String,
        title: String,
        body: String,
        hasNextTodo: Boolean
    ) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notifId = noteId.hashCode()

        val openIntent = Intent(this, MainActivity::class.java).apply {
            action = "com.notes.tacknotes.OPEN_NOTE"
            putExtra("noteId", noteId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            this,
            notifId,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val unpinIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_UNPIN_NOTE
            putExtra("noteId", noteId)
        }
        val unpinPending = PendingIntent.getBroadcast(
            this,
            notifId + 1,
            unpinIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val replyIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_QUICK_REPLY_NOTE
            putExtra("noteId", noteId)
        }
        val replyPendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val replyPending = PendingIntent.getBroadcast(
            this,
            notifId + 2,
            replyIntent,
            replyPendingFlags
        )

        val remoteInput = RemoteInput.Builder(NotificationActionReceiver.KEY_QUICK_REPLY_TEXT)
            .setLabel(if (hasNextTodo) "Add task..." else "Append to note...")
            .build()

        val addTaskAction = Notification.Action.Builder(
            android.graphics.drawable.Icon.createWithResource(this, R.drawable.ic_stat_tack),
            if (hasNextTodo) "Add Task" else "Append",
            replyPending
        ).addRemoteInput(remoteInput).build()

        val unpinAction = Notification.Action.Builder(
            android.graphics.drawable.Icon.createWithResource(this, R.drawable.ic_stat_tack),
            "Unpin",
            unpinPending
        ).build()

        val summaryLine = body.lineSequence().firstOrNull { it.isNotBlank() }?.trim() ?: "Tap to open"

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_PINNED_NOTES)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder.setContentTitle(title.ifBlank { "Pinned Note" })
            .setContentText(summaryLine)
            .setStyle(
                Notification.BigTextStyle()
                    .setBigContentTitle(title.ifBlank { "Pinned Note" })
                    .bigText(body.ifBlank { "Tap to open in Tack" })
            )
            .setSmallIcon(R.drawable.ic_stat_tack)
            .setContentIntent(openPending)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(addTaskAction)

        if (hasNextTodo) {
            val doneIntent = Intent(this, NotificationActionReceiver::class.java).apply {
                action = NotificationActionReceiver.ACTION_COMPLETE_NEXT_TODO
                putExtra("noteId", noteId)
            }
            val donePending = PendingIntent.getBroadcast(
                this,
                notifId + 3,
                doneIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(
                Notification.Action.Builder(
                    android.graphics.drawable.Icon.createWithResource(this, R.drawable.ic_stat_tack),
                    "Check Next",
                    donePending
                ).build()
            )
        }

        builder.addAction(unpinAction)
        notificationManager.notify(notifId, builder.build())
    }

    private fun updateDynamicShortcuts(shortcutsList: List<Map<String, Any?>>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            try {
                val shortcutManager = getSystemService(android.content.pm.ShortcutManager::class.java) ?: return
                val shortcuts = mutableListOf<android.content.pm.ShortcutInfo>()
                for ((index, item) in shortcutsList.take(2).withIndex()) {
                    val id = item["id"] as? String ?: continue
                    val title = (item["title"] as? String)?.takeIf { it.isNotBlank() } ?: "Untitled Note"
                    val intent = Intent(this, MainActivity::class.java).apply {
                        action = "com.notes.tacknotes.OPEN_NOTE"
                        putExtra("noteId", id)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val shortcut = android.content.pm.ShortcutInfo.Builder(this, "dynamic_note_$id")
                        .setShortLabel(title.take(16))
                        .setLongLabel(title.take(30))
                        .setRank(index)
                        .setIcon(android.graphics.drawable.Icon.createWithResource(this, R.drawable.ic_shortcut_new_note))
                        .setIntent(intent)
                        .build()
                    shortcuts.add(shortcut)
                }
                shortcutManager.dynamicShortcuts = shortcuts
            } catch (e: Exception) {
                // Ignore launcher shortcut exceptions gracefully
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return

        if (action == "com.notes.tacknotes.OPEN_NOTE") {
            val noteId = intent.getStringExtra("noteId")
            if (!noteId.isNullOrBlank()) {
                val payload = mapOf(
                    "action" to "OPEN_NOTE",
                    "noteId" to noteId
                )
                val channel = methodChannel
                if (channel != null) {
                    channel.invokeMethod("onReceiveText", payload)
                } else {
                    pendingPayload = payload
                }
            }
            return
        }

        if (action == "com.notes.tacknotes.QUICK_CAPTURE") {
            val payload = mapOf(
                "action" to "QUICK_CAPTURE"
            )
            val channel = methodChannel
            if (channel != null) {
                channel.invokeMethod("onReceiveText", payload)
            } else {
                pendingPayload = payload
            }
            return
        }

        if (action == Intent.ACTION_PROCESS_TEXT || action == Intent.ACTION_SEND || action == Intent.ACTION_SEND_MULTIPLE || action == Intent.ACTION_VIEW) {
            var text: String? = null
            var fileName: String? = null
            var title: String? = null
            var imagePath: String? = null

            when (action) {
                Intent.ACTION_VIEW -> {
                    val uri: Uri? = intent.data
                    if (uri != null) {
                        // Handle tack:// deep-link shortcuts (long-press app icon)
                        if (uri.scheme == "tack" && uri.host == "action") {
                            val shortcutAction = when (uri.path) {
                                "/new_note" -> "NEW_NOTE"
                                "/new_whiteboard" -> "NEW_WHITEBOARD"
                                "/worth_remembering" -> "WIDGET_WORTH_REMEMBERING"
                                "/done_works" -> "WIDGET_DONE_WORKS"
                                "/plan_day" -> "WIDGET_PLAN_DAY"
                                else -> null
                            }
                            if (shortcutAction != null) {
                                val payload = mapOf("action" to shortcutAction, "text" to "")
                                val channel = methodChannel
                                if (channel != null) {
                                    channel.invokeMethod("onReceiveText", payload)
                                } else {
                                    pendingPayload = payload
                                }
                            }
                            return
                        }
                        // Regular file open (content:// or file://)
                        fileName = resolveFileName(uri)
                        text = readFileContent(uri)
                    }
                }
                Intent.ACTION_SEND -> {
                    // Extract subject/title from Android share sheet (e.g. Chrome / YouTube / Twitter article title)
                    val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
                        ?: intent.getStringExtra(Intent.EXTRA_TITLE)
                    if (!subject.isNullOrBlank()) {
                        title = subject.trim()
                    }

                    @Suppress("DEPRECATION")
                    val streamUri: Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)
                    val mimeType = intent.type ?: ""

                    if (streamUri != null && (mimeType.startsWith("image/") || isImageUri(streamUri))) {
                        fileName = resolveFileName(streamUri)
                        imagePath = saveImageToInternal(streamUri, fileName)
                        text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
                    } else if (streamUri != null) {
                        fileName = resolveFileName(streamUri)
                        text = readFileContent(streamUri)
                    } else {
                        text = intent.getStringExtra(Intent.EXTRA_TEXT)
                            ?: intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
                    }
                }
                Intent.ACTION_SEND_MULTIPLE -> {
                    val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
                        ?: intent.getStringExtra(Intent.EXTRA_TITLE)
                    if (!subject.isNullOrBlank()) {
                        title = subject.trim()
                    }

                    @Suppress("DEPRECATION")
                    val streamUris: ArrayList<Uri>? = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
                    if (!streamUris.isNullOrEmpty()) {
                        val firstUri = streamUris.first()
                        val mimeType = intent.type ?: ""
                        if (mimeType.startsWith("image/") || isImageUri(firstUri)) {
                            fileName = resolveFileName(firstUri)
                            imagePath = saveImageToInternal(firstUri, fileName)
                            text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
                        } else {
                            val sb = StringBuilder()
                            for (u in streamUris) {
                                val content = readFileContent(u)
                                if (!content.isNullOrBlank()) {
                                    if (sb.isNotEmpty()) sb.append("\n\n---\n\n")
                                    sb.append(content)
                                }
                            }
                            text = sb.toString()
                        }
                    } else {
                        text = intent.getStringExtra(Intent.EXTRA_TEXT)
                    }
                }
                Intent.ACTION_PROCESS_TEXT -> {
                    text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                        ?: intent.getStringExtra(Intent.EXTRA_PROCESS_TEXT)
                }
            }

            // Handle empty selections or unreadable files gracefully
            if (text.isNullOrBlank() && imagePath.isNullOrBlank()) {
                return
            }

            // Strip extension for a clean note title if opened from a file, but preserve subject if present
            if (title.isNullOrBlank() && !fileName.isNullOrBlank()) {
                title = fileName.replace(Regex("\\.(md|markdown|txt|png|jpg|jpeg|webp)$", RegexOption.IGNORE_CASE), "")
            }

            // If launched with ACTION_PROCESS_TEXT and not read-only, ensure original text is preserved
            if (action == Intent.ACTION_PROCESS_TEXT && text != null) {
                val isReadOnly = intent.getBooleanExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, false)
                if (!isReadOnly) {
                    val resultIntent = Intent().apply {
                        putExtra(Intent.EXTRA_PROCESS_TEXT, text)
                    }
                    setResult(Activity.RESULT_OK, resultIntent)
                }
            }

            val packageName = resolveCallingPackage(intent)
            val sourceAppName = getAppNameFromPackage(packageName)

            val payload = mapOf(
                "text" to (text ?: ""),
                "title" to title,
                "fileName" to fileName,
                "imagePath" to imagePath,
                "sourceApp" to sourceAppName,
                "packageName" to packageName,
                "action" to action
            )

            val channel = methodChannel
            if (channel != null) {
                channel.invokeMethod("onReceiveText", payload)
            } else {
                pendingPayload = payload
            }
        }
    }

    private fun resolveFileName(uri: Uri): String? {
        var name: String? = null
        if (uri.scheme == "content") {
            try {
                contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (index >= 0) {
                            name = cursor.getString(index)
                        }
                    }
                }
            } catch (_: Exception) {}
        }
        if (name.isNullOrBlank()) {
            name = uri.lastPathSegment
        }
        return name
    }

    private fun readFileContent(uri: Uri): String? {
        return try {
            contentResolver.openInputStream(uri)?.use { stream ->
                stream.bufferedReader(Charsets.UTF_8).readText()
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveCallingPackage(intent: Intent): String? {
        // 1. Direct calling package from startActivityForResult
        val callingPkg = callingPackage
        if (!callingPkg.isNullOrBlank()) return callingPkg

        // 2. Calling activity
        val callingAct = callingActivity?.packageName
        if (!callingAct.isNullOrBlank()) return callingAct

        // 3. Referrer URI
        try {
            val refUri: Uri? = referrer
            if (refUri != null && refUri.scheme == "android-app") {
                val host = refUri.host
                if (!host.isNullOrBlank()) return host
            }
        } catch (_: Exception) {}

        // 4. Intent extras for referrer
        val extraRef = intent.getStringExtra(Intent.EXTRA_REFERRER_NAME)
        if (!extraRef.isNullOrBlank()) {
            return extraRef.removePrefix("android-app://")
        }

        return null
    }

    private fun getAppNameFromPackage(packageName: String?): String? {
        if (packageName.isNullOrBlank()) return null
        return try {
            val pm = applicationContext.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            packageName
        }
    }

    private fun isImageUri(uri: Uri): Boolean {
        val type = contentResolver.getType(uri)
        if (type?.startsWith("image/") == true) return true
        val path = uri.path?.lowercase() ?: ""
        return path.endsWith(".png") || path.endsWith(".jpg") || path.endsWith(".jpeg") || path.endsWith(".webp") || path.endsWith(".gif")
    }

    private fun saveImageToInternal(uri: Uri, suggestedName: String?): String? {
        return try {
            val extension = if (suggestedName != null && suggestedName.contains(".")) {
                suggestedName.substringAfterLast(".", "jpg")
            } else {
                "jpg"
            }
            val targetDir = File(filesDir, "shared_media").apply { if (!exists()) mkdirs() }
            val targetFile = File(targetDir, "img_${System.currentTimeMillis()}.$extension")
            contentResolver.openInputStream(uri)?.use { input ->
                targetFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            targetFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

