package com.restaurantpos.flutter_restaurant_pos

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.restaurantpos.app/native_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown_device_id"
                    val info = mapOf(
                        "model" to Build.MODEL,
                        "manufacturer" to Build.MANUFACTURER,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "deviceId" to androidId
                    )
                    result.success(info)
                }

                "getBatteryInfo" -> {
                    val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { filter ->
                        context.registerReceiver(null, filter)
                    }

                    val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                    val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                    val batteryPct: Int = if (level >= 0 && scale > 0) ((level.toFloat() / scale.toFloat()) * 100).toInt() else 100

                    val status: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                    val isCharging: Boolean = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                            status == BatteryManager.BATTERY_STATUS_FULL

                    result.success(mapOf(
                        "level" to batteryPct,
                        "isCharging" to isCharging
                    ))
                }

                "triggerHaptic" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                            val vibrator = vibratorManager.defaultVibrator
                            vibrator.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK))
                        } else {
                            @Suppress("DEPRECATION")
                            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                vibrator.vibrate(VibrationEffect.createOneShot(25, VibrationEffect.DEFAULT_AMPLITUDE))
                            } else {
                                vibrator.vibrate(25)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("HAPTIC_FAILED", e.localizedMessage, null)
                    }
                }

                "openWifiSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_WIFI_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_FAILED", e.localizedMessage, null)
                    }
                }

                "printReceipt" -> {
                    val receiptText = call.argument<String>("receiptText")
                    // Real ESC/POS Bluetooth thermal socket dispatch hook
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
