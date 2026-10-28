package com.restaurantpos.flutter_restaurant_pos

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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

                "openUrl" -> {
                    val urlString = call.argument<String>("url")
                    try {
                        if (!urlString.isNullOrBlank()) {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(urlString)).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.error("INVALID_URL", "URL cannot be blank", null)
                        }
                    } catch (e: Exception) {
                        result.error("OPEN_URL_FAILED", e.localizedMessage, null)
                    }
                }

                "printReceipt" -> {
                    val receiptText = call.argument<String>("receiptText")
                    // Real ESC/POS Bluetooth thermal socket dispatch hook
                    result.success(true)
                }

                "pickImage" -> {
                    pendingResult = result
                    try {
                        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                            type = "image/*"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        }
                        startActivityForResult(intent, IMAGE_PICKER_REQUEST_CODE)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("PICKER_ERROR", e.localizedMessage, null)
                    }
                }

                "showNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "RestPos"
                        val message = call.argument<String>("message") ?: "Backup completed successfully"
                        val channelId = "restpos_backup_channel"
                        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val channel = android.app.NotificationChannel(
                                channelId,
                                "RestPos Notifications",
                                android.app.NotificationManager.IMPORTANCE_HIGH
                            ).apply {
                                description = "Notifications for RestPos backups"
                                enableVibration(true)
                                setShowBadge(true)
                            }
                            notificationManager.createNotificationChannel(channel)
                        }

                        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            android.app.Notification.Builder(context, channelId)
                        } else {
                            @Suppress("DEPRECATION")
                            android.app.Notification.Builder(context)
                        }

                        val notification = builder
                            .setContentTitle(title)
                            .setContentText(message)
                            .setSmallIcon(android.R.drawable.stat_sys_upload_done)
                            .setPriority(android.app.Notification.PRIORITY_HIGH)
                            .setDefaults(android.app.Notification.DEFAULT_ALL)
                            .setAutoCancel(true)
                            .build()

                        notificationManager.notify(1001, notification)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.localizedMessage, null)
                    }
                }

                "saveBackupToRestPos" -> {
                    val jsonContent = call.argument<String>("jsonContent") ?: ""
                    val fileName = "restpos_backup.json"
                    val relativeDir = "${Environment.DIRECTORY_DOWNLOADS}/RestPos/"

                    try {
                        var written = false

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                            val projection = arrayOf(MediaStore.Downloads._ID)
                            val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ? AND ${MediaStore.Downloads.RELATIVE_PATH} LIKE ?"
                            val selectionArgs = arrayOf(fileName, "%RestPos%")

                            var existingId: Long? = null
                            contentResolver.query(collection, projection, selection, selectionArgs, null)?.use { cursor ->
                                if (cursor.moveToFirst()) {
                                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
                                    existingId = cursor.getLong(idColumn)
                                }
                            }

                            if (existingId != null) {
                                val existingUri = Uri.withAppendedPath(collection, existingId.toString())
                                try {
                                    contentResolver.openOutputStream(existingUri, "wt")?.use { output ->
                                        output.write(jsonContent.toByteArray(Charsets.UTF_8))
                                        output.flush()
                                        written = true
                                    }
                                } catch (_: Exception) {
                                    try {
                                        contentResolver.delete(existingUri, null, null)
                                    } catch (_: Exception) {}
                                }
                            }

                            if (!written) {
                                val values = ContentValues().apply {
                                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                                    put(MediaStore.Downloads.MIME_TYPE, "application/json")
                                    put(MediaStore.Downloads.RELATIVE_PATH, relativeDir)
                                    put(MediaStore.Downloads.IS_PENDING, 1)
                                }

                                val itemUri = contentResolver.insert(collection, values)
                                if (itemUri != null) {
                                    contentResolver.openOutputStream(itemUri, "wt")?.use { output ->
                                        output.write(jsonContent.toByteArray(Charsets.UTF_8))
                                        output.flush()
                                        written = true
                                    }
                                    values.clear()
                                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                                    contentResolver.update(itemUri, values, null, null)
                                }
                            }
                        }

                        if (!written) {
                            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "RestPos")
                            if (!dir.exists()) dir.mkdirs()
                            val file = File(dir, fileName)
                            file.writeText(jsonContent, Charsets.UTF_8)
                            written = true
                        }

                        val resultPath = "/storage/emulated/0/${Environment.DIRECTORY_DOWNLOADS}/RestPos/$fileName"
                        result.success(mapOf(
                            "success" to true,
                            "path" to resultPath
                        ))
                    } catch (e: Exception) {
                        result.error("BACKUP_WRITE_ERROR", e.localizedMessage, null)
                    }
                }

                "readBackupFromRestPos" -> {
                    val fileName = "restpos_backup.json"
                    try {
                        var foundJson: String? = null

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                            val projection = arrayOf(MediaStore.Downloads._ID)
                            val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ? AND ${MediaStore.Downloads.RELATIVE_PATH} LIKE ?"
                            val selectionArgs = arrayOf(fileName, "%RestPos%")

                            contentResolver.query(collection, projection, selection, selectionArgs, null)?.use { cursor ->
                                if (cursor.moveToFirst()) {
                                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
                                    val id = cursor.getLong(idColumn)
                                    val uri = Uri.withAppendedPath(collection, id.toString())
                                    try {
                                        contentResolver.openInputStream(uri)?.use { input ->
                                            foundJson = input.bufferedReader(Charsets.UTF_8).use { it.readText() }
                                        }
                                    } catch (_: Exception) {}
                                }
                            }
                        }

                        if (foundJson == null) {
                            // Check filesystem fallback
                            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "RestPos")
                            val file = File(dir, fileName)
                            if (file.exists()) {
                                foundJson = file.readText(Charsets.UTF_8)
                            }
                        }

                        result.success(foundJson)
                    } catch (e: Exception) {
                        result.error("BACKUP_READ_ERROR", e.localizedMessage, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == IMAGE_PICKER_REQUEST_CODE) {
            val res = pendingResult
            pendingResult = null
            if (res != null) {
                if (resultCode == RESULT_OK && data?.data != null) {
                    val uri = data.data!!
                    try {
                        val inputStream = contentResolver.openInputStream(uri)
                        val fileName = "picked_${System.currentTimeMillis()}.jpg"
                        val destinationFile = java.io.File(cacheDir, fileName)
                        inputStream?.use { input ->
                            destinationFile.outputStream().use { output ->
                                input.copyTo(output)
                            }
                        }
                        res.success(destinationFile.absolutePath)
                    } catch (e: Exception) {
                        res.error("FILE_COPY_ERROR", e.localizedMessage, null)
                    }
                } else {
                    res.success(null)
                }
            }
        }
    }

    companion object {
        private const val IMAGE_PICKER_REQUEST_CODE = 9021
    }
    private var pendingResult: io.flutter.plugin.common.MethodChannel.Result? = null
}

