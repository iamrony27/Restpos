import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../../widgets/thermal_slip_preview_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'all'; // all, active, completed, deleted

  void _showOrderDetailsDialog(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final orderProvider = context.read<OrderProvider>();
    final tableProvider = context.read<TableProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.type == OrderType.dineIn
                              ? (order.tableName ?? 'Dine-In')
                              : 'Takeaway',
                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.isDeleted)
                  _buildTagBadge(
                    label: 'DELETED',
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFEF4444).withOpacity(0.16),
                  )
                else if (order.isEdited)
                  _buildTagBadge(
                    label: 'EDITED',
                    icon: Icons.edit_note_rounded,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFF59E0B).withOpacity(0.16),
                  ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Placed at ${DateFormat('hh:mm a, dd MMM').format(order.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
                if (order.isEdited && order.editedAt != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        'Last edited: ${DateFormat('hh:mm a, dd MMM').format(order.editedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.isDeleted && order.deletedAt != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.delete_forever_rounded, size: 14, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(
                        'Deleted at: ${DateFormat('hh:mm a, dd MMM').format(order.deletedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 20),
                ...order.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.quantity}x ${it.menuItem.name}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(CurrencyFormatter.formatPaise(it.lineTotalPaise)),
                    ],
                  ),
                )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.isTaxInclusive && order.taxBps > 0 ? 'Taxable Base (Net)' : 'Subtotal',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      CurrencyFormatter.formatRupees(
                        order.isTaxInclusive && order.taxBps > 0
                            ? order.taxableBaseRupees
                            : order.subtotalRupees,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.taxBps > 0
                          ? 'GST (${(order.taxBps / 100).toStringAsFixed(1)}% - CGST ${(order.taxBps / 200).toStringAsFixed(1)}% + SGST ${(order.taxBps / 200).toStringAsFixed(1)}%)${order.isTaxInclusive ? ' [Incl]' : ''}'
                          : 'Tax (Exempt)',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    Text(CurrencyFormatter.formatRupees(order.taxRupees)),
                  ],
                ),
                if (order.discountPaise > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discount', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700)),
                      Text(
                        '-${CurrencyFormatter.formatRupees(order.discountRupees)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                if (order.roundOffPaise != 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Round Off', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      Text(
                        '${order.roundOffPaise > 0 ? "+" : ""}${CurrencyFormatter.formatRupees(order.roundOffRupees)}',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      CurrencyFormatter.formatRupees(order.totalRupees),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: order.isDeleted ? const Color(0xFFDC2626) : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Preview & Print KOT / Bill
          OutlinedButton.icon(
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text('Print Slip'),
            onPressed: () {
              final posProvider = Provider.of<PosProvider>(ctx, listen: false);
              ThermalSlipPreviewDialog.show(
                ctx,
                order: order,
                profile: posProvider.profile,
                title: 'Order #${order.orderNumber} Slip',
              );
            },
          ),
          if (!order.isDeleted) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(ctx);
                _showEditOrderDialog(context, order);
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDeleteOrder(context, order);
              },
            ),
          ] else ...[
            FilledButton.icon(
              icon: const Icon(Icons.restore_rounded, size: 16),
              label: const Text('Restore'),
              onPressed: () {
                orderProvider.restoreOrder(order.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order #${order.orderNumber} restored.')),
                );
              },
            ),
          ],
          if (!order.isDeleted && (order.status == OrderStatus.open || order.status == OrderStatus.billed)) ...[
            FilledButton(
              onPressed: () {
                orderProvider.updateOrderStatus(order.id, OrderStatus.completed, method: PaymentMethod.cash);
                if (order.tableId != null) {
                  tableProvider.freeTable(order.tableId!);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Settle as Paid'),
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

  void _confirmDeleteOrder(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final orderProvider = context.read<OrderProvider>();
    final tableProvider = context.read<TableProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
        title: Text('Delete Order #${order.orderNumber}?'),
        content: Text(
          'This order will be marked as DELETED and excluded from all active kitchen orders and dashboard sales statistics.\n\n'
          '${order.tableName != null ? "The occupied table (${order.tableName}) will also be freed." : ""}',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () {
              orderProvider.deleteOrder(order.id, tableProvider: tableProvider);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #${order.orderNumber} deleted successfully.'),
                  backgroundColor: theme.colorScheme.error,
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () {
                      orderProvider.restoreOrder(order.id);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete Order'),
          ),
        ],
      ),
    );
  }

  void _showEditOrderDialog(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final orderProvider = context.read<OrderProvider>();
    final tableProvider = context.read<TableProvider>();
    final menuItems = context.read<MenuProvider>().items;

    List<OrderItem> draftItems = List<OrderItem>.from(order.items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            final subtotalPaise = draftItems.fold<int>(0, (sum, i) => sum + i.lineTotalPaise);
            final isInclusive = order.isTaxInclusive;
            final taxBps = order.taxBps;
            final taxableBasePaise = (isInclusive && taxBps > 0)
                ? (subtotalPaise * 10000) ~/ (10000 + taxBps)
                : subtotalPaise;
            final taxPaise = taxBps == 0
                ? 0
                : (isInclusive ? (subtotalPaise - taxableBasePaise) : (subtotalPaise * taxBps) ~/ 10000);
            final totalPaise = isInclusive ? subtotalPaise : (subtotalPaise + taxPaise);

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Edit Order #${order.orderNumber}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              _buildTagBadge(
                                label: 'EDITING',
                                icon: Icons.edit_note_rounded,
                                color: const Color(0xFFD97706),
                                bgColor: const Color(0xFFF59E0B).withOpacity(0.16),
                              ),
                            ],
                          ),
                          Text(
                            order.type == OrderType.dineIn
                                ? (order.tableName ?? 'Dine-In')
                                : 'Takeaway',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Items List Header + Add Item Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items in Order (${draftItems.length})',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Item'),
                        onPressed: () async {
                          final selected = await showDialog<MenuItem>(
                            context: dialogContext,
                            builder: (pickCtx) => AlertDialog(
                              title: const Text('Add Dish to Order'),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 350,
                                child: ListView.separated(
                                  itemCount: menuItems.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (itemCtx, i) {
                                    final mi = menuItems[i];
                                    return ListTile(
                                      title: Text(mi.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text(CurrencyFormatter.formatPaise(mi.pricePaise)),
                                      trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7)),
                                      onTap: () => Navigator.pop(pickCtx, mi),
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(pickCtx),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          );

                          if (selected != null) {
                            setModalState(() {
                              final existingIdx = draftItems.indexWhere((it) => it.menuItem.id == selected.id);
                              if (existingIdx >= 0) {
                                final existing = draftItems[existingIdx];
                                draftItems[existingIdx] = existing.copyWith(quantity: existing.quantity + 1);
                              } else {
                                draftItems.add(
                                  OrderItem(
                                    menuItem: selected,
                                    quantity: 1,
                                    unitPricePaise: selected.pricePaise,
                                  ),
                                );
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  // Draft items list
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: draftItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No items left. Please add an item or cancel.',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: draftItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (itCtx, i) {
                              final item = draftItems[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.menuItem.name,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          Text(
                                            CurrencyFormatter.formatPaise(item.unitPricePaise),
                                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quantity Stepper
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_rounded, size: 18),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setModalState(() {
                                                if (item.quantity > 1) {
                                                  draftItems[i] = item.copyWith(quantity: item.quantity - 1);
                                                } else {
                                                  draftItems.removeAt(i);
                                                }
                                              });
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_rounded, size: 18),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setModalState(() {
                                                draftItems[i] = item.copyWith(quantity: item.quantity + 1);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Subtotal
                                    SizedBox(
                                      width: 65,
                                      child: Text(
                                        CurrencyFormatter.formatPaise(item.lineTotalPaise),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setModalState(() {
                                          draftItems.removeAt(i);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const Divider(height: 16),
                  // Bill summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isInclusive && taxBps > 0 ? 'Taxable Base:' : 'Subtotal:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(isInclusive && taxBps > 0 ? taxableBasePaise : subtotalPaise),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        taxBps > 0
                            ? 'GST (${(taxBps / 100).toStringAsFixed(1)}%)${isInclusive ? ' [Included]' : ''}:'
                            : 'Tax (Exempt):',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(CurrencyFormatter.formatPaise(taxPaise), style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Updated Total:',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(totalPaise),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save & Cancel Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Save Changes'),
                          onPressed: draftItems.isEmpty
                              ? null
                              : () {
                                  orderProvider.editOrder(
                                    order.id,
                                    items: draftItems,
                                    tableProvider: tableProvider,
                                  );
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Order #${order.orderNumber} updated! Marked as EDITED.'),
                                      backgroundColor: const Color(0xFFD97706),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildTagBadge({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProvider = context.watch<OrderProvider>();

    var orders = orderProvider.orders;
    if (_selectedFilter == 'active') {
      orders = orderProvider.activeOrders;
    } else if (_selectedFilter == 'completed') {
      orders = orderProvider.completedOrders;
    } else if (_selectedFilter == 'deleted') {
      orders = orderProvider.deletedOrders;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Orders & Kitchen Tickets',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text('All (${orderProvider.orders.length})'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Kitchen Active (${orderProvider.activeOrders.length})'),
                  selected: _selectedFilter == 'active',
                  onSelected: (_) => setState(() => _selectedFilter = 'active'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Completed (${orderProvider.completedOrders.length})'),
                  selected: _selectedFilter == 'completed',
                  onSelected: (_) => setState(() => _selectedFilter = 'completed'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Deleted (${orderProvider.deletedOrders.length})'),
                  selected: _selectedFilter == 'deleted',
                  selectedColor: const Color(0xFFEF4444).withOpacity(0.18),
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'deleted' ? const Color(0xFFDC2626) : null,
                    fontWeight: _selectedFilter == 'deleted' ? FontWeight.w700 : null,
                  ),
                  onSelected: (_) => setState(() => _selectedFilter = 'deleted'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Order list
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFilter == 'deleted' ? Icons.delete_sweep_rounded : Icons.inbox_rounded,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == 'deleted'
                              ? 'No deleted orders'
                              : 'No orders in this category',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    cacheExtent: 600,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final isCompleted = order.status == OrderStatus.completed || order.status == OrderStatus.paid;

                      return RepaintBoundary(
                        child: BouncingButton(
                          onPressed: () {
                            NativeApiChannel.triggerNativeHaptic();
                            _showOrderDetailsDialog(context, order);
                          },
                          child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: order.isDeleted
                                ? BorderSide(color: const Color(0xFFEF4444).withOpacity(0.4), width: 1.2)
                                : order.isEdited
                                    ? BorderSide(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1.2)
                                    : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            order.orderNumber,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: order.type == OrderType.dineIn
                                                  ? const Color(0xFF0284C7).withOpacity(0.12)
                                                  : const Color(0xFFD97706).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              order.type == OrderType.dineIn
                                                  ? (order.tableName ?? 'Dine-In')
                                                  : 'Takeaway',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: order.type == OrderType.dineIn
                                                  ? const Color(0xFF0284C7)
                                                  : const Color(0xFFD97706),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (order.isDeleted)
                                            _buildTagBadge(
                                              label: 'DELETED',
                                              icon: Icons.delete_outline_rounded,
                                              color: const Color(0xFFDC2626),
                                              bgColor: const Color(0xFFEF4444).withOpacity(0.16),
                                            )
                                          else if (order.isEdited)
                                            _buildTagBadge(
                                              label: 'EDITED',
                                              icon: Icons.edit_note_rounded,
                                              color: const Color(0xFFD97706),
                                              bgColor: const Color(0xFFF59E0B).withOpacity(0.16),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: order.isDeleted
                                                ? const Color(0xFFEF4444).withOpacity(0.14)
                                                : isCompleted
                                                    ? const Color(0xFF16A34A).withOpacity(0.14)
                                                    : theme.colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            order.isDeleted ? 'DELETED' : order.status.name.toUpperCase(),
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: order.isDeleted
                                                  ? const Color(0xFFDC2626)
                                                  : isCompleted
                                                      ? const Color(0xFF16A34A)
                                                      : theme.colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onSelected: (value) {
                                            NativeApiChannel.triggerNativeHaptic();
                                            if (value == 'edit') {
                                              _showEditOrderDialog(context, order);
                                            } else if (value == 'delete') {
                                              _confirmDeleteOrder(context, order);
                                            } else if (value == 'restore') {
                                              orderProvider.restoreOrder(order.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Order #${order.orderNumber} restored.')),
                                              );
                                            } else if (value == 'print') {
                                              final posProvider = Provider.of<PosProvider>(context, listen: false);
                                              ThermalSlipPreviewDialog.show(
                                                context,
                                                order: order,
                                                profile: posProvider.profile,
                                                title: 'Order #${order.orderNumber} Slip',
                                              );
                                            }
                                          },
                                          itemBuilder: (popCtx) => [
                                            if (!order.isDeleted) ...[
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_rounded, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Edit Order'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Delete Order', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ] else ...[
                                              const PopupMenuItem(
                                                value: 'restore',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.restore_rounded, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Restore Order'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const PopupMenuItem(
                                              value: 'print',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.receipt_long_rounded, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Print Slip'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  order.items.map((i) => '${i.quantity}x ${i.menuItem.name}').join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('hh:mm a').format(order.createdAt),
                                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatRupees(order.totalRupees),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: order.isDeleted ? const Color(0xFFDC2626) : theme.colorScheme.primary,
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
