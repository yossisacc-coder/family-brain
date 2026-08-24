package com.familybrain.family_brain

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "family_brain/share"
    private var channel: MethodChannel? = null
    private var pending: HashMap<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitial") {
                result.success(pending)
                pending = null
            } else {
                result.notImplemented()
            }
        }
        pending?.let { channel?.invokeMethod("onShare", it) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureShare(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        captureShare(intent)
        pending?.let { channel?.invokeMethod("onShare", it) }
    }

    private fun captureShare(intent: Intent?) {
        if (intent == null) return
        if (intent.action != Intent.ACTION_SEND) return
        val data = HashMap<String, String>()
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        if (!text.isNullOrBlank()) data["text"] = text
        val stream = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        if (stream != null) {
            copyUri(stream)?.let { data["imagePath"] = it }
        }
        if (data.isNotEmpty()) pending = data
    }

    private fun copyUri(uri: Uri): String? {
        return try {
            val input = contentResolver.openInputStream(uri) ?: return null
            val file = File(cacheDir, "shared_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use { output -> input.copyTo(output) }
            input.close()
            file.absolutePath
        } catch (_: Exception) {
            null
        }
    }
}
