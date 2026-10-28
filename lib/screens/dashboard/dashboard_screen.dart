import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pos_provider.dart';
import '../reports/sales_report_screen.dart';
import '../setup/setup_wizard_screen.dart';

enum ChartMode { itemWise, amountWise, history }
enum ItemsSoldInterval { today, weekly, monthly }

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ChartMode _chartMode = ChartMode.amountWise;
  ItemsSoldInterval _itemsInterval = ItemsSoldInterval.today;
  int _touchedChartIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderProvider = context.watch<OrderProvider>();
    final posProvider = context.watch<PosProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final profile = posProvider.profile;

    final totalRevenue = orderProvider.totalRevenueRupees;
    final completedBills = orderProvider.completedOrders.length;
    final atv = orderProvider.averageTicketValueRupees;
    final bestsellers = menuProvider.topSellingItems;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 14,
        toolbarHeight: 68,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: theme.brightness == Brightness.dark
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: (theme.brightness == Brightness.dark
                        ? const Color(0xFF1C1816)
                        : const Color(0xFFFFFBF7))
                    .withOpacity(0.82),
                border: Border(
                  bottom: BorderSide(
                    color: (theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : CulinaryColors.flameOrange.withOpacity(0.18)),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: CulinaryColors.tandoorOrange,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                profile.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Dynamic Thermal Printer Connect Status Badge (More Compact)
          GestureDetector(
            onTap: () {
              NativeApiChannel.triggerNativeHaptic();
              posProvider.togglePrinterConnection();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    posProvider.isPrinterConnected
                        ? 'Thermal Printer Connected (${posProvider.printerName})'
                        : 'Thermal Printer Disconnected / Offline',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: posProvider.isPrinterConnected
                    ? CulinaryColors.emeraldGreen.withOpacity(0.12)
                    : theme.colorScheme.errorContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: posProvider.isPrinterConnected
                      ? CulinaryColors.emeraldGreen
                      : theme.colorScheme.error.withOpacity(0.6),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: posProvider.isPrinterConnected
                          ? CulinaryColors.emeraldGreen
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.print_rounded,
                    size: 13,
                    color: posProvider.isPrinterConnected
                        ? CulinaryColors.emeraldGreen
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    posProvider.isPrinterConnected ? '58mm' : 'Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: posProvider.isPrinterConnected
                          ? CulinaryColors.emeraldGreen
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Setup Wizard button (only visible if setup is not yet completed)
          if (!profile.isSetupCompleted)
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

          // Settings Action
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              NativeApiChannel.triggerNativeHaptic();
              widget.onNavigateTab(5);
            },
          ),

          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Circular Donut Sales Chart: Item Wise (Qty) vs Amount Wise (₹)
          _buildCircularSalesChart(theme, orderProvider, bestsellers),

          const SizedBox(height: 16),

          // Quick Action Banner: Sales & GST Tax Report
          GestureDetector(
            onTap: () {
              NativeApiChannel.triggerNativeHaptic();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesReportScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    CulinaryColors.flameOrange,
                    CulinaryColors.tandoorSpice,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CulinaryColors.flameOrange.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sales & GST Tax PDF Reports',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Monthly, Quarterly & Yearly statutory filing statements',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Dynamic Size, More Colorful Stat Cards
          Row(
            children: [
              Expanded(
                child: _buildVibrantStatCard(
                  theme: theme,
                  title: "Today's Gross Sales",
                  value: CurrencyFormatter.formatRupees(totalRevenue),
                  subtitle: completedBills > 0 ? '$completedBills bills settled' : 'No sales recorded yet',
                  icon: Icons.currency_rupee_rounded,
                  color: CulinaryColors.emeraldGreen,
                  gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
                  onTap: () => widget.onNavigateTab(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVibrantStatCard(
                  theme: theme,
                  title: 'Completed Orders',
                  value: '$completedBills Bills',
                  subtitle: '${orderProvider.activeOrders.length} active in kitchen',
                  icon: Icons.receipt_long_rounded,
                  color: CulinaryColors.flameOrange,
                  gradientColors: [const Color(0xFFEA580C), const Color(0xFFF97316)],
                  onTap: () => widget.onNavigateTab(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildVibrantStatCard(
                  theme: theme,
                  title: 'Avg Order Value (ATV)',
                  value: CurrencyFormatter.formatRupees(atv),
                  subtitle: completedBills > 0
                      ? '₹${totalRevenue.toStringAsFixed(0)} ÷ $completedBills bills'
                      : 'Waiting for orders',
                  icon: Icons.trending_up_rounded,
                  color: CulinaryColors.royalBlue,
                  gradientColors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                  onTap: () => widget.onNavigateTab(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildItemsSoldCard(
                  theme: theme,
                  orderProvider: orderProvider,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Payment Channel Breakdown Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Channel Distribution',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
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
                  const Divider(height: 18),
                  _buildPaymentRow(
                    context,
                    label: 'Cash Tender',
                    amount: orderProvider.paymentDistribution[PaymentMethod.cash] ?? 0.0,
                    icon: Icons.payments_rounded,
                    color: CulinaryColors.emeraldGreen,
                  ),
                  const Divider(height: 18),
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
        ],
      ),
    );
  }

  Widget _buildCircularSalesChart(
    ThemeData theme,
    OrderProvider orderProvider,
    List<dynamic> bestsellers,
  ) {
    // 5 completely distinct, vibrant colors for each dish segment
    final colors = [
      const Color(0xFFEA580C), // Vivid Tandoor Orange
      const Color(0xFF0284C7), // Royal Azure Blue
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFF8B5CF6), // Amethyst Violet
      const Color(0xFFF59E0B), // Warm Amber Gold
    ];

    final isItemWise = _chartMode == ChartMode.itemWise;
    final isHistory = _chartMode == ChartMode.history;

    // Aggregate real dynamic data directly from all completed/paid orders
    final Map<String, int> dishQuantities = {};
    final Map<String, double> dishRevenue = {};

    for (final order in orderProvider.orders) {
      if (order.status == OrderStatus.cancelled) continue;
      for (final item in order.items) {
        final name = item.menuItem.name;
        dishQuantities[name] = (dishQuantities[name] ?? 0) + item.quantity;
        dishRevenue[name] = (dishRevenue[name] ?? 0.0) + item.lineTotalRupees;
      }
    }

    final List<Map<String, dynamic>> chartData = [];

    if (isItemWise) {
      final sortedEntries = dishQuantities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sortedEntries.take(4).toList();
      final restCount = sortedEntries.skip(4).fold<int>(0, (sum, e) => sum + e.value);

      for (var i = 0; i < top.length; i++) {
        chartData.add({
          'label': top[i].key,
          'value': top[i].value.toDouble(),
          'color': colors[i % colors.length],
        });
      }
      if (restCount > 0) {
        chartData.add({
          'label': 'Other Dishes',
          'value': restCount.toDouble(),
          'color': colors[top.length % colors.length],
        });
      }
    } else if (!isHistory) {
      final sortedEntries = dishRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sortedEntries.take(4).toList();
      final restRevenue = sortedEntries.skip(4).fold<double>(0.0, (sum, e) => sum + e.value);

      for (var i = 0; i < top.length; i++) {
        chartData.add({
          'label': top[i].key,
          'value': top[i].value,
          'color': colors[i % colors.length],
        });
      }
      if (restRevenue > 0) {
        chartData.add({
          'label': 'Other Dishes',
          'value': restRevenue,
          'color': colors[top.length % colors.length],
        });
      }
    }

    final totalValue = chartData.fold<double>(0.0, (sum, d) => sum + (d['value'] as double));

    // Daily turnover history calculations for 7 days
    final now = DateTime.now();
    const weekdayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<Map<String, dynamic>> dailyHistory = [];
    double maxDailyRevenue = 0.0;
    double sevenDayRevenue = 0.0;
    int sevenDayBills = 0;

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final nextDay = day.add(const Duration(days: 1));

      final dayOrders = orderProvider.completedOrders.where((o) =>
          !o.createdAt.isBefore(day) && o.createdAt.isBefore(nextDay)).toList();

      final dayRevenue = dayOrders.fold<double>(0.0, (sum, o) => sum + o.totalRupees);
      if (dayRevenue > maxDailyRevenue) maxDailyRevenue = dayRevenue;
      sevenDayRevenue += dayRevenue;
      sevenDayBills += dayOrders.length;

      dailyHistory.add({
        'day': day,
        'label': i == 0 ? 'Today' : weekdayNames[day.weekday],
        'dateStr': '${day.day}/${day.month}',
        'orders': dayOrders.length,
        'revenue': dayRevenue,
      });
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHistory ? 'Sales History Trend' : 'Sales Distribution',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isHistory
                            ? 'Past 7 days turnover track'
                            : (isItemWise ? 'Quantity-wise item volume' : 'Revenue-wise turnover'),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildChartModePill(
                        theme: theme,
                        mode: ChartMode.itemWise,
                        icon: Icons.numbers_rounded,
                        label: 'Qty',
                      ),
                      _buildChartModePill(
                        theme: theme,
                        mode: ChartMode.amountWise,
                        icon: Icons.currency_rupee_rounded,
                        label: 'Amount',
                      ),
                      _buildChartModePill(
                        theme: theme,
                        mode: ChartMode.history,
                        icon: Icons.show_chart_rounded,
                        label: 'Trend',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isHistory) ...[
              _buildHistoryBarChart(theme, dailyHistory, maxDailyRevenue, sevenDayRevenue, sevenDayBills),
            ] else ...[
              Row(
              children: [
                // Circular Donut Chart
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 42,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedChartIndex = -1;
                                  return;
                                }
                                _touchedChartIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: chartData.isEmpty
                              ? [
                                  PieChartSectionData(
                                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                                    value: 1,
                                    title: '',
                                    radius: 20.0,
                                  ),
                                ]
                              : chartData.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final data = entry.value;
                                  final isTouched = idx == _touchedChartIndex;
                                  final radius = isTouched ? 30.0 : 24.0;
                                  return PieChartSectionData(
                                    color: data['color'] as Color,
                                    value: data['value'] as double,
                                    title: '',
                                    radius: radius,
                                  );
                                }).toList(),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 400),
                        swapAnimationCurve: Curves.easeInOutCubic,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              chartData.isEmpty
                                  ? '0'
                                  : (isItemWise
                                      ? totalValue.toInt().toString()
                                      : '₹${(totalValue / 1000).toStringAsFixed(1)}k'),
                              key: ValueKey<String>(chartData.isEmpty
                                  ? '0'
                                  : (isItemWise
                                      ? totalValue.toInt().toString()
                                      : '₹${(totalValue / 1000).toStringAsFixed(1)}k')),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            isItemWise ? 'Dishes' : 'Total Sales',
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: chartData.isEmpty
                        ? [
                            Center(
                              child: Text(
                                'No orders placed yet.\nStart taking orders in POS!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ]
                        : chartData.map((data) {
                      final pct = totalValue > 0 ? ((data['value'] as double) / totalValue * 100).toStringAsFixed(0) : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: data['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['label'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              isItemWise ? '${(data['value'] as double).toInt()} ($pct%)' : '₹${((data['value'] as double) / 1000).toStringAsFixed(1)}k ($pct%)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryBarChart(
    ThemeData theme,
    List<Map<String, dynamic>> dailyHistory,
    double maxDailyRevenue,
    double sevenDayRevenue,
    int sevenDayBills,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxDailyRevenue > 0 ? (maxDailyRevenue * 1.3) : 1000,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF261D19),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = dailyHistory[group.x.toInt()];
                    return BarTooltipItem(
                      '${item['label']} (${item['dateStr']})\n',
                      const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      children: [
                        TextSpan(
                          text: '₹${(item['revenue'] as double).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: CulinaryColors.flameOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: ' • ${item['orders']} bills',
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= dailyHistory.length) return const SizedBox.shrink();
                      final item = dailyHistory[idx];
                      final isToday = idx == dailyHistory.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                            color: isToday ? CulinaryColors.flameOrange : theme.colorScheme.outline,
                          ),
                        ),
                      );
                    },
                    reservedSize: 22,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      if (val >= 1000) {
                        return Text(
                          '₹${(val / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(fontSize: 9, color: theme.colorScheme.outline),
                        );
                      }
                      return Text(
                        '₹${val.toInt()}',
                        style: TextStyle(fontSize: 9, color: theme.colorScheme.outline),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.25),
                  strokeWidth: 0.8,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: dailyHistory.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final revenue = item['revenue'] as double;
                final isToday = idx == dailyHistory.length - 1;

                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: revenue,
                      gradient: LinearGradient(
                        colors: isToday
                            ? [CulinaryColors.flameOrange, CulinaryColors.tandoorSpice]
                            : [CulinaryColors.royalBlue, const Color(0xFF38BDF8)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxDailyRevenue > 0 ? (maxDailyRevenue * 1.15) : 1000,
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 7-day stats summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHistoryStatCol('7-Day Total', '₹${sevenDayRevenue.toStringAsFixed(0)}', CulinaryColors.flameOrange),
              Container(width: 1, height: 24, color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              _buildHistoryStatCol('Daily Average', '₹${(sevenDayRevenue / 7).toStringAsFixed(0)}', CulinaryColors.royalBlue),
              Container(width: 1, height: 24, color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              _buildHistoryStatCol('Settled Bills', '$sevenDayBills paid', CulinaryColors.emeraldGreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartModePill({
    required ThemeData theme,
    required ChartMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _chartMode == mode;
    return GestureDetector(
      onTap: () {
        if (_chartMode != mode) {
          NativeApiChannel.triggerNativeHaptic();
          setState(() => _chartMode = mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            const SizedBox(width: 2.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStatCol(String title, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildVibrantStatCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.colorScheme.outlineVariant),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          CurrencyFormatter.formatRupees(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSoldCard({
    required ThemeData theme,
    required OrderProvider orderProvider,
  }) {
    final int itemsCount;
    final String intervalLabel;
    switch (_itemsInterval) {
      case ItemsSoldInterval.today:
        itemsCount = orderProvider.itemsSoldToday;
        intervalLabel = "Today's";
        break;
      case ItemsSoldInterval.weekly:
        itemsCount = orderProvider.itemsSoldThisWeek;
        intervalLabel = "Weekly";
        break;
      case ItemsSoldInterval.monthly:
        itemsCount = orderProvider.itemsSoldThisMonth;
        intervalLabel = "Monthly";
        break;
    }

    const color = CulinaryColors.amethystViolet;
    const gradientColors = [Color(0xFF8B5CF6), Color(0xFFA855F7)];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lunch_dining_rounded, size: 16, color: Colors.white),
                ),
                // Compact Pill Selector for Today / Week / Month
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIntervalChip('Today', ItemsSoldInterval.today, color),
                      _buildIntervalChip('Week', ItemsSoldInterval.weekly, color),
                      _buildIntervalChip('Month', ItemsSoldInterval.monthly, color),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$itemsCount Items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$intervalLabel Items Sold',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalChip(String label, ItemsSoldInterval interval, Color activeColor) {
    final isSelected = _itemsInterval == interval;
    return GestureDetector(
      onTap: () {
        NativeApiChannel.triggerNativeHaptic();
        setState(() => _itemsInterval = interval);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : activeColor,
          ),
        ),
      ),
    );
  }
}
