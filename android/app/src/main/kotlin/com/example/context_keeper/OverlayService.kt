package com.example.context_keeper

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "HIDE_OVERLAY") {
            hideOverlay()
            return START_NOT_STICKY
        }

        val contactName = intent?.getStringExtra("contactName") ?: ""
        val notes = intent?.getStringExtra("notes") ?: ""

        if (contactName.isNotEmpty() && notes.isNotEmpty()) {
            showOverlay(contactName, notes)
        }

        return START_STICKY
    }

    private fun showOverlay(contactName: String, notes: String) {
        if (overlayView != null) {
            hideOverlay()
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        // Inflate overlay layout
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_layout, null)

        // Set content
        overlayView?.findViewById<TextView>(R.id.contactName)?.text = contactName
        overlayView?.findViewById<TextView>(R.id.notes)?.text = notes

        // Set close button
        overlayView?.findViewById<View>(R.id.closeButton)?.setOnClickListener {
            hideOverlay()
        }

        // Configure window parameters
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = 100
        }

        try {
            windowManager?.addView(overlayView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun hideOverlay() {
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        overlayView = null
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
    }
}
