import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/table_provider.dart';
import '../../widgets/animated_stat_card.dart';
import '../../widgets/dietary_badge.dart';
import '../setup/setup_wizard_screen.dart';

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
    final posProvider = context.watch<PosProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final profile = posProvider.profile;

    final totalRevenue = orderProvider.totalRevenueRupees;
    final orderCount = orderProvider.orderCount;
    final atv = orderProvider.averageTicketValueRupees;
    final occupiedTables = tableProvider.occupiedCount;
    final availableTables = tableProvider.availableCount;
    final bestsellers = menuProvider.topSellingItems;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: CulinaryColors.tandoorOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: CulinaryColors.emeraldGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CulinaryColors.emeraldGreen.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'OFFLINE POS',
                    style: TextStyle(
                      color: CulinaryColors.emeraldGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${profile.tagline} • FSSAI: ${profile.fssai.isNotEmpty ? profile.fssai : "11223344556677"} • ${_deviceInfo.model}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          // Setup Wizard Action Button
          IconButton(
            tooltip: 'Setup Wizard',
            icon: const Icon(Icons.settings_suggest_rounded, color: CulinaryColors.tandoorOrange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SetupWizardScreen()),
              );
            },
          ),
          // Native Battery & Hardware Badge
          Container(
            margin: const EdgeInsets.only(right: 14),
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
                      ? CulinaryColors.emeraldGreen
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
            // Vibrant Welcome & Shift Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    CulinaryColors.tandoorOrange,
                    CulinaryColors.flameOrange,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: CulinaryColors.tandoorOrange.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.restaurant_menu_rounded, color: CulinaryColors.tandoorOrange, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lunch Service Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'GST: ${profile.isGstEnabled ? "${profile.gstRatePercent.toStringAsFixed(0)}% (Enabled)" : "Disabled (Non-GST)"} • Round-Off: ${profile.isRoundOffEnabled ? "ON" : "OFF"}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BouncingButton(
                    onPressed: () => widget.onNavigateTab(1), // Open POS
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.point_of_sale_rounded, size: 18, color: CulinaryColors.tandoorOrange),
                          SizedBox(width: 6),
                          Text(
                            'New Sale',
                            style: TextStyle(
                              color: CulinaryColors.tandoorOrange,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
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

            // Vibrant Metric Stat Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                AnimatedStatCard(
                  title: "Today's Gross Sales",
                  value: CurrencyFormatter.formatRupees(totalRevenue),
                  subtitle: '+18.4% vs yesterday',
                  icon: Icons.currency_rupee_rounded,
                  iconColor: CulinaryColors.emeraldGreen,
                  onTap: () => widget.onNavigateTab(3), // Orders
                ),
                AnimatedStatCard(
                  title: 'Completed Orders',
                  value: '$orderCount Bills',
                  subtitle: '${orderProvider.activeOrders.length} active in kitchen',
                  icon: Icons.receipt_long_rounded,
                  iconColor: CulinaryColors.flameOrange,
                  onTap: () => widget.onNavigateTab(3), // Orders
                ),
                AnimatedStatCard(
                  title: 'Avg Order Value (ATV)',
                  value: CurrencyFormatter.formatRupees(atv),
                  subtitle: 'High dining ticket',
                  icon: Icons.trending_up_rounded,
                  iconColor: CulinaryColors.royalBlue,
                ),
                AnimatedStatCard(
                  title: 'Floor Occupancy',
                  value: '$occupiedTables / ${tableProvider.tables.length}',
                  subtitle: '$availableTables tables available',
                  icon: Icons.table_restaurant_rounded,
                  iconColor: CulinaryColors.amethystViolet,
                  onTap: () => widget.onNavigateTab(2), // Tables
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Top Selling Dishes / Kitchen Bestsellers Horizontal Carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            'Top Selling Items',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kitchen favorites ranked by live sales volume',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    posProvider.selectCategory(-1); // Switch to Bestsellers
                    widget.onNavigateTab(1); // Go to POS
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: bestsellers.length,
                itemBuilder: (context, index) {
                  final item = bestsellers[index];
                  final rank = index + 1;

                  Color rankColor;
                  if (rank == 1) {
                    rankColor = const Color(0xFFEAB308); // Gold
                  } else if (rank == 2) {
                    rankColor = const Color(0xFF94A3B8); // Silver
                  } else if (rank == 3) {
                    rankColor = const Color(0xFFD97706); // Bronze
                  } else {
                    rankColor = CulinaryColors.tandoorOrange;
                  }

                  return Container(
                    width: 155,
                    margin: const EdgeInsets.only(right: 12),
                    child: BouncingButton(
                      onPressed: () {
                        posProvider.addToCart(item);
                        NativeApiChannel.triggerNativeHaptic();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added to cart!'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: CulinaryColors.emeraldGreen,
                          ),
                        );
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: rank == 1 ? const Color(0xFFF59E0B) : theme.colorScheme.outlineVariant.withOpacity(0.5),
                            width: rank == 1 ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Food Photo with Rank Badge
                            Stack(
                              children: [
                                if (item.imageUri != null)
                                  Image.asset(
                                    item.imageUri!,
                                    height: 95,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 95,
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.restaurant_rounded),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 95,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.restaurant_rounded),
                                  ),

                                // Scrim
                                Container(
                                  height: 95,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.4),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),

                                // Rank Badge (Top Left)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: rankColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '#$rank',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),

                                // Dietary badge (Top Right)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: DietaryBadge(type: item.dietaryType, size: 10),
                                  ),
                                ),
                              ],
                            ),

                            // Dish info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                        Text(
                                          '${item.salesCount} orders',
                                          style: const TextStyle(
                                            color: CulinaryColors.emeraldGreen,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.formattedPrice,
                                          style: const TextStyle(
                                            color: CulinaryColors.tandoorOrange,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: CulinaryColors.tandoorOrange.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.add_rounded, size: 14, color: CulinaryColors.tandoorOrange),
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
                              gradient: const LinearGradient(
                                colors: [CulinaryColors.tandoorOrange, CulinaryColors.turmericGold],
                              ),
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    CulinaryColors.tandoorOrange.withOpacity(0.25),
                                    CulinaryColors.turmericGold.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
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

            // Payment Channel Breakdown
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
                      color: CulinaryColors.royalBlue,
                    ),
                    const Divider(height: 20),
                    _buildPaymentRow(
                      context,
                      label: 'Cash Tender',
                      amount: orderProvider.paymentDistribution[PaymentMethod.cash] ?? 0.0,
                      icon: Icons.payments_rounded,
                      color: CulinaryColors.emeraldGreen,
                    ),
                    const Divider(height: 20),
                    _buildPaymentRow(
                      context,
                      label: 'Debit / Credit Card',
                      amount: orderProvider.paymentDistribution[PaymentMethod.card] ?? 0.0,
                      icon: Icons.credit_card_rounded,
                      color: CulinaryColors.flameOrange,
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
        backgroundColor: CulinaryColors.tandoorOrange,
        foregroundColor: Colors.white,
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
