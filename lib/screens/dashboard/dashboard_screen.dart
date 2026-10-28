import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';
import '../../widgets/animated_stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  NativeBatteryInfo _batteryInfo = const NativeBatteryInfo(levelPercent: 95, isCharging: false);
  NativeDeviceInfo _deviceInfo = const NativeDeviceInfo(
    model: 'Android Terminal',
    manufacturer: 'Native',
    androidVersion: '14.0',
    sdkInt: 34,
    deviceId: 'pos-main',
  );

  @override
  void initState() {
    super.initState();
    _loadNativeData();
  }

  Future<void> _loadNativeData() async {
    final battery = await NativeApiChannel.getBatteryInfo();
    final device = await NativeApiChannel.getDeviceInfo();
    if (mounted) {
      setState(() {
        _batteryInfo = battery;
        _deviceInfo = device;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProvider = context.watch<OrderProvider>();
    final tableProvider = context.watch<TableProvider>();

    final totalRevenue = orderProvider.totalRevenueRupees;
    final orderCount = orderProvider.orderCount;
    final atv = orderProvider.averageTicketValueRupees;
    final occupiedTables = tableProvider.occupiedCount;
    final availableTables = tableProvider.availableCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Spice Garden POS',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OFFLINE FIRST',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${_deviceInfo.model} • Android ${_deviceInfo.androidVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          // Native Battery & Hardware Badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _batteryInfo.isCharging
                      ? Icons.battery_charging_full_rounded
                      : Icons.battery_std_rounded,
                  size: 16,
                  color: _batteryInfo.levelPercent > 20
                      ? const Color(0xFF16A34A)
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_batteryInfo.levelPercent}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNativeData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome & Shift Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.8),
                    theme.colorScheme.secondaryContainer.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, Rahul!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active Shift • Lunch Service • Dine-In & Counter Open',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BouncingButton(
                    onPressed: () => widget.onNavigateTab(1), // Open POS
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Quick Sale',
                            style: theme.textTheme.labelMedium?.copyWith(
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

            const SizedBox(height: 20),

            // Top Stat Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                AnimatedStatCard(
                  title: "Today's Gross Sales",
                  value: CurrencyFormatter.formatRupees(totalRevenue),
                  subtitle: '+18.4% vs yesterday',
                  icon: Icons.currency_rupee_rounded,
                  iconColor: theme.colorScheme.primary,
                  onTap: () => widget.onNavigateTab(3), // Orders
                ),
                AnimatedStatCard(
                  title: 'Total Orders',
                  value: '$orderCount Orders',
                  subtitle: '${orderProvider.activeOrders.length} active in kitchen',
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFFD97706),
                  onTap: () => widget.onNavigateTab(3),
                ),
                AnimatedStatCard(
                  title: 'Average Ticket Value',
                  value: CurrencyFormatter.formatRupees(atv),
                  subtitle: 'Basket size benchmark',
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF0D9488),
                ),
                AnimatedStatCard(
                  title: 'Floor Occupancy',
                  value: '$occupiedTables / ${tableProvider.tables.length}',
                  subtitle: '$availableTables tables ready for guests',
                  icon: Icons.table_restaurant_rounded,
                  iconColor: const Color(0xFF9333EA),
                  onTap: () => widget.onNavigateTab(2), // Tables
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sales Velocity Hourly Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hourly Sales Velocity',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Peak rush detection for kitchen prep',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Today',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 200,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (val, meta) {
                                  const hours = ['11 AM', '12 PM', '1 PM', '2 PM', '3 PM', '4 PM'];
                                  final int index = val.toInt();
                                  if (index >= 0 && index < hours.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        hours[index],
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.outline,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 120),
                                FlSpot(1, 480),
                                FlSpot(2, 650),
                                FlSpot(3, 340),
                                FlSpot(4, 180),
                                FlSpot(5, 420),
                              ],
                              isCurved: true,
                              color: theme.colorScheme.primary,
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary.withOpacity(0.12),
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

            const SizedBox(height: 24),

            // Payment Modes Breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Channel Breakdown',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildPaymentRow(
                      context,
                      label: 'UPI QR Codes',
                      amount: orderProvider.paymentDistribution[PaymentMethod.upi] ?? 0.0,
                      icon: Icons.qr_code_2_rounded,
                      color: const Color(0xFF0284C7),
                    ),
                    const Divider(height: 20),
                    _buildPaymentRow(
                      context,
                      label: 'Cash Tender',
                      amount: orderProvider.paymentDistribution[PaymentMethod.cash] ?? 0.0,
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF16A34A),
                    ),
                    const Divider(height: 20),
                    _buildPaymentRow(
                      context,
                      label: 'Debit / Credit Card',
                      amount: orderProvider.paymentDistribution[PaymentMethod.card] ?? 0.0,
                      icon: Icons.credit_card_rounded,
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onNavigateTab(1), // Go to POS billing
        icon: const Icon(Icons.point_of_sale_rounded),
        label: const Text('Start New Order', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildPaymentRow(
    BuildContext context, {
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          CurrencyFormatter.formatRupees(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
