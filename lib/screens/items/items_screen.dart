import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../core/utils/app_notification.dart';
import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/dietary_badge.dart';

Widget _buildDishImage(
  String? uri, {
  required double height,
  double width = double.infinity,
  BoxFit fit = BoxFit.cover,
  double? cacheWidth,
}) {
  Widget placeholder(IconData icon) {
    return Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF231B17),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C221D),
            Color(0xFF1B1513),
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, color: CulinaryColors.flameOrange.withOpacity(0.65), size: 28),
      ),
    );
  }

  if (uri == null || uri.isEmpty) {
    return placeholder(Icons.restaurant_rounded);
  }

  Widget img;
  if (uri.startsWith('/') || uri.startsWith('file://')) {
    final filePath = uri.replaceFirst('file://', '');
    img = Image.file(
      File(filePath),
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder(Icons.broken_image_rounded),
    );
  } else if (uri.startsWith('http://') || uri.startsWith('https://')) {
    img = Image.network(
      uri,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder(Icons.broken_image_rounded),
    );
  } else {
    img = Image.asset(
      uri,
      height: height,
      width: width,
      fit: fit,
      cacheWidth: cacheWidth?.toInt() ?? 360,
      errorBuilder: (_, __, ___) => placeholder(Icons.restaurant_rounded),
    );
  }

  return Container(
    height: height,
    width: width,
    decoration: const BoxDecoration(
      color: Color(0xFF231B17),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2C221D),
          Color(0xFF1B1513),
        ],
      ),
    ),
    child: img,
  );
}



