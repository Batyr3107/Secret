package com.example.context_keeper

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.context_keeper/phone"
    private val PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPhoneService" -> {
                    startPhoneStateService()
                    result.success(true)
                }
                "stopPhoneService" -> {
                    stopPhoneStateService()
                    result.success(true)
                }
                "showOverlay" -> {
                    val contactName = call.argument<String>("contactName") ?: ""
                    val notes = call.argument<String>("notes") ?: ""
                    showOverlay(contactName, notes)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Request permissions on app start
        requestPhonePermissions()
    }

    private fun requestPhonePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val permissions = mutableListOf(
                Manifest.permission.READ_PHONE_STATE,
                Manifest.permission.READ_CONTACTS
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                permissions.add(Manifest.permission.POST_NOTIFICATIONS)
            }

            val notGranted = permissions.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }

            if (notGranted.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, notGranted.toTypedArray(), PERMISSION_REQUEST_CODE)
            }
        }
    }

    private fun startPhoneStateService() {
        val intent = Intent(this, PhoneStateService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopPhoneStateService() {
        val intent = Intent(this, PhoneStateService::class.java)
        stopService(intent)
    }

    private fun showOverlay(contactName: String, notes: String) {
        val intent = Intent(this, OverlayService::class.java).apply {
            putExtra("contactName", contactName)
            putExtra("notes", notes)
        }
        startService(intent)
    }
}
