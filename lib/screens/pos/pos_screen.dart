import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/menu_item.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/table_provider.dart';
import '../../widgets/dietary_badge.dart';
import 'payment_modal.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  DietaryType? _dietaryFilter;
  bool _isSearchVisible = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDishDialog(BuildContext context, [MenuItem? itemToEdit]) {
    final menuProvider = context.read<MenuProvider>();
    final isEditing = itemToEdit != null;

    final nameController = TextEditingController(text: itemToEdit?.name ?? '');
    final priceController = TextEditingController(
      text: itemToEdit != null ? (itemToEdit.pricePaise / 100).toStringAsFixed(0) : '',
    );
    final skuController = TextEditingController(text: itemToEdit?.sku ?? '');
    final descController = TextEditingController(text: itemToEdit?.description ?? '');

    int selectedCategoryId = itemToEdit?.categoryId ??
        (menuProvider.categories.isNotEmpty ? menuProvider.categories.first.id : 1);
    DietaryType selectedDietaryType = itemToEdit?.dietaryType ?? DietaryType.veg;
    bool isTopSelling = itemToEdit?.isTopSelling ?? false;
    bool isAvailable = itemToEdit?.isAvailable ?? true;

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
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Ingredients, spice level, preparation...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid dish name and price')),
                      );
                      return;
                    }

                    final pricePaise = (priceNum * 100).round();

                    if (isEditing) {
                      final updated = itemToEdit.copyWith(
                        name: name,
                        pricePaise: pricePaise,
                        categoryId: selectedCategoryId,
                        dietaryType: selectedDietaryType,
                        sku: skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        isTopSelling: isTopSelling,
                        isAvailable: isAvailable,
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
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        isTopSelling: isTopSelling,
                        isAvailable: isAvailable,
                        imageUri: null,
                      );
                      menuProvider.addItem(newItem);
                    }

                    Navigator.pop(dlgContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Dish "$name" updated successfully'
                              : 'Dish "$name" added to menu',
                        ),
                        backgroundColor: Colors.green.shade700,
                      ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dish "${item.name}" deleted from menu'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
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
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add New Dish',
            onPressed: () => _showAddEditDishDialog(context),
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
      body: Column(
        children: [
          // Table Selector Bar (if Dine-In)
          if (posProvider.orderType == OrderType.dineIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.5),
              child: Row(
                children: [
                  Icon(
                    Icons.table_restaurant_rounded,
                    size: 20,
                    color: posProvider.selectedTableName != null
                        ? theme.colorScheme.primary
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    posProvider.selectedTableName != null
                        ? 'Table: ${posProvider.selectedTableName}'
                        : 'Select Table',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: posProvider.selectedTableName != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showTableSelector(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: posProvider.selectedTableName != null
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.primary,
                      foregroundColor: posProvider.selectedTableName != null
                          ? theme.colorScheme.onPrimaryContainer
                          : Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.touch_app_rounded, size: 16),
                    label: Text(
                      posProvider.selectedTableName != null ? 'Change Table' : 'Select Table',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar (Hides on scroll down)
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            child: _isSearchVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Search dishes, codes or SKU...',
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
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
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Dishes Grid with Food Photos
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
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is UserScrollNotification) {
                        if (notification.direction == ScrollDirection.reverse && _isSearchVisible) {
                          setState(() => _isSearchVisible = false);
                        } else if (notification.direction == ScrollDirection.forward && !_isSearchVisible) {
                          setState(() => _isSearchVisible = true);
                        }
                      } else if (notification is ScrollUpdateNotification) {
                        final delta = notification.scrollDelta ?? 0.0;
                        if (delta > 8 && _isSearchVisible) {
                          setState(() => _isSearchVisible = false);
                        } else if (delta < -8 && !_isSearchVisible) {
                          setState(() => _isSearchVisible = true);
                        }
                      }
                      return false;
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 90),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.74,
                      ),
                      itemCount: dishes.length,
                      itemBuilder: (context, index) {
                        final item = dishes[index];
                        final cartLine = posProvider.cart.where((l) => l.item.id == item.id).firstOrNull;

                        return BouncingButton(
                          onPressed: () {
                            if (item.isAvailable) {
                              posProvider.addToCart(item);
                              NativeApiChannel.triggerNativeHaptic();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} is marked Out of Stock. Use the menu (⋮) to activate.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: GestureDetector(
                            onLongPress: () => _showAddEditDishDialog(context, item),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Food Photo with Badges & 3-Dot Actions Overlay
                                  Stack(
                                    children: [
                                      if (item.imageUri != null)
                                        Image.asset(
                                          item.imageUri!,
                                          height: 102,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 102,
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              child: Icon(Icons.restaurant_rounded, color: theme.colorScheme.outline),
                                            );
                                          },
                                        )
                                      else
                                        Container(
                                          height: 102,
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: Icon(Icons.restaurant_rounded, color: theme.colorScheme.outline),
                                        ),

                                      // Subtle Gradient Scrim
                                      Container(
                                        height: 102,
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

                                      // 3-Dot Quick Action Menu (Top Right)
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
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    item.isAvailable
                                                        ? '${item.name} marked Out of Stock / Inactive'
                                                        : '${item.name} is now Available / In Stock',
                                                  ),
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
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

                                      // Deactivated / Out of Stock Dark Overlay
                                      if (!item.isAvailable)
                                        Positioned.fill(
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
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  height: 1.2,
                                                ),
                                              ),
                                              if (item.sku != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    item.sku!,
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      color: theme.colorScheme.outline,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),

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
                                              Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: item.isAvailable
                                                      ? theme.colorScheme.primary.withOpacity(0.12)
                                                      : Colors.grey.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  item.isAvailable ? Icons.add_rounded : Icons.block_rounded,
                                                  size: 18,
                                                  color: item.isAvailable ? theme.colorScheme.primary : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      // Floating Bottom Cart Bar
      bottomSheet: posProvider.cart.isNotEmpty
          ? Material(
              elevation: 12,
              color: theme.colorScheme.surfaceContainerLowest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                ),
                child: SafeArea(
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
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatRupees(posProvider.totalRupees),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    BouncingButton(
                      onPressed: () => _openCartBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Review & Pay',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
          )
        : null,
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
                    Text('Subtotal', style: theme.textTheme.bodyMedium),
                    Text(CurrencyFormatter.formatRupees(posProvider.subtotalRupees)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      posProvider.isGstEnabled
                          ? 'GST (${posProvider.gstRatePercent.toStringAsFixed(1)}%) [CGST ${(posProvider.gstRatePercent / 2).toStringAsFixed(1)}% + SGST ${(posProvider.gstRatePercent / 2).toStringAsFixed(1)}%]'
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
                    if (order.tableId != null) {
                      tableProvider.freeTable(order.tableId!);
                    }
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
