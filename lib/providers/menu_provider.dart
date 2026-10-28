import 'package:flutter/foundation.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';

class MenuProvider extends ChangeNotifier {
  final List<MenuCategory> _categories = [
    const MenuCategory(id: 1, name: 'Beverages', icon: 'local_cafe_rounded', colorHex: '#0284C7', sortOrder: 1),
    const MenuCategory(id: 2, name: 'Appetizers', icon: 'tapas_rounded', colorHex: '#D97706', sortOrder: 2),
    const MenuCategory(id: 3, name: 'Main Course', icon: 'dinner_dining_rounded', colorHex: '#C0392B', sortOrder: 3),
    const MenuCategory(id: 4, name: 'Breads & Rice', icon: 'bakery_dining_rounded', colorHex: '#854D0E', sortOrder: 4),
    const MenuCategory(id: 5, name: 'Desserts', icon: 'icecream_rounded', colorHex: '#9333EA', sortOrder: 5),
  ];

  final List<MenuItem> _items = [
    // Beverages
    const MenuItem(id: 101, categoryId: 1, name: 'Masala Chai', pricePaise: 4000, dietaryType: DietaryType.veg, sku: 'BEV-001'),
    const MenuItem(id: 102, categoryId: 1, name: 'Filter Coffee', pricePaise: 6000, dietaryType: DietaryType.veg, sku: 'BEV-002'),
    const MenuItem(id: 103, categoryId: 1, name: 'Sweet Mango Lassi', pricePaise: 9000, dietaryType: DietaryType.veg, sku: 'BEV-003'),
    const MenuItem(id: 104, categoryId: 1, name: 'Fresh Lime Soda', pricePaise: 5000, dietaryType: DietaryType.veg, sku: 'BEV-004'),

    // Appetizers
    const MenuItem(id: 201, categoryId: 2, name: 'Paneer Tikka (6 pcs)', pricePaise: 24000, dietaryType: DietaryType.veg, sku: 'APP-001'),
    const MenuItem(id: 202, categoryId: 2, name: 'Crispy Veg Spring Rolls', pricePaise: 18000, dietaryType: DietaryType.veg, sku: 'APP-002'),
    const MenuItem(id: 203, categoryId: 2, name: 'Chicken 65', pricePaise: 28000, dietaryType: DietaryType.nonVeg, sku: 'APP-003'),
    const MenuItem(id: 204, categoryId: 2, name: 'Tandoori Chicken (Half)', pricePaise: 32000, dietaryType: DietaryType.nonVeg, sku: 'APP-004'),
    const MenuItem(id: 205, categoryId: 2, name: 'Egg Pakora (4 pcs)', pricePaise: 16000, dietaryType: DietaryType.egg, sku: 'APP-005'),

    // Main Course
    const MenuItem(id: 301, categoryId: 3, name: 'Paneer Butter Masala', pricePaise: 31000, dietaryType: DietaryType.veg, sku: 'MAIN-001'),
    const MenuItem(id: 302, categoryId: 3, name: 'Dal Makhani Special', pricePaise: 26000, dietaryType: DietaryType.veg, sku: 'MAIN-002'),
    const MenuItem(id: 303, categoryId: 3, name: 'Butter Chicken Handi', pricePaise: 38000, dietaryType: DietaryType.nonVeg, sku: 'MAIN-003'),
    const MenuItem(id: 304, categoryId: 3, name: 'Mutton Rogan Josh', pricePaise: 46000, dietaryType: DietaryType.nonVeg, sku: 'MAIN-004'),
    const MenuItem(id: 305, categoryId: 3, name: 'Egg Curry (2 Eggs)', pricePaise: 22000, dietaryType: DietaryType.egg, sku: 'MAIN-005'),

    // Breads & Rice
    const MenuItem(id: 401, categoryId: 4, name: 'Butter Naan', pricePaise: 5500, dietaryType: DietaryType.veg, sku: 'RICE-001'),
    const MenuItem(id: 402, categoryId: 4, name: 'Garlic Naan', pricePaise: 6500, dietaryType: DietaryType.veg, sku: 'RICE-002'),
    const MenuItem(id: 403, categoryId: 4, name: 'Jeera Rice', pricePaise: 15000, dietaryType: DietaryType.veg, sku: 'RICE-003'),
    const MenuItem(id: 404, categoryId: 4, name: 'Chicken Dum Biryani', pricePaise: 34000, dietaryType: DietaryType.nonVeg, sku: 'RICE-004'),

    // Desserts
    const MenuItem(id: 501, categoryId: 5, name: 'Gulab Jamun (2 pcs)', pricePaise: 8000, dietaryType: DietaryType.veg, sku: 'DES-001'),
    const MenuItem(id: 502, categoryId: 5, name: 'Rasmalai (2 pcs)', pricePaise: 11000, dietaryType: DietaryType.veg, sku: 'DES-002'),
    const MenuItem(id: 503, categoryId: 5, name: 'Sizzling Brownie with Ice Cream', pricePaise: 18000, dietaryType: DietaryType.egg, sku: 'DES-003'),
  ];

  List<MenuCategory> get categories => List.unmodifiable(_categories);
  List<MenuItem> get items => List.unmodifiable(_items);

  List<MenuItem> getFilteredItems({int categoryId = 0, String query = ''}) {
    return _items.where((item) {
      if (categoryId != 0 && item.categoryId != categoryId) return false;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesSku = item.sku?.toLowerCase().contains(q) ?? false;
        if (!matchesName && !matchesSku) return false;
      }
      return true;
    }).toList();
  }

  void toggleItemAvailability(int itemId) {
    final index = _items.indexWhere((it) => it.id == itemId);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(isAvailable: !current.isAvailable);
      notifyListeners();
    }
  }

  void addItem(MenuItem item) {
    _items.add(item);
    notifyListeners();
  }

  void updateItem(MenuItem item) {
    final index = _items.indexWhere((it) => it.id == item.id);
    if (index >= 0) {
      _items[index] = item;
      notifyListeners();
    }
  }
}
