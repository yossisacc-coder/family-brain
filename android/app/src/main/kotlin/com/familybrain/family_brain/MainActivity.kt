package com.familybrain.family_brain

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val channelName = "family_brain/share"
    private var channel: MethodChannel? = null
    private var pending: HashMap<String, Any>? = null

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
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureShare(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureShare(intent)
        pending?.let {
            channel?.invokeMethod("onShare", it)
            pending = null
        }
    }

    private fun captureShare(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) return

        val data = HashMap<String, Any>()
        data["shareId"] = UUID.randomUUID().toString()
        data["source"] = "android_share"
        intent.type?.let { data["mimeType"] = it }

        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)?.trim()
        if (!subject.isNullOrEmpty()) data["subject"] = subject
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()
        if (!text.isNullOrEmpty()) data["text"] = text

        val paths = copyStreams(intent)
        if (paths.isNotEmpty()) {
            data["imagePath"] = paths.first()
            data["imagePaths"] = paths
        }
        if (!data.containsKey("text")) {
            readFirstTextUri(intent)?.let { data["text"] = it }
        }
        if (data.containsKey("text") ||
            data.containsKey("subject") ||
            data.containsKey("imagePath")
        ) {
            pending = data
        }
    }

    private fun copyUri(uri: Uri, intentType: String?): String? {
        return try {
            val mime = contentResolver.getType(uri) ?: intentType ?: return null
            if (!mime.startsWith("image/")) return null
            val input = contentResolver.openInputStream(uri) ?: return null
            input.use { stream ->
                val ext = extensionFor(mime)
                val file = File(cacheDir, "shared_${UUID.randomUUID()}.$ext")
                var written = 0
                FileOutputStream(file).use { output ->
                    val buffer = ByteArray(16 * 1024)
                    while (true) {
                        val read = stream.read(buffer)
                        if (read <= 0) break
                        written += read
                        if (written > MAX_BYTES) {
                            output.close()
                            file.delete()
                            return null
                        }
                        output.write(buffer, 0, read)
                    }
                }
                if (written == 0) {
                    file.delete()
                    return null
                }
                file.absolutePath
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun copyStreams(intent: Intent): ArrayList<String> {
        val paths = ArrayList<String>()
        val uris = streamUris(intent)
        for (uri in uris) {
            if (paths.size >= 8) break
            copyUri(uri, intent.type)?.let { paths.add(it) }
        }
        return paths
    }

    private fun readFirstTextUri(intent: Intent): String? {
        for (uri in streamUris(intent)) {
            val text = readTextUri(uri, intent.type)
            if (!text.isNullOrEmpty()) return text
        }
        return null
    }

    private fun readTextUri(uri: Uri, intentType: String?): String? {
        return try {
            val mime = contentResolver.getType(uri) ?: intentType ?: return null
            if (!mime.startsWith("text/")) return null
            val input = contentResolver.openInputStream(uri) ?: return null
            input.use { stream ->
                val bytes = ByteArray(MAX_TEXT_BYTES + 1)
                val read = stream.read(bytes)
                if (read <= 0) return null
                val count = minOf(read, MAX_TEXT_BYTES)
                String(bytes, 0, count, Charsets.UTF_8).trim().ifEmpty { null }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun streamUris(intent: Intent): List<Uri> {
        val found = ArrayList<Uri>()
        if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            val many = parcelableUriList(intent)
            if (many != null) found.addAll(many.filterNotNull())
        } else {
            parcelableUri(intent)?.let { found.add(it) }
        }
        intent.clipData?.let { clip ->
            for (i in 0 until clip.itemCount) {
                clip.getItemAt(i).uri?.let { uri ->
                    if (found.none { it == uri }) found.add(uri)
                }
            }
        }
        intent.data?.let { uri ->
            if (found.none { it == uri }) found.add(uri)
        }
        return found
    }

    private fun parcelableUri(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun parcelableUriList(intent: Intent): ArrayList<Uri>? {
        return if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun extensionFor(mime: String): String {
        return when (mime.lowercase()) {
            "image/png" -> "png"
            "image/webp" -> "webp"
            "image/gif" -> "gif"
            "image/heic", "image/heif" -> "heic"
            else -> "jpg"
        }
    }

    companion object {
        private const val MAX_BYTES = 8 * 1024 * 1024
        private const val MAX_TEXT_BYTES = 32 * 1024
    }
}
