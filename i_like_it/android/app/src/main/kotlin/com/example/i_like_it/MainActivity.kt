package com.example.i_like_it

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "shared_link"
    private var isShareIntent = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        intent?.let {
            if (it.action == Intent.ACTION_SEND && it.type == "text/plain") {
                isShareIntent = true
                val sharedText = it.getStringExtra(Intent.EXTRA_TEXT)

                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    val channel = MethodChannel(messenger, CHANNEL)
                    channel.setMethodCallHandler { call, result ->
                        when (call.method) {
                            "closeApp" -> {
                                result.success(null)
                                finish()
                            }
                            else -> result.notImplemented()
                        }
                    }
                    channel.invokeMethod("sharedText", sharedText)
                }
            }
        }
    }
}
