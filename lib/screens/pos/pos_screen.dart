import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../core/utils/app_notification.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/menu_item.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/table_provider.dart';
import '../../widgets/dietary_badge.dart';
import 'payment_modal.dart';

Widget buildDishImage(
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



class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  DietaryType? _dietaryFilter;
  static bool _persistedIsGridView = false;
  static bool _prefsLoaded = false;
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = _persistedIsGridView;
    if (!_prefsLoaded) {
      _loadViewPreference();
    }
  }

  Future<void> _loadViewPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('pos_is_grid_view');
      if (saved != null) {
        _persistedIsGridView = saved;
        if (mounted) {
          setState(() => _isGridView = saved);
        }
      }
      _prefsLoaded = true;
    } catch (_) {}
  }

  void _toggleGridView() {
    NativeApiChannel.triggerNativeHaptic();
    final newValue = !_isGridView;
    setState(() {
      _isGridView = newValue;
      _persistedIsGridView = newValue;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('pos_is_grid_view', newValue);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<String> _presetPhotos = [
    'assets/menu/beverages/masala-chai.webp',
    'assets/menu/beverages/filter-coffee.webp',
    'assets/menu/beverages/mango-lassi.webp',
    'assets/menu/beverages/cold-coffee.webp',
    'assets/menu/beverages/fresh-lime-soda.webp',
    'assets/menu/starters/paneer-tikka.webp',
    'assets/menu/starters/chicken-65.webp',
    'assets/menu/starters/tandoori-chicken.webp',
    'assets/menu/starters/veg-spring-rolls.webp',
    'assets/menu/vegetarian/paneer-butter-masala.webp',
    'assets/menu/vegetarian/dal-makhani.webp',
    'assets/menu/chicken/butter-chicken.webp',
    'assets/menu/chicken/chicken-biryani.webp',
    'assets/menu/mutton/mutton-rogan-josh.webp',
    'assets/menu/indian-bread/butter-naan.webp',
    'assets/menu/rice/jeera-rice.webp',
    'assets/menu/desserts/gulab-jamun.webp',
    'assets/menu/desserts/rasmalai.webp',
    'assets/menu/desserts/chocolate-brownie.webp',
  ];

  bool _isPresetPhoto(String uri) => _presetPhotos.contains(uri);

  void _showAddEditDishDialog(BuildContext context, [MenuItem? itemToEdit]) {
    final menuProvider = context.read<MenuProvider>();
    final isEditing = itemToEdit != null;

    final nameController = TextEditingController(text: itemToEdit?.name ?? '');
    final priceController = TextEditingController(
      text: itemToEdit != null ? (itemToEdit.pricePaise / 100).toStringAsFixed(0) : '',
    );
    final skuController = TextEditingController(text: itemToEdit?.sku ?? '');

    int selectedCategoryId = itemToEdit?.categoryId ??
        (menuProvider.categories.isNotEmpty ? menuProvider.categories.first.id : 1);
    DietaryType selectedDietaryType = itemToEdit?.dietaryType ?? DietaryType.veg;
    bool isTopSelling = itemToEdit?.isTopSelling ?? false;
    bool isAvailable = itemToEdit?.isAvailable ?? true;
    String? selectedImageUri = itemToEdit?.imageUri ?? _presetPhotos.first;

    final customUrlController = TextEditingController(
      text: (itemToEdit?.imageUri != null && !_isPresetPhoto(itemToEdit!.imageUri!)) ? itemToEdit.imageUri : '',
    );
    bool isCustomUrlMode = customUrlController.text.isNotEmpty;

    const availablePhotos = _presetPhotos;

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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
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
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
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
                            itemCount: availablePhotos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final photoPath = availablePhotos[idx];
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
                      const SizedBox(height: 12),
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
                        subtitle: const Text('Highlighted with gold star badge', style: TextStyle(fontSize: 12)),
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
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceNum = double.tryParse(priceController.text.trim()) ?? 0.0;
                    if (name.isEmpty || priceNum <= 0) {
                      AppNotification.showError(
                        context,
                        'Please enter a valid dish name and price',
                        title: 'Validation Error',
                      );
                      return;
                    }

                    final pricePaise = (priceNum * 100).round();

                    final finalImageUri = isCustomUrlMode && customUrlController.text.trim().isNotEmpty
                        ? customUrlController.text.trim()
                        : selectedImageUri;

                    if (isEditing) {
                      final updated = itemToEdit.copyWith(
                        name: name,
                        pricePaise: pricePaise,
                        categoryId: selectedCategoryId,
                        dietaryType: selectedDietaryType,
                        sku: skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                        isTopSelling: isTopSelling,
                        isAvailable: isAvailable,
                        imageUri: finalImageUri,
                      );
                      menuProvider.updateItem(updated);
                    } else {
                      final nextId = menuProvider.items
                              .map((i) => i.id)
                              .fold<int>(100, (max, id) => id > max ? id : max) +
                          1;
                      final newItem = MenuItem(
                        id: nextId,
                        categoryId: selectedCategoryId,
                        name: name,
                        pricePaise: pricePaise,
                        dietaryType: selectedDietaryType,
                        sku: skuController.text.trim().isEmpty
                            ? 'DISH-$nextId'
                            : skuController.text.trim(),
                        isTopSelling: isTopSelling,
                        isAvailable: isAvailable,
                        imageUri: finalImageUri,
                      );
                      menuProvider.addItem(newItem);
                    }

                    Navigator.pop(dlgContext);
                    AppNotification.showSuccess(
                      context,
                      isEditing
                          ? 'Dish "$name" updated successfully'
                          : 'Dish "$name" added to menu',
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
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Dish'),
            ],
          ),
          content: Text('Are you sure you want to delete "${item.name}" from the menu? This cannot be undone.'),
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
                context.read<MenuProvider>().deleteItem(item.id);
                context.read<PosProvider>().removeFromCart(item.id);
                Navigator.pop(ctx);
                AppNotification.showSuccess(
                  context,
                  'Dish "${item.name}" deleted from menu',
                  title: 'Dish Deleted',
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCustomItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    DietaryType selectedDietary = DietaryType.veg;
    bool saveToMenu = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final theme = Theme.of(dialogCtx);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CulinaryColors.flameOrange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: CulinaryColors.flameOrange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Quick Custom Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Item / Dish Name',
                        hintText: 'e.g. Special Dessert, Extra Gravy',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant_menu_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Dietary Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          avatar: const DietaryBadge(type: DietaryType.veg, size: 10),
                          label: const Text('Veg'),
                          selected: selectedDietary == DietaryType.veg,
                          onSelected: (_) => setDialogState(() => selectedDietary = DietaryType.veg),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const DietaryBadge(type: DietaryType.nonVeg, size: 10),
                          label: const Text('Non-Veg'),
                          selected: selectedDietary == DietaryType.nonVeg,
                          onSelected: (_) => setDialogState(() => selectedDietary = DietaryType.nonVeg),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const DietaryBadge(type: DietaryType.egg, size: 10),
                          label: const Text('Egg'),
                          selected: selectedDietary == DietaryType.egg,
                          onSelected: (_) => setDialogState(() => selectedDietary = DietaryType.egg),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Save to menu catalog', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: const Text('Keep available for future orders', style: TextStyle(fontSize: 12)),
                      value: saveToMenu,
                      onChanged: (val) => setDialogState(() => saveToMenu = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceRupees = double.tryParse(priceController.text.trim()) ?? 0.0;
                    if (name.isEmpty) {
                      AppNotification.showError(dialogCtx, 'Please enter an item name');
                      return;
                    }
                    if (priceRupees < 0) {
                      AppNotification.showError(dialogCtx, 'Price cannot be negative');
                      return;
                    }
                    final pricePaise = (priceRupees * 100).round();
                    final customItem = MenuItem(
                      id: DateTime.now().millisecondsSinceEpoch,
                      categoryId: 0,
                      name: name,
                      pricePaise: pricePaise,
                      dietaryType: selectedDietary,
                    );
                    if (saveToMenu) {
                      context.read<MenuProvider>().addItem(customItem);
                    }
                    context.read<PosProvider>().addToCart(customItem);
                    Navigator.pop(dialogCtx);
                    AppNotification.showSuccess(
                      context,
                      'Added "$name" to cart (${CurrencyFormatter.formatPaise(pricePaise)})',
                      title: 'Item Added',
                    );
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTableSelector(BuildContext context) {
    final tableProvider = context.read<TableProvider>();
    final posProvider = context.read<PosProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Seating Table',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: tableProvider.tables.length,
                  itemBuilder: (context, index) {
                    final table = tableProvider.tables[index];
                    final isSelected = posProvider.selectedTableId == table.id;

                    return BouncingButton(
                      onPressed: () {
                        posProvider.selectTable(table.id, table.name);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              table.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${table.seatingCapacity} Seats',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posProvider = context.watch<PosProvider>();
    final menuProvider = context.watch<MenuProvider>();

    var dishes = menuProvider.getFilteredItems(
      categoryId: posProvider.selectedCategoryId,
      query: posProvider.searchQuery,
    );

    if (_dietaryFilter != null) {
      dishes = dishes.where((d) => d.dietaryType == _dietaryFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'POS Billing',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          // Grid / List Toggle
          IconButton(
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: CulinaryColors.flameOrange,
            ),
            onPressed: _toggleGridView,
          ),
          // Order Mode Switcher (Dine-In / Takeaway)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<OrderType>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(
                  value: OrderType.dineIn,
                  icon: Icon(Icons.table_restaurant_rounded, size: 16),
                  label: Text('Dine-In'),
                ),
                ButtonSegment(
                  value: OrderType.takeaway,
                  icon: Icon(Icons.takeout_dining_rounded, size: 16),
                  label: Text('Takeaway'),
                ),
              ],
              selected: {posProvider.orderType},
              onSelectionChanged: (set) {
                NativeApiChannel.triggerNativeHaptic();
                posProvider.setOrderType(set.first);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
          // Merged Search Bar & Table Selector in a Single Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Row(
              children: [
                // Expanded Search Bar
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Search dishes, code, SKU...',
                      hintStyle: WidgetStatePropertyAll(
                        TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 13),
                      ),
                      leading: const Icon(Icons.search_rounded, size: 20),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 10),
                      ),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              posProvider.setSearchQuery('');
                            },
                          ),
                      ],
                      onChanged: (val) => posProvider.setSearchQuery(val),
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
                if (posProvider.orderType == OrderType.dineIn) ...[
                  const SizedBox(width: 8),
                  // Compact Optional Table Selector Pill
                  GestureDetector(
                    onTap: () {
                      NativeApiChannel.triggerNativeHaptic();
                      _showTableSelector(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: posProvider.selectedTableName != null
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: posProvider.selectedTableName != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.table_restaurant_rounded,
                            size: 16,
                            color: posProvider.selectedTableName != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 80),
                            child: Text(
                              posProvider.selectedTableName != null
                                  ? posProvider.selectedTableName!
                                  : 'Table (Opt)',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: posProvider.selectedTableName != null
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Categories & Dietary Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // All Category
                FilterChip(
                  label: const Text('All Items'),
                  selected: posProvider.selectedCategoryId == 0,
                  onSelected: (_) => posProvider.selectCategory(0),
                ),
                const SizedBox(width: 8),
                // Bestsellers / Top Selling Quick Filter
                FilterChip(
                  avatar: const Text('⭐', style: TextStyle(fontSize: 13)),
                  label: const Text(
                    'Bestsellers',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  selected: posProvider.selectedCategoryId == -1,
                  selectedColor: const Color(0xFFFEF3C7),
                  checkmarkColor: const Color(0xFFB45309),
                  side: BorderSide(
                    color: posProvider.selectedCategoryId == -1
                        ? const Color(0xFFF59E0B)
                        : Colors.amber.shade300,
                  ),
                  onSelected: (_) => posProvider.selectCategory(-1),
                ),
                const SizedBox(width: 8),
                // Dynamic Categories
                ...menuProvider.categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: posProvider.selectedCategoryId == cat.id,
                      onSelected: (_) => posProvider.selectCategory(cat.id),
                    ),
                  );
                }),
                const VerticalDivider(width: 16),
                // Dietary filter chips
                FilterChip(
                  avatar: const DietaryBadge(type: DietaryType.veg, size: 10),
                  label: const Text('Veg Only'),
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
                const VerticalDivider(width: 16),
                ActionChip(
                  avatar: const Icon(Icons.add_circle_outline_rounded, size: 16, color: CulinaryColors.flameOrange),
                  label: const Text(
                    '+ Custom Item',
                    style: TextStyle(fontWeight: FontWeight.w700, color: CulinaryColors.flameOrange),
                  ),
                  backgroundColor: CulinaryColors.flameOrange.withOpacity(0.08),
                  side: BorderSide(color: CulinaryColors.flameOrange.withOpacity(0.35)),
                  onPressed: () => _showAddCustomItemDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Dishes Grid / List View with Food Photos
          Expanded(
            child: dishes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 54, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('No dishes match your filter', style: theme.textTheme.titleMedium),
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
                          childAspectRatio: 0.88,
                        ),
                        itemCount: dishes.length,
                        itemBuilder: (context, index) {
                          final item = dishes[index];
                          final cartLine = posProvider.cart.where((l) => l.item.id == item.id).firstOrNull;

                          return RepaintBoundary(
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              elevation: cartLine != null ? 3 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: cartLine != null
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                                  width: cartLine != null ? 1.5 : 1,
                                ),
                              ),
                              color: !item.isAvailable
                                  ? theme.colorScheme.surfaceContainerHigh.withOpacity(0.55)
                                  : theme.colorScheme.surface,
                              child: InkWell(
                                onTap: () {
                                  if (item.isAvailable) {
                                    posProvider.addToCart(item);
                                    NativeApiChannel.triggerNativeHaptic();
                                  } else {
                                    NativeApiChannel.triggerNativeHaptic();
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (ctx) => SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  DietaryBadge(type: item.dietaryType, size: 16),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      item.name,
                                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade100,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Out of Stock',
                                                      style: TextStyle(
                                                        color: Colors.red.shade900,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 14),
                                              const Text(
                                                'This item is currently deactivated. Would you like to reactivate it or edit details?',
                                                style: TextStyle(fontSize: 13, color: Colors.grey),
                                              ),
                                              const SizedBox(height: 18),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      icon: const Icon(Icons.edit_rounded, size: 18),
                                                      label: const Text('Edit Dish'),
                                                      onPressed: () {
                                                        Navigator.pop(ctx);
                                                        _showAddEditDishDialog(context, item);
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                                                      label: const Text('Activate Dish'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: CulinaryColors.emeraldGreen,
                                                        foregroundColor: Colors.white,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.pop(ctx);
                                                        menuProvider.setItemAvailability(item.id, true);
                                                        AppNotification.showSuccess(
                                                          context,
                                                          '${item.name} is now Available / In Stock',
                                                          title: 'Dish Available',
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () => _showAddEditDishDialog(context, item),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Food Photo with Badges & 3-Dot Actions Overlay
                                    Stack(
                                      children: [
                                        buildDishImage(
                                          item.imageUri,
                                          height: 122,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          cacheWidth: 360,
                                        ),

                                        // Subtle Gradient Scrim
                                        Container(
                                          height: 122,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.35),
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.2),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Dietary Badge (Top Left)
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: DietaryBadge(type: item.dietaryType, size: 12),
                                              ),
                                              if (item.isTopSelling) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF59E0B),
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.25),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.star_rounded, color: Colors.white, size: 11),
                                                      SizedBox(width: 1),
                                                      Text(
                                                        'Best',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Deactivated / Out of Stock Dark Overlay (IgnorePointer so 3-dot and card get gestures)
                                        if (!item.isAvailable)
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: Container(
                                                color: Colors.black.withOpacity(0.55),
                                                alignment: Alignment.center,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade800,
                                                    borderRadius: BorderRadius.circular(6),
                                                    boxShadow: [
                                                      BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 4),
                                                    ],
                                                  ),
                                                  child: const Text(
                                                    'OUT OF STOCK',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 10,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                        // 3-Dot Quick Action Menu (Top Right - ON TOP OF OVERLAY)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: PopupMenuButton<String>(
                                            padding: EdgeInsets.zero,
                                            icon: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 15),
                                            ),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            onSelected: (val) {
                                              if (val == 'toggle') {
                                                menuProvider.toggleItemAvailability(item.id);
                                                if (!item.isAvailable) {
                                                  AppNotification.showSuccess(
                                                    context,
                                                    '${item.name} is now Available / In Stock',
                                                    title: 'Item In Stock',
                                                  );
                                                } else {
                                                  AppNotification.showInfo(
                                                    context,
                                                    '${item.name} marked Out of Stock / Inactive',
                                                    title: 'Item Out of Stock',
                                                  );
                                                }
                                              } else if (val == 'edit') {
                                                _showAddEditDishDialog(context, item);
                                              } else if (val == 'delete') {
                                                _confirmDeleteDish(context, item);
                                              }
                                            },
                                            itemBuilder: (context) => [
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
                                                    Text(item.isAvailable ? 'Deactivate (Out of Stock)' : 'Activate (In Stock)'),
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
                                        ),

                                        // Quantity in Cart overlay (Bottom Left of photo)
                                        if (cartLine != null)
                                          Positioned(
                                            bottom: 6,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                '${cartLine.quantity} in cart',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Dish Content
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              height: 1.2,
                                            ),
                                          ),
                                          if (item.sku != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 1),
                                              child: Text(
                                                item.sku!,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.outline,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 4),

                                          // Price & Quick Add Button Row
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                item.formattedPrice,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: item.isAvailable ? theme.colorScheme.primary : Colors.grey,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if (item.isAvailable && cartLine != null && cartLine.quantity > 0)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        NativeApiChannel.triggerNativeHaptic();
                                                        posProvider.decrementQuantity(item.id);
                                                      },
                                                      borderRadius: BorderRadius.circular(6),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: theme.colorScheme.primary.withOpacity(0.12),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Icon(
                                                          Icons.remove_rounded,
                                                          size: 17,
                                                          color: theme.colorScheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                                      child: Text(
                                                        '${cartLine.quantity}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 13,
                                                          color: theme.colorScheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        NativeApiChannel.triggerNativeHaptic();
                                                        posProvider.addToCart(item);
                                                      },
                                                      borderRadius: BorderRadius.circular(6),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: theme.colorScheme.primary,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.add_rounded,
                                                          size: 17,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                InkWell(
                                                  onTap: () {
                                                    if (item.isAvailable) {
                                                      posProvider.addToCart(item);
                                                      NativeApiChannel.triggerNativeHaptic();
                                                    }
                                                  },
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      color: item.isAvailable
                                                          ? theme.colorScheme.primary.withOpacity(0.12)
                                                          : Colors.grey.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(
                                                      item.isAvailable ? Icons.add_rounded : Icons.block_rounded,
                                                      size: 20,
                                                      color: item.isAvailable ? theme.colorScheme.primary : Colors.grey,
                                                    ),
                                                  ),
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
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 90),
                        itemCount: dishes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = dishes[index];
                          final cartLine = posProvider.cart.where((l) => l.item.id == item.id).firstOrNull;

                          return RepaintBoundary(
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: item.isAvailable
                                    ? theme.colorScheme.surface
                                    : theme.colorScheme.surfaceContainerHigh.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: cartLine != null
                                      ? theme.colorScheme.primary
                                      : (item.isAvailable
                                          ? theme.colorScheme.outlineVariant.withOpacity(0.4)
                                          : Colors.red.withOpacity(0.3)),
                                  width: cartLine != null ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (item.isAvailable) {
                                    posProvider.addToCart(item);
                                    NativeApiChannel.triggerNativeHaptic();
                                  } else {
                                    NativeApiChannel.triggerNativeHaptic();
                                    menuProvider.toggleItemAvailability(item.id);
                                    AppNotification.showSuccess(
                                      context,
                                      '${item.name} activated',
                                      title: 'Dish Activated',
                                    );
                                  }
                                },
                                onLongPress: () => _showAddEditDishDialog(context, item),
                                child: SizedBox(
                                  height: 104,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Dish Thumbnail - Flush left/top/bottom, no margin
                                      SizedBox(
                                        width: 104,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                          child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            buildDishImage(
                                              item.imageUri,
                                              height: 104,
                                              width: 104,
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
                                                        'Best',
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

                                      // Details
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(10, 10, 4, 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  height: 1.18,
                                                  decoration: item.isAvailable ? null : TextDecoration.lineThrough,
                                                ),
                                              ),

                                            const SizedBox(height: 6),
                                            Text(
                                              item.formattedPrice,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: item.isAvailable ? CulinaryColors.flameOrange : Colors.grey,
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),
                                    ),

                                      // Quick Add or Action button
                                      if (item.isAvailable && cartLine != null && cartLine.quantity > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.remove_circle_rounded, color: theme.colorScheme.primary, size: 32),
                                                iconSize: 32,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                                onPressed: () {
                                                  NativeApiChannel.triggerNativeHaptic();
                                                  posProvider.decrementQuantity(item.id);
                                                },
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  '${cartLine.quantity}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.add_circle_rounded, color: theme.colorScheme.primary, size: 32),
                                                iconSize: 32,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                                onPressed: () {
                                                  NativeApiChannel.triggerNativeHaptic();
                                                  posProvider.addToCart(item);
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: IconButton(
                                            icon: Icon(
                                              item.isAvailable ? Icons.add_circle_rounded : Icons.more_vert_rounded,
                                              color: item.isAvailable ? theme.colorScheme.primary : Colors.grey,
                                              size: 34,
                                            ),
                                            iconSize: 34,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                            onPressed: () {
                                              if (item.isAvailable) {
                                                posProvider.addToCart(item);
                                                NativeApiChannel.triggerNativeHaptic();
                                              } else {
                                                _showAddEditDishDialog(context, item);
                                              }
                                            },
                                          ),
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
          ),
          if (posProvider.cart.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 86,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${posProvider.totalItemCount} Items in Cart',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatRupees(posProvider.totalRupees),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    BouncingButton(
                      onPressed: () => _openCartBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [CulinaryColors.flameOrange, CulinaryColors.tandoorSpice],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: CulinaryColors.flameOrange.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Review & Pay',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartBottomSheet extends StatelessWidget {
  const _CartBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posProvider = context.watch<PosProvider>();
    final orderProvider = context.read<OrderProvider>();
    final tableProvider = context.read<TableProvider>();
    final menuProvider = context.read<MenuProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cart Order',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => posProvider.clearCart(),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              itemCount: posProvider.cart.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final line = posProvider.cart[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      DietaryBadge(type: line.item.dietaryType),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.item.name,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              line.item.formattedPrice,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                      // Stepper
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 16),
                              onPressed: () => posProvider.decrementQuantity(line.item.id),
                            ),
                            Text(
                              '${line.quantity}',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 16),
                              onPressed: () => posProvider.addToCart(line.item),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        CurrencyFormatter.formatPaise(line.lineTotalPaise),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bill Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      posProvider.isGstEnabled && posProvider.isTaxInclusive
                          ? 'Taxable Base (Net)'
                          : 'Subtotal',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      CurrencyFormatter.formatRupees(
                        posProvider.isGstEnabled && posProvider.isTaxInclusive
                            ? posProvider.taxableBaseRupees
                            : posProvider.subtotalRupees,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      posProvider.isGstEnabled
                          ? 'GST (${posProvider.gstRatePercent.toStringAsFixed(1)}%) [CGST ${(posProvider.gstRatePercent / 2).toStringAsFixed(1)}% + SGST ${(posProvider.gstRatePercent / 2).toStringAsFixed(1)}%]${posProvider.isTaxInclusive ? ' (Incl.)' : ''}'
                          : 'Tax Exempt / Non-GST',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: posProvider.isGstEnabled ? theme.colorScheme.outline : Colors.green.shade700,
                        fontWeight: posProvider.isGstEnabled ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    Text(
                      posProvider.isGstEnabled ? CurrencyFormatter.formatRupees(posProvider.taxRupees) : '₹0.00',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: posProvider.isGstEnabled ? null : Colors.green.shade700,
                        fontWeight: posProvider.isGstEnabled ? null : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (posProvider.discountRupees > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700),
                      ),
                      Text(
                        '-${CurrencyFormatter.formatRupees(posProvider.discountRupees)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (posProvider.isRoundOffEnabled && posProvider.roundOffAdjustmentPaise != 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Round-Off Adjustment',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                      Text(
                        '${posProvider.roundOffAdjustmentPaise > 0 ? "+" : ""}${CurrencyFormatter.formatRupees(posProvider.roundOffAdjustmentRupees)}',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      CurrencyFormatter.formatRupees(posProvider.totalRupees),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Checkout Pay Button
          BouncingButton(
            onPressed: () {
              Navigator.pop(context); // Close cart sheet
              final order = posProvider.buildOrder(paymentMethod: PaymentMethod.upi);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => PaymentModal(
                  order: order,
                  onPaymentConfirmed: () {
                    orderProvider.addOrder(order);
                    for (final item in order.items) {
                      menuProvider.recordItemSale(item.menuItem.id, item.quantity);
                    }
                    if (order.tableId != null) {
                      tableProvider.freeTable(order.tableId!);
                    }
                    posProvider.clearCart();
                    AppNotification.showSuccess(
                      context,
                      'Order #${order.orderNumber} placed successfully',
                      title: 'Payment Received',
                    );
                  },
                  onPaymentConfirmedWithMethod: (chosenMethod) {
                    final settledOrder = order.copyWith(
                      paymentMethod: chosenMethod,
                      status: OrderStatus.paid,
                      completedAt: DateTime.now(),
                    );
                    orderProvider.addOrder(settledOrder);
                    for (final item in settledOrder.items) {
                      menuProvider.recordItemSale(item.menuItem.id, item.quantity);
                    }
                    if (settledOrder.tableId != null) {
                      tableProvider.freeTable(settledOrder.tableId!);
                    }
                    posProvider.clearCart();
                    AppNotification.showSuccess(
                      context,
                      'Order #${settledOrder.orderNumber} settled via ${chosenMethod.name.toUpperCase()}',
                      title: 'Payment Received',
                    );
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                'Proceed to Payment (${CurrencyFormatter.formatRupees(posProvider.totalRupees)})',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
