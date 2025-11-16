package com.example.local_ocr

import android.app.*
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
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class ScreenshotForegroundService : Service() {
    
    companion object {
        const val CHANNEL_ID = "screenshot_service_channel"
        const val NOTIFICATION_ID = 1001
        
        private var instance: ScreenshotForegroundService? = null
        private var methodChannel: MethodChannel? = null
        
        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
        
        fun isRunning(): Boolean = instance != null
    }

    private var mediaProjection: MediaProjection? = null
    private var resultCode: Int = 0
    private var resultData: Intent? = null
    
    private var successCount = 0
    private var failedCount = 0

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START_SERVICE" -> {
                resultCode = intent.getIntExtra("resultCode", 0)
                resultData = intent.getParcelableExtra("resultData")
                initMediaProjection()
            }
            "STOP_SERVICE" -> {
                stopService()
            }
            "TAKE_SCREENSHOT" -> {
                takeScreenshot()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "خدمة التقاط الشاشة",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "يعمل في الخلفية لالتقاط لقطات الشاشة"
                setShowBadge(false)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val stopIntent = Intent(this, ScreenshotForegroundService::class.java).apply {
            action = "STOP_SERVICE"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("خدمة OCR نشطة")
            .setContentText("جاهز لالتقاط الشاشة - ناجح: $successCount | فاشل: $failedCount")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "إيقاف",
                stopPendingIntent
            )
            .build()
    }

    private fun updateNotification() {
        val notification = createNotification()
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun initMediaProjection() {
        if (resultData == null) {
            notifyFlutter("onServiceFailed", "No permission data")
            stopService()
            return
        }

        try {
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = projectionManager.getMediaProjection(resultCode, resultData!!)
            
            mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    notifyFlutter("onServiceStopped", null)
                    stopService()
                }
            }, null)
            
            notifyFlutter("onServiceStarted", null)
        } catch (e: Exception) {
            notifyFlutter("onServiceFailed", e.message)
            stopService()
        }
    }

    private fun takeScreenshot() {
        if (mediaProjection == null) {
            notifyFlutter("onScreenshotFailed", "MediaProjection is null")
            failedCount++
            updateNotification()
            return
        }

        try {
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
                try {
                    val image = imageReader.acquireLatestImage()
                    if (image != null) {
                        val path = saveImage(image, width, height)
                        image.close()
                        virtualDisplay?.release()
                        imageReader.close()
                        
                        successCount++
                        updateNotification()
                        notifyFlutter("onScreenshotCaptured", path)
                    } else {
                        failedCount++
                        updateNotification()
                        notifyFlutter("onScreenshotFailed", "Image is null")
                    }
                } catch (e: Exception) {
                    failedCount++
                    updateNotification()
                    notifyFlutter("onScreenshotFailed", e.message ?: "Unknown error")
                }
            }, 300) // زيادة الوقت لضمان إخفاء الـ overlay
            
        } catch (e: Exception) {
            failedCount++
            updateNotification()
            notifyFlutter("onScreenshotFailed", e.message ?: "Unknown error")
        }
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

    private fun notifyFlutter(method: String, argument: Any?) {
        Handler(Looper.getMainLooper()).post {
            try {
                methodChannel?.invokeMethod(method, argument)
            } catch (e: Exception) {
                android.util.Log.e("ScreenshotService", "Error notifying Flutter: ${e.message}")
            }
        }
    }

    private fun stopService() {
        mediaProjection?.stop()
        mediaProjection = null
        instance = null
        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopService()
    }
}