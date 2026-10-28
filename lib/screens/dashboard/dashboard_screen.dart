import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pos_provider.dart';
import '../../widgets/dietary_badge.dart';
import '../reports/sales_report_screen.dart';
import '../setup/setup_wizard_screen.dart';

enum ChartMode { itemWise, amountWise }
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
    final orderCount = orderProvider.orderCount;
    final atv = orderProvider.averageTicketValueRupees;
    final bestsellers = menuProvider.topSellingItems;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: 74,
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Full Restaurant Name (No truncation)
              Text(
                profile.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: CulinaryColors.tandoorOrange,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              // Restaurant Tagline (Clean, FSSAI removed as requested)
              Text(
                profile.tagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        actions: [
          // Dynamic Thermal Printer Connect Status Badge
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
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: posProvider.isPrinterConnected
                    ? CulinaryColors.emeraldGreen.withOpacity(0.12)
                    : theme.colorScheme.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: posProvider.isPrinterConnected
                      ? CulinaryColors.emeraldGreen
                      : theme.colorScheme.error,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: posProvider.isPrinterConnected
                          ? CulinaryColors.emeraldGreen
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.print_rounded,
                    size: 15,
                    color: posProvider.isPrinterConnected
                        ? CulinaryColors.emeraldGreen
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    posProvider.isPrinterConnected ? '58mm Online' : 'Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
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
              widget.onNavigateTab(4);
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
                  subtitle: '+18.4% vs yesterday',
                  icon: Icons.currency_rupee_rounded,
                  color: CulinaryColors.emeraldGreen,
                  gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
                  onTap: () => widget.onNavigateTab(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVibrantStatCard(
                  theme: theme,
                  title: 'Completed Orders',
                  value: '$orderCount Bills',
                  subtitle: '${orderProvider.activeOrders.length} active in kitchen',
                  icon: Icons.receipt_long_rounded,
                  color: CulinaryColors.flameOrange,
                  gradientColors: [const Color(0xFFEA580C), const Color(0xFFF97316)],
                  onTap: () => widget.onNavigateTab(3),
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
                  subtitle: 'High dining ticket',
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

          const SizedBox(height: 24),

          // Top Selling Dishes Horizontal Carousel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              TextButton(
                onPressed: () {
                  posProvider.selectCategory(-1); // Switch to Bestsellers
                  widget.onNavigateTab(1); // Go to POS
                },
                child: const Text('View All'),
              ),
            ],
          ),

          const SizedBox(height: 10),

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
                  width: 156,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        posProvider.addToCart(item);
                        NativeApiChannel.triggerNativeHaptic();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added to cart!'),
                            duration: const Duration(milliseconds: 1200),
                            action: SnackBarAction(
                              label: 'View Cart',
                              onPressed: () => widget.onNavigateTab(1),
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              if (item.imageUri != null)
                                Image.asset(
                                  item.imageUri!,
                                  height: 96,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 96,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.restaurant_rounded),
                                  ),
                                )
                              else
                                Container(
                                  height: 96,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.restaurant_rounded),
                                ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: rankColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#$rank',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
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
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
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
                                        padding: const EdgeInsets.all(3),
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
    // 5 completely distinct, vibrant colors for each dish
    final colors = [
      const Color(0xFFEA580C), // Vivid Tandoor Orange (Butter Chicken)
      const Color(0xFF0284C7), // Royal Azure Blue (Chicken Biryani)
      const Color(0xFF10B981), // Emerald Green (Paneer Butter)
      const Color(0xFF8B5CF6), // Amethyst Violet (Butter Naan)
      const Color(0xFFF59E0B), // Warm Amber Gold (Others & Drinks)
    ];

    final isItemWise = _chartMode == ChartMode.itemWise;

    final List<Map<String, dynamic>> chartData = isItemWise
        ? [
            {'label': 'Chicken Biryani', 'value': 198.0, 'color': colors[0]},
            {'label': 'Butter Naan', 'value': 189.0, 'color': colors[1]},
            {'label': 'Butter Chicken', 'value': 165.0, 'color': colors[2]},
            {'label': 'Masala Chai', 'value': 142.0, 'color': colors[3]},
            {'label': 'Paneer Tikka', 'value': 118.0, 'color': colors[4]},
          ]
        : [
            {'label': 'Butter Chicken', 'value': 62700.0, 'color': colors[0]},
            {'label': 'Chicken Biryani', 'value': 67320.0, 'color': colors[1]},
            {'label': 'Paneer Butter', 'value': 41850.0, 'color': colors[2]},
            {'label': 'Butter Naan', 'value': 10395.0, 'color': colors[3]},
            {'label': 'Others & Drinks', 'value': 18500.0, 'color': colors[4]},
          ];

    final totalValue = chartData.fold<double>(0.0, (sum, d) => sum + (d['value'] as double));

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
                        'Sales Distribution',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isItemWise ? 'Quantity-wise item volume' : 'Revenue-wise turnover',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<ChartMode>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ChartMode.itemWise,
                      label: Text('Qty'),
                      icon: Icon(Icons.numbers_rounded, size: 14),
                    ),
                    ButtonSegment(
                      value: ChartMode.amountWise,
                      label: Text('₹ Amount'),
                      icon: Icon(Icons.currency_rupee_rounded, size: 14),
                    ),
                  ],
                  selected: {_chartMode},
                  onSelectionChanged: (set) {
                    setState(() => _chartMode = set.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          sections: chartData.asMap().entries.map((entry) {
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
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isItemWise ? totalValue.toInt().toString() : '₹${(totalValue / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: chartData.map((data) {
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
        ),
      ),
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
