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
    const MenuItem(
      id: 101,
      categoryId: 1,
      name: 'Masala Chai',
      pricePaise: 4000,
      dietaryType: DietaryType.veg,
      sku: 'BEV-001',
      imageUri: 'assets/menu/beverages/masala-chai.webp',
      isTopSelling: true,
      salesCount: 142,
      description: 'Slow-brewed Assam CTC with fresh ginger, cardamom & aromatic spices.',
    ),
    const MenuItem(
      id: 102,
      categoryId: 1,
      name: 'Filter Coffee',
      pricePaise: 6000,
      dietaryType: DietaryType.veg,
      sku: 'BEV-002',
      imageUri: 'assets/menu/beverages/cold-coffee.webp',
      salesCount: 68,
      description: 'Traditional South Indian chicory decoction with frothy steamed milk.',
    ),
    const MenuItem(
      id: 103,
      categoryId: 1,
      name: 'Sweet Mango Lassi',
      pricePaise: 9000,
      dietaryType: DietaryType.veg,
      sku: 'BEV-003',
      imageUri: 'assets/menu/beverages/mango-lassi.webp',
      isTopSelling: true,
      salesCount: 95,
      description: 'Thick creamy churned yogurt blended with sweet Alphonso mango pulp.',
    ),
    const MenuItem(
      id: 104,
      categoryId: 1,
      name: 'Fresh Lime Soda',
      pricePaise: 5000,
      dietaryType: DietaryType.veg,
      sku: 'BEV-004',
      imageUri: 'assets/menu/beverages/fresh-lime-soda.webp',
      salesCount: 52,
      description: 'Crisp club soda with freshly squeezed lime, rock salt and mint.',
    ),

    // Appetizers
    const MenuItem(
      id: 201,
      categoryId: 2,
      name: 'Paneer Tikka (6 pcs)',
      pricePaise: 24000,
      dietaryType: DietaryType.veg,
      sku: 'APP-001',
      imageUri: 'assets/menu/starters/paneer-tikka.webp',
      isTopSelling: true,
      salesCount: 118,
      description: 'Char-grilled cottage cheese cubes marinated in mustard oil & Kashmiri chilli.',
    ),
    const MenuItem(
      id: 202,
      categoryId: 2,
      name: 'Crispy Veg Spring Rolls',
      pricePaise: 18000,
      dietaryType: DietaryType.veg,
      sku: 'APP-002',
      imageUri: 'assets/menu/starters/veg-spring-rolls.webp',
      salesCount: 47,
      description: 'Golden fried wrappers stuffed with wok-tossed cabbage, carrots and glass noodles.',
    ),
    const MenuItem(
      id: 203,
      categoryId: 2,
      name: 'Chicken 65',
      pricePaise: 28000,
      dietaryType: DietaryType.nonVeg,
      sku: 'APP-003',
      imageUri: 'assets/menu/starters/chicken-65.webp',
      isTopSelling: true,
      salesCount: 104,
      description: 'Deep-fried spicy chicken morsels tempered with curry leaves and green chillies.',
    ),
    const MenuItem(
      id: 204,
      categoryId: 2,
      name: 'Tandoori Chicken (Half)',
      pricePaise: 32000,
      dietaryType: DietaryType.nonVeg,
      sku: 'APP-004',
      imageUri: 'assets/menu/starters/chicken-tikka.webp',
      salesCount: 81,
      description: 'Classic clay-oven roasted chicken spiced with hung curd and garam masala.',
    ),
    const MenuItem(
      id: 205,
      categoryId: 2,
      name: 'Egg Bhurji Pav',
      pricePaise: 16000,
      dietaryType: DietaryType.egg,
      sku: 'APP-005',
      imageUri: 'assets/menu/egg/egg-bhurji.webp',
      salesCount: 39,
      description: 'Street-style spicy scrambled eggs cooked with chopped onions, tomatoes & cilantro.',
    ),

    // Main Course
    const MenuItem(
      id: 301,
      categoryId: 3,
      name: 'Paneer Butter Masala',
      pricePaise: 31000,
      dietaryType: DietaryType.veg,
      sku: 'MAIN-001',
      imageUri: 'assets/menu/vegetarian/paneer-butter-masala.webp',
      isTopSelling: true,
      salesCount: 135,
      description: 'Soft cottage cheese simmered in a velvety buttery tomato-cashew gravy.',
    ),
    const MenuItem(
      id: 302,
      categoryId: 3,
      name: 'Dal Makhani Special',
      pricePaise: 26000,
      dietaryType: DietaryType.veg,
      sku: 'MAIN-002',
      imageUri: 'assets/menu/vegetarian/dal-makhani.webp',
      salesCount: 77,
      description: 'Whole black lentils slow-cooked overnight with white butter and fresh cream.',
    ),
    const MenuItem(
      id: 303,
      categoryId: 3,
      name: 'Butter Chicken Handi',
      pricePaise: 38000,
      dietaryType: DietaryType.nonVeg,
      sku: 'MAIN-003',
      imageUri: 'assets/menu/chicken/butter-chicken.webp',
      isTopSelling: true,
      salesCount: 165,
      description: 'Tender tandoori chicken cooked in creamy fenugreek-infused makhani gravy.',
    ),
    const MenuItem(
      id: 304,
      categoryId: 3,
      name: 'Mutton Rogan Josh',
      pricePaise: 46000,
      dietaryType: DietaryType.nonVeg,
      sku: 'MAIN-004',
      imageUri: 'assets/menu/mutton/mutton-rogan-josh.webp',
      salesCount: 63,
      description: 'Kashmiri delicacy of tender braised mutton simmered with fennel and ratanjot.',
    ),
    const MenuItem(
      id: 305,
      categoryId: 3,
      name: 'Egg Curry (2 Eggs)',
      pricePaise: 22000,
      dietaryType: DietaryType.egg,
      sku: 'MAIN-005',
      imageUri: 'assets/menu/egg/egg-curry.webp',
      salesCount: 42,
      description: 'Hard-boiled eggs simmered in a spiced onion-tomato gravy with roasted spices.',
    ),

    // Breads & Rice
    const MenuItem(
      id: 401,
      categoryId: 4,
      name: 'Butter Naan',
      pricePaise: 5500,
      dietaryType: DietaryType.veg,
      sku: 'RICE-001',
      imageUri: 'assets/menu/indian-bread/butter-naan.webp',
      isTopSelling: true,
      salesCount: 189,
      description: 'Teardrop refined flour bread baked on tandoor walls, brushed with dairy butter.',
    ),
    const MenuItem(
      id: 402,
      categoryId: 4,
      name: 'Garlic Naan',
      pricePaise: 6500,
      dietaryType: DietaryType.veg,
      sku: 'RICE-002',
      imageUri: 'assets/menu/indian-bread/garlic-naan.webp',
      salesCount: 88,
      description: 'Crisp flatbread topped with minced roasted garlic and fresh coriander.',
    ),
    const MenuItem(
      id: 403,
      categoryId: 4,
      name: 'Jeera Rice',
      pricePaise: 15000,
      dietaryType: DietaryType.veg,
      sku: 'RICE-003',
      imageUri: 'assets/menu/rice/jeera-rice.webp',
      salesCount: 71,
      description: 'Long-grain aged basmati rice tempered with cumin seeds and pure desi ghee.',
    ),
    const MenuItem(
      id: 404,
      categoryId: 4,
      name: 'Chicken Dum Biryani',
      pricePaise: 34000,
      dietaryType: DietaryType.nonVeg,
      sku: 'RICE-004',
      imageUri: 'assets/menu/biryani/chicken-biryani.webp',
      isTopSelling: true,
      salesCount: 198,
      description: 'Hyderabadi fragrant dum basmati layers sealed with saffron, kewra and succulent chicken.',
    ),

    // Desserts
    const MenuItem(
      id: 501,
      categoryId: 5,
      name: 'Gulab Jamun (2 pcs)',
      pricePaise: 8000,
      dietaryType: DietaryType.veg,
      sku: 'DES-001',
      imageUri: 'assets/menu/desserts/gulab-jamun.webp',
      isTopSelling: true,
      salesCount: 110,
      description: 'Golden fried mawa dumplings soaked in cardamom-rose scented warm sugar syrup.',
    ),
    const MenuItem(
      id: 502,
      categoryId: 5,
      name: 'Rasmalai (2 pcs)',
      pricePaise: 11000,
      dietaryType: DietaryType.veg,
      sku: 'DES-002',
      imageUri: 'assets/menu/desserts/rasmalai.webp',
      salesCount: 65,
      description: 'Delicate flattened cottage cheese discs steeped in thickened saffron-pistachio rabri.',
    ),
    const MenuItem(
      id: 503,
      categoryId: 5,
      name: 'Sizzling Brownie',
      pricePaise: 18000,
      dietaryType: DietaryType.egg,
      sku: 'DES-003',
      imageUri: 'assets/menu/desserts/chocolate-brownie.webp',
      salesCount: 54,
      description: 'Warm fudge brownie served on a smoking sizzler platter with vanilla bean ice cream.',
    ),
  ];

  List<MenuCategory> get categories => List.unmodifiable(_categories);
  List<MenuItem> get items => List.unmodifiable(_items);

  List<MenuItem> get topSellingItems {
    final list = _items.where((it) => it.isTopSelling).toList();
    list.sort((a, b) => b.salesCount.compareTo(a.salesCount));
    return List.unmodifiable(list);
  }

  List<MenuItem> getFilteredItems({int categoryId = 0, String query = ''}) {
    return _items.where((item) {
      if (categoryId == -1) {
        // Special category -1 represents 'Bestsellers / Top Selling'
        if (!item.isTopSelling) return false;
      } else if (categoryId != 0 && item.categoryId != categoryId) {
        return false;
      }
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

  void deleteItem(int itemId) {
    _items.removeWhere((it) => it.id == itemId);
    notifyListeners();
  }

  void setCategories(List<MenuCategory> categories) {
    _categories.clear();
    _categories.addAll(categories);
    notifyListeners();
  }

  void addCategory(MenuCategory category) {
    _categories.add(category);
    notifyListeners();
  }

  void deleteCategory(int categoryId) {
    _categories.removeWhere((c) => c.id == categoryId);
    notifyListeners();
  }

  void setItemAvailability(int itemId, bool isAvailable) {
    final index = _items.indexWhere((it) => it.id == itemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(isAvailable: isAvailable);
      notifyListeners();
    }
  }
}
