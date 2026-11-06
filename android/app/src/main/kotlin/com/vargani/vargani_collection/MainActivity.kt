package com.vargani.vargani_collection

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vargani.vargani_collection/whatsapp_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sharePdfToWhatsApp") {
                val filePath = call.argument<String>("filePath")
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")

                if (filePath == null) {
                    result.error("INVALID_PATH", "File path cannot be null", null)
                    return@setMethodCallHandler
                }

                try {
                    val file = File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "File does not exist: $filePath", null)
                        return@setMethodCallHandler
                    }

                    val authority = "${applicationContext.packageName}.vargani_file_provider"
                    val contentUri: Uri = FileProvider.getUriForFile(applicationContext, authority, file)

                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_STREAM, contentUri)
                        if (!message.isNullOrEmpty()) {
                            putExtra(Intent.EXTRA_TEXT, message)
                        }
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }

                    var targetNumber = phoneNumber?.replace(Regex("[^0-9]"), "") ?: ""
                    if (targetNumber.length == 10) {
                        targetNumber = "91$targetNumber"
                    }

                    if (targetNumber.isNotEmpty()) {
                        intent.putExtra("jid", "$targetNumber@s.whatsapp.net")
                    }

                    val pm = packageManager
                    val isWhatsAppInstalled = try {
                        pm.getPackageInfo("com.whatsapp", 0)
                        true
                    } catch (e: Exception) {
                        false
                    }

                    val isBusinessInstalled = try {
                        pm.getPackageInfo("com.whatsapp.w4b", 0)
                        true
                    } catch (e: Exception) {
                        false
                    }

                    if (isWhatsAppInstalled) {
                        intent.setPackage("com.whatsapp")
                        startActivity(intent)
                        result.success(true)
                    } else if (isBusinessInstalled) {
                        intent.setPackage("com.whatsapp.w4b")
                        startActivity(intent)
                        result.success(true)
                    } else {
                        val chooser = Intent.createChooser(intent, "पावती शेअर करा")
                        startActivity(chooser)
                        result.success(true)
                    }
                } catch (e: Exception) {
                    result.error("SHARE_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
