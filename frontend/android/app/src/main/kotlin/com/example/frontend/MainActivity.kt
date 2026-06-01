package com.example.frontend

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gridpool/upi"
    private val UPI_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "initiateTransaction") {
                val url = call.argument<String>("url")
                if (url != null) {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    
                    try {
                        startActivityForResult(intent, UPI_REQUEST_CODE)
                    } catch (e: Exception) {
                        result.error("LAUNCH_FAILED", e.message, null)
                        pendingResult = null
                    }
                } else {
                    result.error("INVALID_URL", "URL is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == UPI_REQUEST_CODE) {
            if (data != null) {
                val response = data.getStringExtra("response") ?: "Status=FAILURE&error=NoResponse"
                pendingResult?.success(response)
            } else {
                pendingResult?.success("Status=FAILURE&error=DataNull")
            }
            pendingResult = null
        }
    }
}
