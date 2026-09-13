package com.notes.tacknotes

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.notes.tacknotes/process_text"
    private var methodChannel: MethodChannel? = null
    private var pendingPayload: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
                else -> result.notImplemented()
            }
        }

        // Deliver any pending payload that arrived before the channel was ready
        pendingPayload?.let { payload ->
            methodChannel?.invokeMethod("onReceiveText", payload)
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return

        if (action == Intent.ACTION_PROCESS_TEXT || action == Intent.ACTION_SEND || action == Intent.ACTION_VIEW) {
            var text: String? = null
            var fileName: String? = null
            var title: String? = null

            when (action) {
                Intent.ACTION_VIEW -> {
                    val uri: Uri? = intent.data
                    if (uri != null) {
                        fileName = resolveFileName(uri)
                        text = readFileContent(uri)
                    }
                }
                Intent.ACTION_SEND -> {
                    @Suppress("DEPRECATION")
                    val streamUri: Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)
                    if (streamUri != null) {
                        fileName = resolveFileName(streamUri)
                        text = readFileContent(streamUri)
                    } else {
                        text = intent.getStringExtra(Intent.EXTRA_TEXT)
                            ?: intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
                    }
                }
                Intent.ACTION_PROCESS_TEXT -> {
                    text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                        ?: intent.getStringExtra(Intent.EXTRA_PROCESS_TEXT)
                }
            }

            // Handle empty selections or unreadable files gracefully
            if (text.isNullOrBlank()) {
                return
            }

            // Strip extension for a clean note title if opened from a file
            if (!fileName.isNullOrBlank()) {
                title = fileName.replace(Regex("\\.(md|markdown|txt)$", RegexOption.IGNORE_CASE), "")
            }

            // If launched with ACTION_PROCESS_TEXT and not read-only, ensure original text is preserved
            if (action == Intent.ACTION_PROCESS_TEXT) {
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
                "text" to text,
                "title" to title,
                "fileName" to fileName,
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
}

