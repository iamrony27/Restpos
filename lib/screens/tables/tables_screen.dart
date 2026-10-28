import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
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
            Text(table.name),
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
          if (table.status == TableStatus.available)
            FilledButton.icon(
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
              label: const Text('Start Table Order'),
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
              child: const Text('Clear & Reset Table'),
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
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
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

                return BouncingButton(
                  onPressed: () {
                    NativeApiChannel.triggerNativeHaptic();
                    _showTableActionDialog(context, table);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusText(table.status),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.people_alt_rounded, size: 16, color: theme.colorScheme.outline),
                              const SizedBox(width: 4),
                              Text(
                                '${table.seatingCapacity} Seats',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                              ),
                              if (table.occupiedSince != null) ...[
                                const Spacer(),
                                Icon(Icons.timer_outlined, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${table.elapsedMinutes}m',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (table.currentBillPaise > 0)
                            Text(
                              CurrencyFormatter.formatPaise(table.currentBillPaise),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          else
                            Text(
                              'Ready for seating',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
