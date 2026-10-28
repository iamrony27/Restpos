class MenuCategory {
  final int id;
  final String name;
  final String icon;
  final String colorHex;
  final int sortOrder;

  const MenuCategory({
    required this.id,
    required this.name,
    this.icon = 'restaurant',
    this.colorHex = '#E0533C',
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color_hex': colorHex,
      'sort_order': sortOrder,
    };
  }

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    return MenuCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      icon: (map['icon'] as String?) ?? 'restaurant',
      colorHex: (map['color_hex'] as String?) ?? '#E0533C',
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}
