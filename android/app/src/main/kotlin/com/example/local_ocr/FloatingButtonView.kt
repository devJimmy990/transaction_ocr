package com.example.local_ocr
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.view.*
import android.view.animation.AnimationUtils
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat

@SuppressLint("ClickableViewAccessibility")
class FloatingButtonView(
    private val context: Context,
    private val screenshotCapture: ScreenshotCapture,
    private val screenshotQueue: ScreenshotQueue
) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val floatingView: View = LayoutInflater.from(context)
        .inflate(R.layout.floating_button_layout, null)
    
    private val btnScreenshot: ImageView = floatingView.findViewById(R.id.camera_icon)
    private val tvSuccessCount: TextView = floatingView.findViewById(R.id.success_count)
    private val tvFailedCount: TextView = floatingView.findViewById(R.id.failed_count)
    
    private var successCount = 0
    private var failedCount = 0
    
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var longPressTimer: android.os.Handler? = null
    private var isLongPress = false

    private val params = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            WindowManager.LayoutParams.TYPE_PHONE,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
        PixelFormat.TRANSLUCENT
    ).apply {
        gravity = Gravity.TOP or Gravity.END
        x = 20
        y = 100
    }

    init {
        setupTouchListener()
    }

    fun show() {
        try {
            windowManager.addView(floatingView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun remove() {
        try {
            windowManager.removeView(floatingView)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun updateSuccessCount() {
        successCount++
        tvSuccessCount.text = successCount.toString()
    }

    fun updateFailedCount() {
        failedCount++
        tvFailedCount.text = failedCount.toString()
    }

    private fun setupTouchListener() {
        btnScreenshot.setOnTouchListener { view, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isLongPress = false
                    
                    // Start long press timer
                    longPressTimer = android.os.Handler(android.os.Looper.getMainLooper())
                    longPressTimer?.postDelayed({
                        isLongPress = true
                        onLongPress()
                    }, 500)
                    
                    true
                }
                
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    
                    // If moved, cancel long press
                    if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                        longPressTimer?.removeCallbacksAndMessages(null)
                        
                        params.x = initialX - dx
                        params.y = initialY + dy
                        windowManager.updateViewLayout(floatingView, params)
                    }
                    true
                }
                
                MotionEvent.ACTION_UP -> {
                    longPressTimer?.removeCallbacksAndMessages(null)
                    
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    
                    // If minimal movement and not long press, it's a click
                    if (Math.abs(dx) < 10 && Math.abs(dy) < 10 && !isLongPress) {
                        onClick()
                    }
                    true
                }
                
                else -> false
            }
        }
    }

    private fun onClick() {
        // Animate button
        val shake = AnimationUtils.loadAnimation(context, android.R.anim.fade_in)
        btnScreenshot.startAnimation(shake)

        // Hide button temporarily
        floatingView.visibility = View.INVISIBLE

        // Capture screenshot after delay
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            try {
                screenshotCapture.capture()
            } catch (e: Exception) {
                e.printStackTrace()
                // Show error toast
                android.widget.Toast.makeText(
                    context,
                    "Screenshot failed: ${e.message}",
                    android.widget.Toast.LENGTH_SHORT
                ).show()
            }

            // Show button again
            floatingView.visibility = View.VISIBLE
        }, 300)
    }

    private fun onLongPress() {
        // Vibrate feedback
        val vibrator = ContextCompat.getSystemService(context, android.os.Vibrator::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(android.os.VibrationEffect.createOneShot(50, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            vibrator?.vibrate(50)
        }
        
        // Stop service
        context.stopService(Intent(context, OverlayService::class.java))
        
        // Return to app
        OverlayService.methodChannel?.invokeMethod("onServiceStopped", null)
    }
}