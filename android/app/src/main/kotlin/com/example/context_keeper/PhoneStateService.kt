package com.example.context_keeper

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat

class PhoneStateService : Service() {
    private lateinit var telephonyManager: TelephonyManager
    private var phoneStateListener: PhoneStateListener? = null
    private var telephonyCallback: TelephonyCallback? = null

    companion object {
        private const val CHANNEL_ID = "PhoneStateServiceChannel"
        private const val NOTIFICATION_ID = 1
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        startListening()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Phone State Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors incoming calls to show contact notes"
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Context Keeper")
            .setContentText("Monitoring incoming calls...")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startListening() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE)
            != PackageManager.PERMISSION_GRANTED) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Use TelephonyCallback for Android 12+
            telephonyCallback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                override fun onCallStateChanged(state: Int) {
                    handleCallStateChange(state)
                }
            }
            telephonyManager.registerTelephonyCallback(mainExecutor, telephonyCallback!!)
        } else {
            // Use deprecated PhoneStateListener for older versions
            @Suppress("DEPRECATION")
            phoneStateListener = object : PhoneStateListener() {
                @Deprecated("Deprecated in Java")
                override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                    handleCallStateChange(state, phoneNumber)
                }
            }
            @Suppress("DEPRECATION")
            telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
        }
    }

    private fun handleCallStateChange(state: Int, phoneNumber: String? = null) {
        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                phoneNumber?.let {
                    onIncomingCall(it)
                }
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                // Call ended
                hideOverlay()
            }
        }
    }

    private fun onIncomingCall(phoneNumber: String) {
        // Send broadcast to Flutter app
        val intent = Intent("com.example.context_keeper.INCOMING_CALL").apply {
            putExtra("phoneNumber", phoneNumber)
        }
        sendBroadcast(intent)
    }

    private fun hideOverlay() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = "HIDE_OVERLAY"
        }
        startService(intent)
    }

    override fun onDestroy() {
        super.onDestroy()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            telephonyCallback?.let {
                telephonyManager.unregisterTelephonyCallback(it)
            }
        } else {
            @Suppress("DEPRECATION")
            phoneStateListener?.let {
                telephonyManager.listen(it, PhoneStateListener.LISTEN_NONE)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
