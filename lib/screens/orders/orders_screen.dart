import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'all'; // all, active, completed, cancelled

  void _showOrderDetailsDialog(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final orderProvider = context.read<OrderProvider>();
    final tableProvider = context.read<TableProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(order.orderNumber),
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
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Placed at ${DateFormat('hh:mm a, dd MMM').format(order.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
              const Divider(height: 20),
              ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${it.quantity}x ${it.menuItem.name}'),
                    Text(CurrencyFormatter.formatPaise(it.lineTotalPaise)),
                  ],
                ),
              )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GST (5%)'),
                  Text(CurrencyFormatter.formatRupees(order.taxRupees)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(
                    CurrencyFormatter.formatRupees(order.totalRupees),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // Print KOT
          OutlinedButton.icon(
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Reprint KOT / Bill'),
            onPressed: () async {
              await NativeApiChannel.printReceiptNative(
                receiptText: 'ORDER #${order.orderNumber}\n${order.items.map((i) => '${i.quantity}x ${i.menuItem.name}').join('\n')}',
              );
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Dispatched to thermal printer!')),
                );
              }
            },
          ),
          if (order.status == OrderStatus.open || order.status == OrderStatus.billed) ...[
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProvider = context.watch<OrderProvider>();

    var orders = orderProvider.orders;
    if (_selectedFilter == 'active') {
      orders = orderProvider.activeOrders;
    } else if (_selectedFilter == 'completed') {
      orders = orderProvider.completedOrders;
    } else if (_selectedFilter == 'cancelled') {
      orders = orders.where((o) => o.status == OrderStatus.cancelled).toList();
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
                        Icon(Icons.inbox_rounded, size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('No orders in this category', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final isCompleted = order.status == OrderStatus.completed || order.status == OrderStatus.paid;

                      return BouncingButton(
                        onPressed: () {
                          NativeApiChannel.triggerNativeHaptic();
                          _showOrderDetailsDialog(context, order);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          order.orderNumber,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
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
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? const Color(0xFF16A34A).withOpacity(0.14)
                                            : theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        order.status.name.toUpperCase(),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: isCompleted
                                              ? const Color(0xFF16A34A)
                                              : theme.colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
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
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
