package com.example.local_ocr


import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class OverlayService : Service() {
    private var floatingButtonView: FloatingButtonView? = null
    private var screenshotCapture: ScreenshotCapture? = null
    private val screenshotQueue = ScreenshotQueue()
    
    companion object {
        const val CHANNEL_ID = "screenshot_service_channel"
        const val NOTIFICATION_ID = 1001
        var methodChannel: MethodChannel? = null
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        screenshotCapture = ScreenshotCapture(this) { imagePath, success ->
            if (success) {
                screenshotQueue.add(imagePath)
                sendToFlutter(imagePath)
            } else {
                notifyFailure(imagePath)
            }
        }
        
        floatingButtonView = FloatingButtonView(this, screenshotCapture!!, screenshotQueue)
        floatingButtonView?.show()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    intent?.let {
        when (it.action) {
            "STOP_SERVICE" -> stopSelf()
            "UPDATE_SUCCESS" -> floatingButtonView?.updateSuccessCount()
            "UPDATE_FAILED" -> floatingButtonView?.updateFailedCount()
            else -> {} 
        }
    }
    return START_STICKY
}


    override fun onDestroy() {
        floatingButtonView?.remove()
        screenshotCapture?.release()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screenshot Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Running screenshot capture service"
                setShowBadge(false)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screenshot Service")
            .setContentText("Tap to return to app")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun sendToFlutter(imagePath: String) {
        methodChannel?.invokeMethod("onScreenshotCaptured", imagePath)
    }

    private fun notifyFailure(imagePath: String) {
        methodChannel?.invokeMethod("onScreenshotFailed", imagePath)
    }
}