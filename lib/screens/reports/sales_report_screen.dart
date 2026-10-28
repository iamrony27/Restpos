import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/theme/color_schemes.dart';
import '../../core/utils/app_notification.dart';
import '../../models/order_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/report_pdf_service.dart';

enum ReportPeriodType { monthly, quarterly, yearly }

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);
  ReportPeriodType _periodType = ReportPeriodType.monthly;
  late String _selectedPeriod;
  bool _isGeneratingPdf = false;
  late Map<ReportPeriodType, List<String>> _periodOptions;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final curMonth = DateFormat('MMMM yyyy').format(now);
    final prevMonth1 = DateFormat('MMMM yyyy').format(DateTime(now.year, now.month - 1, 1));
    final prevMonth2 = DateFormat('MMMM yyyy').format(DateTime(now.year, now.month - 2, 1));
    final curQuarter = ((now.month - 1) ~/ 3) + 1;
    final prevQuarter = curQuarter == 1 ? 4 : curQuarter - 1;
    final prevQuarterYear = curQuarter == 1 ? now.year - 1 : now.year;
    final curFyStart = now.month >= 4 ? now.year : now.year - 1;

    _periodOptions = {
      ReportPeriodType.monthly: [
        curMonth,
        'All Orders (Lifetime)',
        'Today',
        prevMonth1,
        prevMonth2,
      ],
      ReportPeriodType.quarterly: [
        'Q$curQuarter ${now.year} (Current)',
        'Q$prevQuarter $prevQuarterYear (Previous)',
      ],
      ReportPeriodType.yearly: [
        'FY $curFyStart-${(curFyStart + 1).toString().substring(2)} (Current)',
        'All Time (Complete History)',
      ],
    };
    _selectedPeriod = curMonth;

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      if (offset >= 0 && offset <= 80) {
        _scrollOffset.value = offset;
      } else if (offset > 80 && _scrollOffset.value != 80) {
        _scrollOffset.value = 80;
      } else if (offset < 0 && _scrollOffset.value != 0) {
        _scrollOffset.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onPeriodTypeChanged(ReportPeriodType type) {
    setState(() {
      _periodType = type;
      _selectedPeriod = _periodOptions[type]!.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pos = context.watch<PosProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final profile = pos.profile;
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    // Compute genuine aggregate figures directly from completed/paid bills
    final allOrders = orderProvider.completedOrders;

    List<Order> filteredOrders;
    if (_selectedPeriod.contains('All Orders') || _selectedPeriod.contains('All Time')) {
      filteredOrders = allOrders;
    } else if (_selectedPeriod == 'Today') {
      final now = DateTime.now();
      filteredOrders = allOrders.where((o) =>
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day).toList();
    } else if (_periodType == ReportPeriodType.monthly) {
      filteredOrders = allOrders.where((o) =>
          DateFormat('MMMM yyyy').format(o.createdAt) == _selectedPeriod).toList();
    } else if (_periodType == ReportPeriodType.quarterly) {
      filteredOrders = allOrders.where((o) {
        final q = ((o.createdAt.month - 1) ~/ 3) + 1;
        return _selectedPeriod.contains('Q$q ${o.createdAt.year}');
      }).toList();
    } else {
      // Yearly (Indian Financial Year: 1 Apr - 31 Mar)
      final now = DateTime.now();
      final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
      final fyStart = DateTime(fyStartYear, 4, 1);
      final fyEnd = DateTime(fyStartYear + 1, 3, 31, 23, 59, 59);
      if (_selectedPeriod.contains('Current')) {
        filteredOrders = allOrders.where((o) =>
            o.createdAt.isAfter(fyStart.subtract(const Duration(seconds: 1))) &&
            o.createdAt.isBefore(fyEnd)).toList();
      } else {
        filteredOrders = allOrders;
      }
    }

    final int orderCount = filteredOrders.length;
    final double grossSales = filteredOrders.fold(0, (sum, o) => sum + o.subtotalPaise) / 100.0;
    final double taxableBase = filteredOrders.fold(0, (sum, o) => sum + o.taxableBasePaise) / 100.0;
    final double totalGst = filteredOrders.fold(0, (sum, o) => sum + o.taxPaise) / 100.0;
    final double cgst = filteredOrders.fold(0.0, (sum, o) => sum + o.cgstRupees);
    final double sgst = filteredOrders.fold(0.0, (sum, o) => sum + o.sgstRupees);
    final double roundOff = filteredOrders.fold(0, (sum, o) => sum + o.roundOffPaise) / 100.0;
    final double netRevenue = filteredOrders.fold(0, (sum, o) => sum + o.totalPaise) / 100.0;

    final Map<String, double> paymentBreakdown = {};
    for (final o in filteredOrders) {
      final method = o.paymentMethod ?? PaymentMethod.cash;
      final String label;
      switch (method) {
        case PaymentMethod.upi:
          label = 'UPI (Bharat QR / GPay)';
          break;
        case PaymentMethod.card:
          label = 'Debit / Credit Cards';
          break;
        case PaymentMethod.cash:
          label = 'Cash Tender';
          break;
        case PaymentMethod.credit:
          label = 'Customer Credit (Khata)';
          break;
      }
      paymentBreakdown[label] = (paymentBreakdown[label] ?? 0.0) + o.totalRupees;
    }
    if (paymentBreakdown.isEmpty) {
      paymentBreakdown['Cash Tender'] = 0.0;
    }

    final Map<String, double> categoryBreakdown = {};
    for (final o in filteredOrders) {
      for (final item in o.items) {
        final cat = menuProvider.categories.where((c) => c.id == item.menuItem.categoryId).firstOrNull;
        final catName = cat?.name ?? 'Main Course';
        categoryBreakdown[catName] = (categoryBreakdown[catName] ?? 0.0) + item.lineTotalRupees;
      }
    }
    if (categoryBreakdown.isEmpty) {
      categoryBreakdown['All Categories'] = 0.0;
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _scrollOffset,
          builder: (context, _) {
            final double scrollProgress = (_scrollOffset.value / 80.0).clamp(0.0, 1.0);
            final appBarBg = Color.lerp(
              theme.colorScheme.surface,
              CulinaryColors.flameOrange,
              scrollProgress,
            );
            final appBarFg = Color.lerp(
              theme.colorScheme.onSurface,
              Colors.white,
              scrollProgress,
            );

            return AppBar(
              title: Text(
                'Sales & GST Reports',
                style: TextStyle(
                  color: appBarFg,
                  fontWeight: FontWeight.w800,
                ),
              ),
              centerTitle: false,
              backgroundColor: appBarBg,
              foregroundColor: appBarFg,
              elevation: scrollProgress * 4.0,
              actions: [
                IconButton(
                  icon: Icon(Icons.share_rounded, color: appBarFg),
                  tooltip: 'Export & Share PDF',
                  onPressed: () => _exportPdf(
                    pos: pos,
                    grossSales: grossSales,
                    taxableBase: taxableBase,
                    cgst: cgst,
                    sgst: sgst,
                    totalGst: totalGst,
                    roundOff: roundOff,
                    netRevenue: netRevenue,
                    orderCount: orderCount,
                    paymentBreakdown: paymentBreakdown,
                    categoryBreakdown: categoryBreakdown,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Header Card with GST & FSSAI Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  CulinaryColors.flameOrange,
                  CulinaryColors.tandoorSpice,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: CulinaryColors.flameOrange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        profile.isGstEnabled
                            ? 'GST: ${profile.gstRatePercent}%'
                            : 'NON-GST',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'FSSAI Lic: ${profile.fssai} • GSTIN: ${profile.isGstEnabled ? profile.gstin : "Exempt"}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        profile.isTaxInclusive ? 'Tax Mode: Inclusive (Tax in Price)' : 'Tax Mode: Exclusive (Tax Added)',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Period Selector: Monthly / Quarterly / Yearly
          SegmentedButton<ReportPeriodType>(
            segments: const [
              ButtonSegment(
                value: ReportPeriodType.monthly,
                label: Text('Monthly'),
                icon: Icon(Icons.calendar_month_rounded, size: 16),
              ),
              ButtonSegment(
                value: ReportPeriodType.quarterly,
                label: Text('Quarterly'),
                icon: Icon(Icons.event_note_rounded, size: 16),
              ),
              ButtonSegment(
                value: ReportPeriodType.yearly,
                label: Text('Yearly'),
                icon: Icon(Icons.date_range_rounded, size: 16),
              ),
            ],
            selected: {_periodType},
            onSelectionChanged: (set) => _onPeriodTypeChanged(set.first),
          ),

          const SizedBox(height: 12),

          // Dropdown for period choice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timelapse_rounded, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Report Interval:',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      isExpanded: true,
                      items: _periodOptions[_periodType]!.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item, style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPeriod = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Financial KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme: theme,
                  title: 'Gross Turnover',
                  value: currencyFormatter.format(grossSales),
                  subtitle: '$orderCount Invoices Billed',
                  color: CulinaryColors.royalBlue,
                  icon: Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  theme: theme,
                  title: 'Taxable Base',
                  value: currencyFormatter.format(taxableBase),
                  subtitle: profile.isGstEnabled ? 'Before GST' : 'Zero Rated',
                  color: CulinaryColors.emeraldGreen,
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme: theme,
                  title: 'Total GST Tax',
                  value: currencyFormatter.format(totalGst),
                  subtitle: profile.isGstEnabled
                      ? 'CGST: ${currencyFormatter.format(cgst)} | SGST: ${currencyFormatter.format(sgst)}'
                      : 'Non-GST Status',
                  color: CulinaryColors.tandoorSpice,
                  icon: Icons.account_balance_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  theme: theme,
                  title: 'Net Realized',
                  value: currencyFormatter.format(netRevenue),
                  subtitle: 'Settled to Bank',
                  color: CulinaryColors.amethystViolet,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tax Breakdown Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Statutory GST Tax Audit',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CulinaryColors.emeraldGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          profile.isGstEnabled ? 'CGST + SGST Reconciled' : 'Exempt',
                          style: const TextStyle(
                            color: CulinaryColors.emeraldGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow('Gross Revenue', currencyFormatter.format(grossSales)),
                  _buildSummaryRow('Taxable Turnover (Base)', currencyFormatter.format(taxableBase)),
                  if (profile.isGstEnabled) ...[
                    _buildSummaryRow('Central GST (CGST @ ${profile.gstRatePercent / 2}%)', currencyFormatter.format(cgst)),
                    _buildSummaryRow('State GST (SGST @ ${profile.gstRatePercent / 2}%)', currencyFormatter.format(sgst)),
                    _buildSummaryRow(
                      'Total GST Tax Collected',
                      currencyFormatter.format(totalGst),
                      isBold: true,
                      color: CulinaryColors.tandoorSpice,
                    ),
                  ],
                  _buildSummaryRow('Round-Off Adjustments', '±${currencyFormatter.format(roundOff)}'),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    'Net Settled Revenue',
                    currencyFormatter.format(netRevenue),
                    isBold: true,
                    fontSize: 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Primary Export PDF Button
          BouncingButton(
            onPressed: _isGeneratingPdf
                ? () {}
                : () => _exportPdf(
                      pos: pos,
                      grossSales: grossSales,
                      taxableBase: taxableBase,
                      cgst: cgst,
                      sgst: sgst,
                      totalGst: totalGst,
                      roundOff: roundOff,
                      netRevenue: netRevenue,
                      orderCount: orderCount,
                      paymentBreakdown: paymentBreakdown,
                      categoryBreakdown: categoryBreakdown,
                    ),
            child: Container(
              height: 54,
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
                    color: CulinaryColors.flameOrange.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _isGeneratingPdf
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Synthesizing Official PDF...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Generate & Print GST PDF Report',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf({
    required PosProvider pos,
    required double grossSales,
    required double taxableBase,
    required double cgst,
    required double sgst,
    required double totalGst,
    required double roundOff,
    required double netRevenue,
    required int orderCount,
    required Map<String, double> paymentBreakdown,
    required Map<String, double> categoryBreakdown,
  }) async {
    setState(() => _isGeneratingPdf = true);
    NativeApiChannel.triggerNativeHaptic();

    try {
      final periodTypeStr = _periodType == ReportPeriodType.monthly
          ? 'Monthly'
          : (_periodType == ReportPeriodType.quarterly ? 'Quarterly' : 'Yearly');

      await ReportPdfService.printOrShareReport(
        profile: pos.profile,
        periodType: periodTypeStr,
        periodName: _selectedPeriod,
        totalOrders: orderCount,
        grossSalesRupees: grossSales,
        taxableBaseRupees: taxableBase,
        cgstRupees: cgst,
        sgstRupees: sgst,
        totalGstRupees: totalGst,
        roundOffRupees: roundOff,
        netRevenueRupees: netRevenue,
        isTaxInclusive: pos.profile.isTaxInclusive,
        categorySales: categoryBreakdown,
        paymentBreakdown: paymentBreakdown,
      );
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'PDF generation notice: $e',
          title: 'Report Notice',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }
}
