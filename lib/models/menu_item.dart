enum DietaryType { veg, nonVeg, egg }

class MenuItem {
  final int id;
  final int categoryId;
  final String name;
  final int pricePaise; // Price in minor units (paise: ₹1.00 = 100 paise)
  final DietaryType dietaryType;
  final bool isAvailable;
  final String? description;
  final String? sku;
  final String? imageUri;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.pricePaise,
    this.dietaryType = DietaryType.veg,
    this.isAvailable = true,
    this.description,
    this.sku,
    this.imageUri,
  });

  double get priceRupees => pricePaise / 100.0;

  String get formattedPrice => '₹${priceRupees.toStringAsFixed(priceRupees.truncateToDouble() == priceRupees ? 0 : 2)}';

  MenuItem copyWith({
    int? id,
    int? categoryId,
    String? name,
    int? pricePaise,
    DietaryType? dietaryType,
    bool? isAvailable,
    String? description,
    String? sku,
    String? imageUri,
  }) {
    return MenuItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      pricePaise: pricePaise ?? this.pricePaise,
      dietaryType: dietaryType ?? this.dietaryType,
      isAvailable: isAvailable ?? this.isAvailable,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      imageUri: imageUri ?? this.imageUri,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'price': pricePaise,
      'dietary_type': dietaryType.name,
      'is_available': isAvailable ? 1 : 0,
      'description': description,
      'sku': sku,
      'image_uri': imageUri,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    DietaryType dType = DietaryType.veg;
    final dName = map['dietary_type'] as String?;
    if (dName == 'nonVeg') {
      dType = DietaryType.nonVeg;
    } else if (dName == 'egg') {
      dType = DietaryType.egg;
    } else if (map['is_veg'] != null && (map['is_veg'] as int) == 0) {
      dType = DietaryType.nonVeg;
    }

    return MenuItem(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      pricePaise: (map['price'] as int?) ?? 0,
      dietaryType: dType,
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
      description: map['description'] as String?,
      sku: map['sku'] as String?,
      imageUri: map['image_uri'] as String?,
    );
  }
}
