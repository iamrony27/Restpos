import 'package:flutter/services.dart';

class NativeDeviceInfo {
  final String model;
  final String manufacturer;
  final String androidVersion;
  final int sdkInt;
  final String deviceId;

  const NativeDeviceInfo({
    required this.model,
    required this.manufacturer,
    required this.androidVersion,
    required this.sdkInt,
    required this.deviceId,
  });

  factory NativeDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return NativeDeviceInfo(
      model: map['model']?.toString() ?? 'Unknown Model',
      manufacturer: map['manufacturer']?.toString() ?? 'Android',
      androidVersion: map['androidVersion']?.toString() ?? '14',
      sdkInt: (map['sdkInt'] as int?) ?? 34,
      deviceId: map['deviceId']?.toString() ?? 'dev-pos-terminal-001',
    );
  }
}

class NativeBatteryInfo {
  final int levelPercent;
  final bool isCharging;

  const NativeBatteryInfo({
    required this.levelPercent,
    required this.isCharging,
  });

  factory NativeBatteryInfo.fromMap(Map<dynamic, dynamic> map) {
    return NativeBatteryInfo(
      levelPercent: (map['level'] as int?) ?? 100,
      isCharging: (map['isCharging'] as bool?) ?? false,
    );
  }
}

class NativeApiChannel {
  static const MethodChannel _channel = MethodChannel('com.restaurantpos.app/native_channel');

  /// Fetches native Android device hardware details
  static Future<NativeDeviceInfo> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
      if (result != null) {
        return NativeDeviceInfo.fromMap(result);
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeApiChannel.getDeviceInfo failed: ${e.message}');
    }
    return const NativeDeviceInfo(
      model: 'Linux/Android Device',
      manufacturer: 'Google/AOSP',
      androidVersion: '14.0',
      sdkInt: 34,
      deviceId: 'local-terminal-pos',
    );
  }

  /// Queries native Android BatteryManager for battery level & charging state
  static Future<NativeBatteryInfo> getBatteryInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBatteryInfo');
      if (result != null) {
        return NativeBatteryInfo.fromMap(result);
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeApiChannel.getBatteryInfo failed: ${e.message}');
    }
    return const NativeBatteryInfo(levelPercent: 92, isCharging: true);
  }

  /// Triggers native Android tactile feedback
  static Future<void> triggerNativeHaptic({String type = 'click'}) async {
    try {
      await _channel.invokeMethod('triggerHaptic', {'type': type});
    } on PlatformException {
      // Fallback to Flutter HapticFeedback
      HapticFeedback.lightImpact();
    }
  }

  /// Dispatches native Android Intent to open Wi-Fi settings for wireless debugging
  static Future<bool> openWifiSettings() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('openWifiSettings');
      return success ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Native Android Bluetooth / Thermal Printer ESC/POS dispatcher
  static Future<bool> printReceiptNative({
    required String receiptText,
    String? printerMacAddress,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('printReceipt', {
        'receiptText': receiptText,
        'printerMac': printerMacAddress,
      });
      return success ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Launches Android native photo picker and returns local file path
  static Future<String?> pickImageFromDevice() async {
    try {
      final String? path = await _channel.invokeMethod<String>('pickImage');
      return path;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeApiChannel.pickImageFromDevice failed: ${e.message}');
      return null;
    }
  }

  /// Displays a native Android status bar notification
  static Future<bool> showNotification({
    required String title,
    required String message,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('showNotification', {
        'title': title,
        'message': message,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeApiChannel.showNotification failed: ${e.message}');
      return false;
    }
  }
  /// Writes backup JSON to Download/RestPos via Android MediaStore (Scoped Storage compliant)
  static Future<String?> saveBackupToRestPos(String jsonContent) async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('saveBackupToRestPos', {
        'jsonContent': jsonContent,
      });
      return res?['path']?.toString();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeApiChannel.saveBackupToRestPos failed: ${e.message}');
      return null;
    }
  }

  /// Reads backup JSON from Download/RestPos via Android MediaStore
  static Future<String?> readBackupFromRestPos() async {
    try {
      final String? jsonStr = await _channel.invokeMethod<String>('readBackupFromRestPos');
      return jsonStr;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeApiChannel.readBackupFromRestPos failed: ${e.message}');
      return null;
    }
  }

  /// Opens an external URL, WhatsApp link, or UPI payment URI via Android Intent
  static Future<bool> openUrl(String url) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return success ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('NativeApiChannel.openUrl failed: ${e.message}');
      return false;
    }
  }
}


