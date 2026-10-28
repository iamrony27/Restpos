import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/utils/app_notification.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/table_model.dart';
import '../../providers/pos_provider.dart';
import '../../providers/table_provider.dart';

class TablesScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const TablesScreen({super.key, required this.onNavigateTab});

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const Color(0xFF16A34A); // Green
      case TableStatus.occupied:
        return const Color(0xFF0284C7); // Blue
      case TableStatus.billed:
        return const Color(0xFFD97706); // Amber
      case TableStatus.reserved:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String _getStatusText(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.billed:
        return 'Billed';
      case TableStatus.reserved:
        return 'Reserved';
    }
  }

  Future<void> _showAddEditTableDialog(BuildContext context, [RestaurantTable? existingTable]) async {
    final tableProvider = context.read<TableProvider>();
    final isEditing = existingTable != null;
    final nameController = TextEditingController(
      text: isEditing ? existingTable.name : 'Table ${tableProvider.tables.length + 1}',
    );
    int capacity = isEditing ? existingTable.seatingCapacity : 4;
    TableStatus status = isEditing ? existingTable.status : TableStatus.available;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_rounded : Icons.add_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Edit Table' : 'Add New Table',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Table Name / Number', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. Table 11, Rooftop 3, Booth A',
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Seating Capacity (Guests)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove_rounded),
                      onPressed: capacity > 1
                          ? () => setDialogState(() => capacity--)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        '$capacity Seats',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: capacity < 30
                          ? () => setDialogState(() => capacity++)
                          : null,
                    ),
                  ],
                ),
                if (isEditing && existingTable.status != TableStatus.occupied && existingTable.status != TableStatus.billed) ...[
                  const SizedBox(height: 18),
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  SegmentedButton<TableStatus>(
                    segments: const [
                      ButtonSegment(value: TableStatus.available, label: Text('Available')),
                      ButtonSegment(value: TableStatus.reserved, label: Text('Reserved')),
                    ],
                    selected: {status},
                    onSelectionChanged: (set) {
                      setDialogState(() => status = set.first);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                NativeApiChannel.triggerNativeHaptic();
                if (isEditing) {
                  tableProvider.updateTable(
                    existingTable.id,
                    name: name,
                    seatingCapacity: capacity,
                    status: status,
                  );
                  AppNotification.showSuccess(context, '$name updated successfully');
                } else {
                  tableProvider.addTable(
                    name: name,
                    seatingCapacity: capacity,
                    status: status,
                  );
                  AppNotification.showSuccess(context, '$name added to Floor Plan');
                }
              },
              child: Text(isEditing ? 'Save Changes' : 'Add Table'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }

  void _confirmDeleteTable(BuildContext context, RestaurantTable table) {
    final tableProvider = context.read<TableProvider>();
    if (table.status == TableStatus.occupied || table.status == TableStatus.billed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Table In Use'),
            ],
          ),
          content: Text('${table.name} currently has an active order or pending bill. Please clear or settle the table before deleting it.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Table?'),
        content: Text('Are you sure you want to remove ${table.name} from the floor plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              NativeApiChannel.triggerNativeHaptic();
              tableProvider.deleteTable(table.id);
              AppNotification.showSuccess(context, '${table.name} deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTableActionDialog(BuildContext context, RestaurantTable table) {
    final tableProvider = context.read<TableProvider>();
    final posProvider = context.read<PosProvider>();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(table.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(table.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacity: ${table.seatingCapacity} Guests'),
            Text('Status: ${_getStatusText(table.status)}'),
            if (table.occupiedSince != null)
              Text('Dining Time: ${table.elapsedMinutes} mins elapsed'),
            if (table.currentBillPaise > 0)
              Text(
                'Current Bill: ${CurrencyFormatter.formatPaise(table.currentBillPaise)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit'),
            onPressed: () {
              Navigator.pop(ctx);
              _showAddEditTableDialog(context, table);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteTable(context, table);
            },
          ),
          if (table.status == TableStatus.available)
            FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
              label: const Text('Start Order'),
              onPressed: () {
                Navigator.pop(ctx);
                posProvider.selectTable(table.id, table.name);
                onNavigateTab(1); // Go to POS
              },
            ),
          if (table.status == TableStatus.occupied || table.status == TableStatus.billed) ...[
            TextButton(
              onPressed: () {
                tableProvider.freeTable(table.id);
                Navigator.pop(ctx);
              },
              child: const Text('Clear & Reset'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                posProvider.selectTable(table.id, table.name);
                onNavigateTab(1); // Go to POS to add items or bill
              },
              child: const Text('Add Items / Settle'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tableProvider = context.watch<TableProvider>();
    final tables = tableProvider.tables;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Floor Plan & Tables',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              onPressed: () => _showAddEditTableDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Table', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Floor Status Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Available (${tableProvider.availableCount})', const Color(0xFF16A34A)),
                _buildLegendItem('Occupied (${tableProvider.occupiedCount})', const Color(0xFF0284C7)),
                _buildLegendItem('Billed (${tableProvider.billedCount})', const Color(0xFFD97706)),
              ],
            ),
          ),
          const Divider(),
          // Tables Grid
          Expanded(
            child: tables.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.table_restaurant_outlined, size: 64, color: theme.colorScheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text('No tables found', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _showAddEditTableDialog(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add First Table'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    cacheExtent: 600,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      final statusColor = _getStatusColor(table.status);

                      return RepaintBoundary(
                        child: BouncingButton(
                        onPressed: () {
                          NativeApiChannel.triggerNativeHaptic();
                          _showTableActionDialog(context, table);
                        },
                        child: Card(
                          elevation: table.status != TableStatus.available ? 1.5 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: statusColor.withOpacity(table.status != TableStatus.available ? 0.45 : 0.25),
                              width: table.status != TableStatus.available ? 1.5 : 1,
                            ),
                          ),
                          color: table.status == TableStatus.occupied
                              ? const Color(0xFF0284C7).withOpacity(0.05)
                              : table.status == TableStatus.billed
                                  ? const Color(0xFFD97706).withOpacity(0.05)
                                  : table.status == TableStatus.available
                                      ? const Color(0xFF16A34A).withOpacity(0.03)
                                      : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        table.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert_rounded, size: 18, color: theme.colorScheme.outline),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_rounded, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit Table'),
                                            ],
                                          ),
                                        ),
                                        if (table.status == TableStatus.occupied || table.status == TableStatus.billed)
                                          const PopupMenuItem(
                                            value: 'clear',
                                            child: Row(
                                              children: [
                                                Icon(Icons.refresh_rounded, size: 18),
                                                SizedBox(width: 8),
                                                Text('Clear / Reset'),
                                              ],
                                            ),
                                          ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                              SizedBox(width: 8),
                                              Text('Delete Table', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (val) {
                                        NativeApiChannel.triggerNativeHaptic();
                                        if (val == 'edit') {
                                          _showAddEditTableDialog(context, table);
                                        } else if (val == 'clear') {
                                          tableProvider.freeTable(table.id);
                                          AppNotification.showSuccess(context, '${table.name} reset to Available');
                                        } else if (val == 'delete') {
                                          _confirmDeleteTable(context, table);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getStatusText(table.status),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    if (table.occupiedSince != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.timer_outlined, size: 13, color: statusColor),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${table.elapsedMinutes}m',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.people_alt_rounded, size: 15, color: theme.colorScheme.outline),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${table.seatingCapacity} Seats',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.outline,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (table.currentBillPaise > 0)
                                      Text(
                                        CurrencyFormatter.formatPaise(table.currentBillPaise),
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.primary,
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

  Widget _buildLegendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