class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryId = 0; // 0 = All
  DietaryType? _dietaryFilter;
  bool _showOnlyOutOfStock = false;
  bool _isGridView = false;

  final List<String> _presetPhotos = [
    'assets/menu/beverages/masala-chai.webp',
    'assets/menu/beverages/filter-coffee.webp',
    'assets/menu/beverages/mango-lassi.webp',
    'assets/menu/beverages/cold-coffee.webp',
    'assets/menu/beverages/fresh-lime-soda.webp',
    'assets/menu/starters/paneer-tikka.webp',
    'assets/menu/starters/chicken-65.webp',
    'assets/menu/starters/tandoori-chicken.webp',
    'assets/menu/starters/veg-spring-rolls.webp',
    'assets/menu/starters/chicken-lollipop.webp',
    'assets/menu/vegetarian/paneer-butter-masala.webp',
    'assets/menu/vegetarian/dal-makhani.webp',
    'assets/menu/vegetarian/palak-paneer.webp',
    'assets/menu/chicken/butter-chicken.webp',
    'assets/menu/chicken/chicken-curry.webp',
    'assets/menu/chicken/chicken-tikka-masala.webp',
    'assets/menu/mutton/mutton-rogan-josh.webp',
    'assets/menu/biryani/chicken-biryani.webp',
    'assets/menu/biryani/veg-biryani.webp',
    'assets/menu/indian-bread/butter-naan.webp',
    'assets/menu/indian-bread/garlic-naan.webp',
    'assets/menu/rice/jeera-rice.webp',
    'assets/menu/desserts/gulab-jamun.webp',
    'assets/menu/desserts/rasmalai.webp',
    'assets/menu/desserts/chocolate-brownie.webp',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDishDialog(BuildContext context, [MenuItem? existingItem]) {
    NativeApiChannel.triggerNativeHaptic();
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final isEditing = existingItem != null;

    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final priceController = TextEditingController(
      text: existingItem != null ? (existingItem.pricePaise / 100).toStringAsFixed(0) : '',
    );
    final skuController = TextEditingController(text: existingItem?.sku ?? '');
    final customUrlController = TextEditingController(
      text: (existingItem?.imageUri != null && !_presetPhotos.contains(existingItem!.imageUri))
          ? existingItem.imageUri
          : '',
    );

    int selectedCategoryId = existingItem?.categoryId ??
        (menuProvider.categories.isNotEmpty ? menuProvider.categories.first.id : 1);
    DietaryType selectedDietaryType = existingItem?.dietaryType ?? DietaryType.veg;
    bool isTopSelling = existingItem?.isTopSelling ?? false;
    bool isAvailable = existingItem?.isAvailable ?? true;
    String? selectedImageUri = existingItem?.imageUri ?? _presetPhotos.first;
    bool isCustomUrlMode = customUrlController.text.isNotEmpty;

    showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Dish' : 'Add New Dish',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(ctx).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Preview and Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Item Photo',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                                    label: const Text('From Phone', style: TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      final picked = await NativeApiChannel.pickImageFromDevice();
                                      if (picked != null) {
                                        setDlgState(() {
                                          selectedImageUri = picked;
                                          customUrlController.text = picked;
                                          isCustomUrlMode = true;
                                        });
                                      }
                                    },
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    icon: Icon(
                                      isCustomUrlMode ? Icons.photo_library_rounded : Icons.link_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      isCustomUrlMode ? 'Presets' : 'Link',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () {
                                      setDlgState(() => isCustomUrlMode = !isCustomUrlMode);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isCustomUrlMode) ...[
                        TextField(
                          controller: customUrlController,
                          decoration: InputDecoration(
                            labelText: 'Image Asset or URL',
                            hintText: 'e.g. assets/menu/... or https://...',
                            prefixIcon: const Icon(Icons.image_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            setDlgState(() {
                              selectedImageUri = val.trim().isNotEmpty ? val.trim() : null;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        Container(
                          height: 84,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                          ),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presetPhotos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final photoPath = _presetPhotos[idx];
                              final isSelected = selectedImageUri == photoPath;
                              return GestureDetector(
                                onTap: () {
                                  setDlgState(() {
                                    selectedImageUri = photoPath;
                                  });
                                },
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        photoPath,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 76,
                                          height: 76,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.fastfood_rounded, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: theme.colorScheme.primary, width: 3),
                                            borderRadius: BorderRadius.circular(8),
                                            color: theme.colorScheme.primary.withOpacity(0.25),
                                          ),
                                          child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Dish Name *',
                          hintText: 'e.g. Paneer Butter Masala',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price (₹) *',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: skuController,
                              decoration: InputDecoration(
                                labelText: 'SKU / Code',
                                hintText: 'e.g. MAIN-010',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: menuProvider.categories.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => selectedCategoryId = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text('Dietary Type:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      SegmentedButton<DietaryType>(
                        segments: const [
                          ButtonSegment(value: DietaryType.veg, label: Text('Veg')),
                          ButtonSegment(value: DietaryType.nonVeg, label: Text('Non-Veg')),
                          ButtonSegment(value: DietaryType.egg, label: Text('Egg')),
                        ],
                        selected: {selectedDietaryType},
                        onSelectionChanged: (set) => setDlgState(() => selectedDietaryType = set.first),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Top Selling / Bestseller', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Highlight dish with gold star badge', style: TextStyle(fontSize: 12)),
                        value: isTopSelling,
                        onChanged: (val) => setDlgState(() => isTopSelling = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available (Active)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          isAvailable ? 'In stock and orderable' : 'Marked out of stock / deactivated',
                          style: TextStyle(fontSize: 12, color: isAvailable ? Colors.green : Colors.red),
                        ),
                        value: isAvailable,
                        onChanged: (val) => setDlgState(() => isAvailable = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CulinaryColors.flameOrange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceNum = double.tryParse(priceController.text.trim()) ?? 0;
                    if (name.isEmpty || priceNum <= 0) {
                      AppNotification.showError(
                        context,
                        'Please enter a valid dish name and price',
                        title: 'Validation Error',
                      );
                      return;
                    }

                    final finalImageUri = isCustomUrlMode && customUrlController.text.trim().isNotEmpty
                        ? customUrlController.text.trim()
                        : selectedImageUri;

                    final newItem = MenuItem(
                      id: existingItem?.id ?? DateTime.now().millisecondsSinceEpoch % 100000,
                      categoryId: selectedCategoryId,
                      name: name,
                      pricePaise: (priceNum * 100).round(),
                      dietaryType: selectedDietaryType,
                      sku: skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                      imageUri: finalImageUri,
                      isTopSelling: isTopSelling,
                      isAvailable: isAvailable,
                      salesCount: existingItem?.salesCount ?? 0,
                    );

                    if (isEditing) {
                      menuProvider.updateItem(newItem);
                    } else {
                      menuProvider.addItem(newItem);
                    }

                    Navigator.pop(dlgContext);
                    AppNotification.showSuccess(
                      context,
                      isEditing ? 'Updated ${newItem.name}' : 'Added ${newItem.name}',
                      title: isEditing ? 'Dish Updated' : 'Dish Added',
                    );
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Dish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDish(BuildContext context, MenuItem item) {
    NativeApiChannel.triggerNativeHaptic();
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Dish?'),
        content: Text('Are you sure you want to permanently remove "${item.name}" from your menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              menuProvider.deleteItem(item.id);
              Navigator.pop(ctx);
              AppNotification.showSuccess(
                context,
                'Deleted ${item.name}',
                title: 'Dish Deleted',
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuProvider = Provider.of<MenuProvider>(context);

    // Filter items based on category, search, dietary, out of stock filter
    var items = menuProvider.items.where((item) {
      if (_selectedCategoryId != 0 && item.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_dietaryFilter != null && item.dietaryType != _dietaryFilter) {
        return false;
      }
      if (_showOnlyOutOfStock && item.isAvailable) {
        return false;
      }
      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.trim().toLowerCase();
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesSku = item.sku?.toLowerCase().contains(q) ?? false;
        if (!matchesName && !matchesSku) return false;
      }
      return true;
    }).toList();

    // Sort: Available first sorted by salesCount desc; Out of stock at bottom
    items.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return b.salesCount.compareTo(a.salesCount);
    });

    final activeCount = menuProvider.items.where((i) => i.isAvailable).length;
    final outOfStockCount = menuProvider.items.length - activeCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Management',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${menuProvider.items.length} dishes • $activeCount active • $outOfStockCount out of stock',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: CulinaryColors.flameOrange,
            ),
            onPressed: () {
              NativeApiChannel.triggerNativeHaptic();
              setState(() => _isGridView = !_isGridView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: CulinaryColors.flameOrange, size: 28),
            tooltip: 'Add New Dish',
            onPressed: () => _showAddEditDishDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: SizedBox(
              height: 46,
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search dishes, code, SKU...',
                hintStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                ),
                textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13)),
                leading: const Icon(Icons.search_rounded, size: 20),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                ],
                onChanged: (_) => setState(() {}),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerLow),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Categories & Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategoryId == 0,
                  onSelected: (_) => setState(() => _selectedCategoryId = 0),
                ),
                const SizedBox(width: 8),
                ...menuProvider.categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: _selectedCategoryId == cat.id,
                      onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                    ),
                  );
                }),
                const VerticalDivider(width: 16),
                FilterChip(
                  avatar: const DietaryBadge(type: DietaryType.veg, size: 10),
                  label: const Text('Veg'),
                  selected: _dietaryFilter == DietaryType.veg,
                  onSelected: (sel) => setState(() => _dietaryFilter = sel ? DietaryType.veg : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const DietaryBadge(type: DietaryType.nonVeg, size: 10),
                  label: const Text('Non-Veg'),
                  selected: _dietaryFilter == DietaryType.nonVeg,
                  onSelected: (sel) => setState(() => _dietaryFilter = sel ? DietaryType.nonVeg : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                  label: Text('Out of Stock ($outOfStockCount)'),
                  selected: _showOnlyOutOfStock,
                  onSelected: (sel) => setState(() => _showOnlyOutOfStock = sel),
                ),
              ],
            ),
          ),

          const Divider(height: 12),

          // Dishes Grid or List View with Quick Controls
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('No dishes found', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDishDialog(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add New Dish'),
                        ),
                      ],
                    ),
                  )
                : _isGridView
                    ? GridView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        cacheExtent: 600,
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 90),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.92,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return RepaintBoundary(
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: item.isAvailable
                                      ? theme.colorScheme.outlineVariant.withOpacity(0.5)
                                      : Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              color: !item.isAvailable
                                  ? theme.colorScheme.surfaceContainerHigh.withOpacity(0.55)
                                  : theme.colorScheme.surface,
                              child: InkWell(
                                onTap: () => _showAddEditDishDialog(context, item),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        _buildDishImage(
                                          item.imageUri,
                                          height: 110,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          cacheWidth: 320,
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: DietaryBadge(type: item.dietaryType, size: 12),
                                          ),
                                        ),
                                        if (item.isTopSelling)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Best',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (!item.isAvailable)
                                          Positioned.fill(
                                            child: Container(
                                              color: Colors.black.withOpacity(0.55),
                                              alignment: Alignment.center,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade800,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'OUT OF STOCK',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item.formattedPrice,
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: item.isAvailable ? CulinaryColors.flameOrange : Colors.grey,
                                                ),
                                              ),
                                              Switch(
                                                value: item.isAvailable,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                activeColor: CulinaryColors.emeraldGreen,
                                                onChanged: (val) {
                                                  NativeApiChannel.triggerNativeHaptic();
                                                  menuProvider.setItemAvailability(item.id, val);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        cacheExtent: 600,
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return RepaintBoundary(
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: item.isAvailable
                                    ? theme.colorScheme.surface
                                    : theme.colorScheme.surfaceContainerHigh.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: item.isAvailable
                                      ? theme.colorScheme.outlineVariant.withOpacity(0.4)
                                      : Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showAddEditDishDialog(context, item),
                                child: SizedBox(
                                  height: 106,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Thumbnail with Dietary Badge - Flush left/top/bottom, no margin
                                      SizedBox(
                                        width: 106,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              _buildDishImage(
                                                item.imageUri,
                                                width: 106,
                                                height: 106,
                                                fit: BoxFit.cover,
                                                cacheWidth: 260,
                                              ),
                                              Positioned(
                                                top: 6,
                                                left: 6,
                                              child: Container(
                                                padding: const EdgeInsets.all(2.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: DietaryBadge(type: item.dietaryType, size: 10),
                                              ),
                                            ),
                                            if (item.isTopSelling)
                                              Positioned(
                                                bottom: 6,
                                                left: 6,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF59E0B),
                                                    borderRadius: BorderRadius.circular(5),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.35),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.star_rounded, color: Colors.white, size: 10),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        'Bestseller',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            if (!item.isAvailable)
                                              Positioned.fill(
                                                child: Container(
                                                  color: Colors.black.withOpacity(0.55),
                                                  alignment: Alignment.center,
                                                  child: const Icon(Icons.block_rounded, color: Colors.white, size: 26),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                      // Dish Info
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Full width prominent Dish Name
                                              Text(
                                                item.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14.5,
                                                  decoration: item.isAvailable ? null : TextDecoration.lineThrough,
                                                ),
                                              ),
                                              const SizedBox(height: 3),

                                              // Price & Sold item quantity badge
                                              Row(
                                                children: [
                                                  Text(
                                                    item.formattedPrice,
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 14,
                                                      color: item.isAvailable ? CulinaryColors.flameOrange : Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.trending_up_rounded,
                                                          size: 11.5,
                                                          color: CulinaryColors.flameOrange,
                                                        ),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          '${item.salesCount} sold',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            color: theme.colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),

                                              // SKU & Stock Status
                                              Row(
                                                children: [
                                                  if (item.sku != null && item.sku!.isNotEmpty) ...[
                                                    Text(
                                                      item.sku!,
                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                        color: theme.colorScheme.outline,
                                                        fontSize: 10.5,
                                                      ),
                                                    ),
                                                    Text(
                                                      ' • ',
                                                      style: TextStyle(
                                                        color: theme.colorScheme.outline,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                  Text(
                                                    item.isAvailable ? 'In Stock' : 'Out of Stock',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: item.isAvailable ? Colors.green : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),



                                // Quick Stock Toggle Switch
                                Switch(
                                  value: item.isAvailable,
                                  activeColor: CulinaryColors.emeraldGreen,
                                  onChanged: (val) {
                                    NativeApiChannel.triggerNativeHaptic();
                                    menuProvider.setItemAvailability(item.id, val);
                                  },
                                ),

                                // Actions Menu
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showAddEditDishDialog(context, item);
                                    } else if (val == 'toggle') {
                                      menuProvider.toggleItemAvailability(item.id);
                                    } else if (val == 'delete') {
                                      _confirmDeleteDish(context, item);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.isAvailable ? Icons.block_rounded : Icons.check_circle_rounded,
                                            color: item.isAvailable ? Colors.orange : Colors.green,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(item.isAvailable ? 'Deactivate' : 'Activate'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit Dish'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text('Delete Dish', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
