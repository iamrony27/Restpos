import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import '../models/restaurant_profile.dart';
import '../models/table_model.dart';

class LocalStorageService {
  static const String _keyOrders = 'pos_saved_orders';
  static const String _keyTables = 'pos_saved_tables';
  static const String _keyMenuItems = 'pos_saved_menu_items';
  static const String _keyMenuCategories = 'pos_saved_menu_categories';
  static const String _keyProfile = 'restaurant_profile';

  // --- Orders Persistence ---
  static Future<void> saveOrders(List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = orders.map((o) => o.toMap()).toList();
      await prefs.setString(_keyOrders, jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<List<Order>?> loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyOrders);
      if (str == null || str.isEmpty) return null;
      final List<dynamic> decoded = jsonDecode(str) as List<dynamic>;
      return decoded.map((m) => Order.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOrders);
    } catch (_) {}
  }

  // --- Tables Persistence ---
  static Future<void> saveTables(List<RestaurantTable> tables) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tables.map((t) => t.toMap()).toList();
      await prefs.setString(_keyTables, jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<List<RestaurantTable>?> loadTables() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyTables);
      if (str == null || str.isEmpty) return null;
      final List<dynamic> decoded = jsonDecode(str) as List<dynamic>;
      return decoded.map((m) => RestaurantTable.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- Menu Items & Categories Persistence ---
  static Future<void> saveMenuItems(List<MenuItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((i) => i.toMap()).toList();
      await prefs.setString(_keyMenuItems, jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<List<MenuItem>?> loadMenuItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyMenuItems);
      if (str == null || str.isEmpty) return null;
      final List<dynamic> decoded = jsonDecode(str) as List<dynamic>;
      return decoded.map((m) => MenuItem.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveMenuCategories(List<MenuCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = categories.map((c) => c.toMap()).toList();
      await prefs.setString(_keyMenuCategories, jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<List<MenuCategory>?> loadMenuCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyMenuCategories);
      if (str == null || str.isEmpty) return null;
      final List<dynamic> decoded = jsonDecode(str) as List<dynamic>;
      return decoded.map((m) => MenuCategory.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // --- Restaurant Profile Persistence ---
  static Future<void> saveProfile(RestaurantProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyProfile, jsonEncode(profile.toMap()));
    } catch (_) {}
  }

  static Future<RestaurantProfile?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyProfile);
      if (str == null || str.isEmpty) return null;
      final Map<String, dynamic> decoded = jsonDecode(str) as Map<String, dynamic>;
      return RestaurantProfile.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }
}
