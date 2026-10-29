import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/channels/native_api_channel.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import '../models/restaurant_profile.dart';
import '../models/table_model.dart';

class BackupData {
  final int version;
  final String exportedAt;
  final RestaurantProfile profile;
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final List<RestaurantTable> tables;
  final List<Order> orders;

  const BackupData({
    required this.version,
    required this.exportedAt,
    required this.profile,
    required this.categories,
    required this.items,
    required this.tables,
    required this.orders,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'exported_at': exportedAt,
      'profile': profile.toMap(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'items': items.map((i) => i.toMap()).toList(),
      'tables': tables.map((t) => t.toMap()).toList(),
      'orders': orders.map((o) => o.toMap()).toList(),
    };
  }

  factory BackupData.fromMap(Map<String, dynamic> map) {
    final rawCats = map['categories'] as List<dynamic>? ?? [];
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final rawTables = map['tables'] as List<dynamic>? ?? [];
    final rawOrders = map['orders'] as List<dynamic>? ?? [];

    return BackupData(
      version: (map['version'] as int?) ?? 1,
      exportedAt: map['exported_at'] as String? ?? DateTime.now().toIso8601String(),
      profile: map['profile'] != null
          ? RestaurantProfile.fromMap(map['profile'] as Map<String, dynamic>)
          : const RestaurantProfile(),
      categories: rawCats
          .map((c) => MenuCategory.fromMap(c as Map<String, dynamic>))
          .toList(),
      items: rawItems
          .map((i) => MenuItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      tables: rawTables
          .map((t) => RestaurantTable.fromMap(t as Map<String, dynamic>))
          .toList(),
      orders: rawOrders
          .map((o) => Order.fromMap(o as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toMap());
  }

  factory BackupData.fromJsonString(String jsonStr) {
    final decoded = json.decode(jsonStr) as Map<String, dynamic>;
    return BackupData.fromMap(decoded);
  }
}

class BackupRestoreService {
  static const String prefKeyBackupJson = 'restpos_persisted_backup_json';
  static const String prefKeyBackupTime = 'restpos_persisted_backup_time';
  static const String prefKeyBackupSize = 'restpos_persisted_backup_size';

  static List<String> get candidateFilePaths => const [
    '/storage/emulated/0/Download/RestPos/restpos_backup.json',
    '/storage/emulated/0/Android/data/com.restaurantpos.flutter_restaurant_pos/files/restpos_backup.json',
    '/data/user/0/com.restaurantpos.flutter_restaurant_pos/files/restpos_backup.json',
    '/data/user/0/com.restaurantpos.flutter_restaurant_pos/cache/RestPos/restpos_backup.json',
    '/storage/emulated/0/RestPos/restpos_backup.json',
    '/storage/emulated/0/Documents/RestPos/restpos_backup.json',
    '/storage/emulated/0/Download/spice_garden_pos_backup.json',
  ];

  /// Base directory for permanent backups in RestPos folder
  /// Preserved even if the app is uninstalled/reinstalled
  static Future<Directory> getBackupDirectory() async {
    // 1. Try public shared Download/RestPos
    final downloadRestPos = Directory('/storage/emulated/0/Download/RestPos');
    try {
      if (!downloadRestPos.existsSync()) {
        downloadRestPos.createSync(recursive: true);
      }
      return downloadRestPos;
    } catch (_) {}

    // 2. Try root storage RestPos (/storage/emulated/0/RestPos)
    final rootRestPos = Directory('/storage/emulated/0/RestPos');
    try {
      if (!rootRestPos.existsSync()) {
        rootRestPos.createSync(recursive: true);
      }
      return rootRestPos;
    } catch (_) {}

    // 3. Fallback to Documents/RestPos
    final docRestPos = Directory('/storage/emulated/0/Documents/RestPos');
    try {
      if (!docRestPos.existsSync()) {
        docRestPos.createSync(recursive: true);
      }
      return docRestPos;
    } catch (_) {}

    // 4. Fallback to app cache dir
    final fallback = Directory('/data/user/0/com.restaurantpos.flutter_restaurant_pos/cache/RestPos');
    if (!fallback.existsSync()) {
      fallback.createSync(recursive: true);
    }
    return fallback;
  }

  /// Backup file path: RestPos/restpos_backup.json (always overwrites previous)
  static Future<String> getBackupFilePath() async {
    final dir = await getBackupDirectory();
    return '${dir.path}/restpos_backup.json';
  }

  /// Exports current database state across all storage tiers, overwriting previous backup
  static Future<File> exportBackup({
    required RestaurantProfile profile,
    required List<MenuCategory> categories,
    required List<MenuItem> items,
    required List<RestaurantTable> tables,
    required List<Order> orders,
  }) async {
    final backup = BackupData(
      version: 1,
      exportedAt: DateTime.now().toIso8601String(),
      profile: profile,
      categories: categories,
      items: items,
      tables: tables,
      orders: orders,
    );

    final jsonStr = backup.toJsonString();
    final byteLength = utf8.encode(jsonStr).length;

    // Tier 1: Persist backup mirror to SharedPreferences (guaranteed immunity to storage permissions)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKeyBackupJson, jsonStr);
      await prefs.setString(prefKeyBackupTime, backup.exportedAt);
      await prefs.setInt(prefKeyBackupSize, byteLength);
    } catch (_) {}

    // Tier 2: Write to App-specific internal & external file paths
    try {
      final internalDir = Directory('/data/user/0/com.restaurantpos.flutter_restaurant_pos/files');
      if (!internalDir.existsSync()) internalDir.createSync(recursive: true);
      final internalFile = File('${internalDir.path}/restpos_backup.json');
      await internalFile.writeAsString(jsonStr, mode: FileMode.write, flush: true);
    } catch (_) {}

    try {
      final cacheDir = Directory('/data/user/0/com.restaurantpos.flutter_restaurant_pos/cache/RestPos');
      if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
      final cacheFile = File('${cacheDir.path}/restpos_backup.json');
      await cacheFile.writeAsString(jsonStr, mode: FileMode.write, flush: true);
    } catch (_) {}

    try {
      final extFilesDir = Directory('/storage/emulated/0/Android/data/com.restaurantpos.flutter_restaurant_pos/files');
      if (!extFilesDir.existsSync()) extFilesDir.createSync(recursive: true);
      final extFile = File('${extFilesDir.path}/restpos_backup.json');
      await extFile.writeAsString(jsonStr, mode: FileMode.write, flush: true);
    } catch (_) {}

    // Tier 3: Save via Native Android MediaStore (Scoped Storage compliant for Download/RestPos)
    try {
      final nativePath = await NativeApiChannel.saveBackupToRestPos(jsonStr);
      if (nativePath != null && nativePath.isNotEmpty) {
        final f = File(nativePath);
        if (f.existsSync()) return f;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Native saveBackupToRestPos fallback triggered: $e');
    }

    // Tier 4: Direct File write fallback
    try {
      final path = await getBackupFilePath();
      final file = File(path);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      await file.writeAsString(jsonStr, mode: FileMode.write, flush: true);
      return file;
    } catch (_) {}

    return File('/data/user/0/com.restaurantpos.flutter_restaurant_pos/files/restpos_backup.json');
  }

  /// Checks if a backup file exists in any of the candidate file locations
  static Future<File?> findExistingBackupFile() async {
    for (final path in candidateFilePaths) {
      try {
        final f = File(path);
        if (f.existsSync() && f.lengthSync() > 0) {
          return f;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Checks if a backup file exists on device or in persistent mirror
  static Future<bool> hasExistingBackup() async {
    // 1. Native MediaStore / Native File read
    try {
      final nativeContent = await NativeApiChannel.readBackupFromRestPos();
      if (nativeContent != null && nativeContent.trim().isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // 2. Direct File candidates
    final file = await findExistingBackupFile();
    if (file != null) return true;

    // 3. SharedPreferences mirror
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefJson = prefs.getString(prefKeyBackupJson);
      if (prefJson != null && prefJson.trim().isNotEmpty) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Imports and parses backup data from Native, Filesystem, or SharedPreferences mirror
  static Future<BackupData?> importBackup() async {
    // 1. Primary: Read via Native Android MediaStore & native storage
    try {
      final nativeContent = await NativeApiChannel.readBackupFromRestPos();
      if (nativeContent != null && nativeContent.trim().isNotEmpty) {
        return BackupData.fromJsonString(nativeContent);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Native readBackupFromRestPos fallback triggered: $e');
    }

    // 2. Fallback to direct file read
    final file = await findExistingBackupFile();
    if (file != null && file.existsSync()) {
      try {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          return BackupData.fromJsonString(content);
        }
      } catch (_) {}
    }

    // 3. Fallback to SharedPreferences mirror
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefJson = prefs.getString(prefKeyBackupJson);
      if (prefJson != null && prefJson.trim().isNotEmpty) {
        return BackupData.fromJsonString(prefJson);
      }
    } catch (_) {}

    return null;
  }

  /// Inspects and retrieves detailed metadata (file size, timestamp, counts) of the existing backup
  static Future<BackupFileInfo?> getExistingBackupInfo() async {
    String? content;
    int size = 0;

    // 1. Try reading via NativeApiChannel
    try {
      content = await NativeApiChannel.readBackupFromRestPos();
      if (content != null && content.trim().isNotEmpty) {
        size = utf8.encode(content).length;
      }
    } catch (_) {}

    // 2. Direct file fallback if content is null
    if (content == null || content.trim().isEmpty) {
      final file = await findExistingBackupFile();
      if (file != null && file.existsSync()) {
        try {
          content = await file.readAsString();
          size = file.lengthSync();
        } catch (_) {}
      }
    }

    // 3. SharedPreferences mirror fallback if content is null
    if (content == null || content.trim().isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final prefJson = prefs.getString(prefKeyBackupJson);
        if (prefJson != null && prefJson.trim().isNotEmpty) {
          content = prefJson;
          size = prefs.getInt(prefKeyBackupSize) ?? utf8.encode(prefJson).length;
        }
      } catch (_) {}
    }

    if (content == null || content.trim().isEmpty) return null;

    try {
      final data = BackupData.fromJsonString(content);
      String formattedDate = data.exportedAt;
      try {
        final dt = DateTime.parse(data.exportedAt).toLocal();
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthStr = months[dt.month - 1];
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        formattedDate = '${dt.day} $monthStr ${dt.year}, $hour:$minute $ampm';
      } catch (_) {}

      final kb = size / 1024.0;
      final sizeStr = kb >= 1024
          ? '${(kb / 1024.0).toStringAsFixed(2)} MB'
          : '${kb.toStringAsFixed(1)} KB';

      return BackupFileInfo(
        fileSizeBytes: size,
        formattedSize: sizeStr,
        exportedAt: data.exportedAt,
        formattedDate: formattedDate,
        dishCount: data.items.length,
        categoryCount: data.categories.length,
        tableCount: data.tables.length,
        orderCount: data.orders.length,
        restaurantName: data.profile.name,
        data: data,
      );
    } catch (_) {
      return null;
    }
  }
}

class BackupFileInfo {
  final int fileSizeBytes;
  final String formattedSize;
  final String exportedAt;
  final String formattedDate;
  final int dishCount;
  final int categoryCount;
  final int tableCount;
  final int orderCount;
  final String restaurantName;
  final BackupData data;

  const BackupFileInfo({
    required this.fileSizeBytes,
    required this.formattedSize,
    required this.exportedAt,
    required this.formattedDate,
    required this.dishCount,
    required this.categoryCount,
    required this.tableCount,
    required this.orderCount,
    required this.restaurantName,
    required this.data,
  });
}
