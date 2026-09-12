package com.notes.tacknotes

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
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

        if (action == Intent.ACTION_PROCESS_TEXT || action == Intent.ACTION_SEND) {
            val text: String? = when (action) {
                Intent.ACTION_PROCESS_TEXT -> {
                    intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                        ?: intent.getStringExtra(Intent.EXTRA_PROCESS_TEXT)
                }
                Intent.ACTION_SEND -> {
                    if ("text/plain" == intent.type) {
                        intent.getStringExtra(Intent.EXTRA_TEXT)
                            ?: intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
                    } else null
                }
                else -> null
            }

            // Handle empty selections gracefully
            if (text.isNullOrBlank()) {
                return
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

