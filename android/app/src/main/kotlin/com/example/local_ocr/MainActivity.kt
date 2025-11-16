package com.example.local_ocr

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "screenshot_channel"
    private val REQUEST_CODE = 1000

    private var methodChannel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // إعطاء الـ Service إمكانية التواصل مع Flutter
        ScreenshotForegroundService.setMethodChannel(methodChannel!!)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestMediaProjection" -> {
                    pendingResult = result
                    requestScreenCapturePermission()
                }
                "startService" -> {
                    result.success(ScreenshotForegroundService.isRunning())
                }
                "stopService" -> {
                    stopScreenshotService()
                    result.success(true)
                }
                "takeScreenshot" -> {
                    requestScreenshot()
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(ScreenshotForegroundService.isRunning())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestScreenCapturePermission() {
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                startScreenshotService(resultCode, data)
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    private fun startScreenshotService(resultCode: Int, data: Intent) {
        val serviceIntent = Intent(this, ScreenshotForegroundService::class.java).apply {
            action = "START_SERVICE"
            putExtra("resultCode", resultCode)
            putExtra("resultData", data)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopScreenshotService() {
        val serviceIntent = Intent(this, ScreenshotForegroundService::class.java).apply {
            action = "STOP_SERVICE"
        }
        startService(serviceIntent)
    }

    private fun requestScreenshot() {
        val serviceIntent = Intent(this, ScreenshotForegroundService::class.java).apply {
            action = "TAKE_SCREENSHOT"
        }
        startService(serviceIntent)
    }
}