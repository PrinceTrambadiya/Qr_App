package com.example.qr_tester

import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

// flutter method channel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall

// permissions
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import android.Manifest
import androidx.core.app.ActivityCompat


class MainActivity: FlutterActivity() {
    private val PERMISSION_CHANNEL = "io.kernellabs.pitch_conferencing/permissions"
    private val METHOD_CHECK_CAMERA = "checkCamera"
    private val METHOD_REQUEST_CAMERA = "requestCamera"
    private val CAMERA_PERMISSION_REQUEST_CODE = 1

    // method channel result
    var currentResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)

        MethodChannel(flutterView, PERMISSION_CHANNEL).setMethodCallHandler { platformCall, result ->
            // TODO: this MethodChannel should probably be separated into a different file
            when (platformCall.method) {
                METHOD_CHECK_CAMERA -> handleMethodCheckCamera(platformCall, result)
                METHOD_REQUEST_CAMERA -> handleMethodRequestCamera(platformCall, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleMethodCheckCamera(platformCall: MethodCall, result: MethodChannel.Result): Unit {
        val resultCamera: Int = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
        val permitted = resultCamera == PackageManager.PERMISSION_GRANTED
        result.success(permitted)
    }

    /**
     * result is false if the user denies camera access
     */
    private fun handleMethodRequestCamera(platformCall: MethodCall, result: MethodChannel.Result): Unit {
        val resultCamera: Int = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
        val alreadyPermitted = resultCamera == PackageManager.PERMISSION_GRANTED
        if (alreadyPermitted) return result.success(true)
        
        // request user for mic access
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_REQUEST_CODE
        )
        currentResult = result
        // result will be called in onRequestPermissionsResult()
    }

    fun IntArray.containsOnly(num: Int): Boolean = filter { it == num }.isNotEmpty()
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        val granted = grantResults.containsOnly(PackageManager.PERMISSION_GRANTED)
        currentResult?.success(granted);
        currentResult = null
    }
}
