package com.example.local_ocr

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    private val CHANNEL = "screenshot_channel"
    private val REQUEST_CODE = 1000

    private var methodChannel: MethodChannel? = null
    private var mediaProjection: MediaProjection? = null
    private var resultCode: Int = 0
    private var resultData: Intent? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestMediaProjection" -> {
                    requestScreenCapturePermission()
                    result.success(true)
                }
                "takeScreenshot" -> {
                    if (resultData != null) {
                        captureScreen(result)
                    } else {
                        result.error("NO_PERMISSION", "Screen capture not permitted", null)
                    }
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
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK && data != null) {
            this.resultCode = resultCode
            this.resultData = data
        }
    }

    private fun captureScreen(result: MethodChannel.Result) {
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, resultData!!)

        val metrics = resources.displayMetrics
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        val imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

        val virtualDisplay = mediaProjection?.createVirtualDisplay(
            "Screenshot",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader.surface, null, null
        )

        Handler(Looper.getMainLooper()).postDelayed({
            val image = imageReader.acquireLatestImage()
            if (image != null) {
                val path = saveImage(image, width, height)
                image.close()
                virtualDisplay?.release()
                imageReader.close()
                mediaProjection?.stop()
                result.success(path)
            } else {
                result.error("CAPTURE_FAILED", "Failed to capture", null)
            }
        }, 100)
    }

    private fun saveImage(image: Image, width: Int, height: Int): String {
        val planes = image.planes
        val buffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * width

        val bitmap = Bitmap.createBitmap(
            width + rowPadding / pixelStride,
            height,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)

        val croppedBitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height)

        val dir = File(cacheDir, "screenshots")
        if (!dir.exists()) dir.mkdirs()

        val file = File(dir, "screenshot_${System.currentTimeMillis()}.png")
        FileOutputStream(file).use {
            croppedBitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }

        bitmap.recycle()
        croppedBitmap.recycle()

        return file.absolutePath
    }
}