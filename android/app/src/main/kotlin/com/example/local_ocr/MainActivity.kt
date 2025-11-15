package com.example.local_ocr

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.yourapp/screenshot"
    private val REQUEST_MEDIA_PROJECTION = 1001
    private val REQUEST_OVERLAY_PERMISSION = 1002

    private var pendingResult: MethodChannel.Result? = null
    private var screenshotCapture: ScreenshotCapture? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {

                // 🔹 Ask user for screen-capture permission once
                "requestMediaProjection" -> {
                    pendingResult = result
                    requestMediaProjection()
                }

                // 🔹 Take screenshot (no dialog each time)
                "takeScreenshot" -> {
                    if (ScreenshotCapture.resultData == null) {
                        result.error("NO_PERMISSION", "MediaProjection not granted yet", null)
                        return@setMethodCallHandler
                    }

                    if (screenshotCapture == null) {
                        screenshotCapture = ScreenshotCapture(this) { path, success ->
                            Handler(Looper.getMainLooper()).post {
                                if (success) result.success(path)
                                else result.error("CAPTURE_FAILED", "Failed to take screenshot", null)
                            }
                        }
                    }

                    screenshotCapture?.capture()
                }

                // 🔹 Release projection when session ends
                "releaseProjection" -> {
                    screenshotCapture?.release()
                    screenshotCapture = null
                    result.success(true)
                }

                // 🔹 Start overlay (floating button)
                "startService" -> {
                    if (checkOverlayPermission()) {
                        val intent = Intent(this, OverlayService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } else {
                        requestOverlayPermission()
                        result.success(false)
                    }
                }

                "stopService" -> {
                    stopService(Intent(this, OverlayService::class.java))
                    result.success(true)
                }

                // 🔹 Update floating button stats
                "updateSuccess" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = "UPDATE_SUCCESS"
                    }
                    startService(intent)
                    result.success(true)
                }

                "updateFailed" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = "UPDATE_FAILED"
                    }
                    startService(intent)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // Make channel accessible to the OverlayService
        OverlayService.methodChannel = methodChannel
    }

    // ✅ Request MediaProjection permission (shows system dialog once)
    private fun requestMediaProjection() {
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val intent = projectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_MEDIA_PROJECTION)
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else true
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            REQUEST_MEDIA_PROJECTION -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    ScreenshotCapture.resultCode = resultCode
                    ScreenshotCapture.resultData = data
                    pendingResult?.success(true)
                } else {
                    pendingResult?.success(false)
                }
                pendingResult = null
            }

            REQUEST_OVERLAY_PERMISSION -> {
                if (checkOverlayPermission()) {
                    // You can now start overlay service safely
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        screenshotCapture?.release()
    }
}
