package com.example.local_ocr

import android.content.Context
import android.content.Intent
import android.content.res.Resources
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
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

class ScreenshotCapture(
    private val context: Context,
    private val callback: (String, Boolean) -> Unit
) {
    private var mediaProjection: MediaProjection? = null
    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null

    companion object {
        var resultCode: Int = 0
        var resultData: Intent? = null
    }

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            super.onStop()
            cleanupProjection()
        }
    }

    fun capture() {
        // ✅ Only create MediaProjection once per session
        if (mediaProjection == null) {
            createMediaProjection()
        }

        val displayMetrics = Resources.getSystem().displayMetrics
        val width = displayMetrics.widthPixels
        val height = displayMetrics.heightPixels
        val density = displayMetrics.densityDpi

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)

        try {
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "ScreenCapture_${System.currentTimeMillis()}",
                width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface, null, null
            )

            // Add slight delay to ensure the frame is ready
            Handler(Looper.getMainLooper()).postDelayed({
                processImage()
            }, 300)
        } catch (e: Exception) {
            e.printStackTrace()
            callback("", false)
            cleanupAfterCapture()
        }
    }

    private fun createMediaProjection() {
        val projectionManager = context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, resultData!!)

        if (Build.VERSION.SDK_INT >= 34) {
            mediaProjection?.registerCallback(projectionCallback, Handler(Looper.getMainLooper()))
        }
    }

    private fun processImage() {
        val image: Image? = imageReader?.acquireLatestImage()

        if (image != null) {
            try {
                val bitmap = imageToBitmap(image)
                val path = saveBitmap(bitmap)
                callback(path, true)
            } catch (e: Exception) {
                e.printStackTrace()
                callback("", false)
            } finally {
                image.close()
                cleanupAfterCapture()
            }
        } else {
            callback("", false)
            cleanupAfterCapture()
        }
    }

    private fun imageToBitmap(image: Image): Bitmap {
        val planes = image.planes
        val buffer: ByteBuffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * image.width

        val bitmap = Bitmap.createBitmap(
            image.width + rowPadding / pixelStride,
            image.height,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)

        return Bitmap.createBitmap(bitmap, 0, 0, image.width, image.height)
    }

    private fun saveBitmap(bitmap: Bitmap): String {
        val cacheDir = File(context.cacheDir, "screenshots")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }

        val timestamp = System.currentTimeMillis()
        val file = File(cacheDir, "screenshot_$timestamp.png")

        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }

        bitmap.recycle()
        return file.absolutePath
    }

    // ✅ Clean up only temporary resources (not MediaProjection)
    private fun cleanupAfterCapture() {
        try {
            virtualDisplay?.release()
            virtualDisplay = null

            imageReader?.close()
            imageReader = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ✅ Fully release when session ends
    fun release() {
        try {
            if (Build.VERSION.SDK_INT >= 34) {
                mediaProjection?.unregisterCallback(projectionCallback)
            }
            mediaProjection?.stop()
            mediaProjection = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // 🔒 Internal cleanup if projection unexpectedly stopped
    private fun cleanupProjection() {
        mediaProjection = null
    }
}
