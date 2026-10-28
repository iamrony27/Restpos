import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/channels/native_api_channel.dart';
import '../core/theme/color_schemes.dart';
import '../core/utils/app_notification.dart';
import '../models/order_model.dart';
import '../models/restaurant_profile.dart';
import '../providers/pos_provider.dart';

/// Interactive modal dialog displaying an authentic ESC/POS thermal receipt preview
/// before the receipt is dispatched to physical or Bluetooth thermal printers.
class ThermalSlipPreviewDialog extends StatefulWidget {
  final Order? order;
  final RestaurantProfile? profile;
  final String? customReceiptText;
  final String? title;
  final PaymentMethod? paymentMethod;
  final double? cashTendered;
  final double? changeDue;
  final VoidCallback? onPrintConfirmed;

  const ThermalSlipPreviewDialog({
    super.key,
    this.order,
    this.profile,
    this.customReceiptText,
    this.title,
    this.paymentMethod,
    this.cashTendered,
    this.changeDue,
    this.onPrintConfirmed,
  });

  /// Convenient static helper to show the dialog
  static Future<bool?> show(
    BuildContext context, {
    Order? order,
    RestaurantProfile? profile,
    String? customReceiptText,
    String? title,
    PaymentMethod? paymentMethod,
    double? cashTendered,
    double? changeDue,
    VoidCallback? onPrintConfirmed,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ThermalSlipPreviewDialog(
        order: order,
        profile: profile,
        customReceiptText: customReceiptText,
        title: title,
        paymentMethod: paymentMethod,
        cashTendered: cashTendered,
        changeDue: changeDue,
        onPrintConfirmed: onPrintConfirmed,
      ),
    );
  }

  @override
  State<ThermalSlipPreviewDialog> createState() => _ThermalSlipPreviewDialogState();
}

class _ThermalSlipPreviewDialogState extends State<ThermalSlipPreviewDialog> {
  bool _is80mm = false; // false = 58mm (default standard POS), true = 80mm
  bool _isPrinting = false;

  String _buildEscPosPayload(RestaurantProfile profile) {
    if (widget.customReceiptText != null) {
      return widget.customReceiptText!;
    }

    final order = widget.order;
    if (order == null) return '';

    final isInclusive = order.isTaxInclusive && order.taxBps > 0;
    final taxableLabel = isInclusive ? 'Taxable Base' : 'Subtotal';
    final taxableAmount = isInclusive ? order.taxableBaseRupees : order.subtotalRupees;
    final taxTreatment = order.isTaxInclusive ? 'Incl. in Price' : 'Added at checkout';
    final gstLine = order.taxBps > 0
        ? 'GST (${(order.taxBps / 100).toStringAsFixed(1)}% - $taxTreatment): ₹${order.taxRupees.toStringAsFixed(2)}\n'
          '  (CGST: ₹${order.cgstRupees.toStringAsFixed(2)} + SGST: ₹${order.sgstRupees.toStringAsFixed(2)})'
        : 'Tax: ₹0.00 (Non-GST / Exempt)';

    final discountLine = order.discountPaise > 0
        ? 'Discount: -₹${order.discountRupees.toStringAsFixed(2)}\n'
        : '';
    final roundOffLine = order.roundOffPaise != 0
        ? 'Round Off: ${order.roundOffPaise > 0 ? "+" : ""}₹${order.roundOffRupees.toStringAsFixed(2)}\n'
        : '';

    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(order.createdAt);
    final pMethod = widget.paymentMethod ?? order.paymentMethod ?? PaymentMethod.cash;

    return '''
================================
     ${profile.name.toUpperCase()}
   ${profile.tagline}
   ${profile.address}
   Ph: ${profile.phone}
--------------------------------
FSSAI Lic: ${profile.fssai.isNotEmpty ? profile.fssai : "11223344556677"}
GSTIN: ${profile.isGstEnabled ? profile.gstin : "Exempt / Non-GST"}
Order #${order.orderNumber}
Date: $dateStr
Type: ${order.type == OrderType.dineIn ? (order.tableName ?? 'Dine-In') : (order.type == OrderType.takeaway ? 'Takeaway' : 'Delivery')}
Cashier: Counter POS-1
--------------------------------
QTY  ITEM                  TOTAL
--------------------------------
${order.items.map((i) {
      final name = i.menuItem.name.padRight(18).substring(0, 18);
      return '${i.quantity}x  $name ₹${i.lineTotalRupees.toStringAsFixed(0)}';
    }).join('\n')}
--------------------------------
$taxableLabel: ₹${taxableAmount.toStringAsFixed(2)}
$gstLine
$discountLine${roundOffLine}GRAND TOTAL: ₹${order.totalRupees.toStringAsFixed(0)}
Payment Mode: ${pMethod.name.toUpperCase()}
================================
     Thank You! Visit Again.
     Powered by RestPos POS
================================
''';
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final effectiveProfile = widget.profile ?? posProvider.profile;
    final payload = _buildEscPosPayload(effectiveProfile);

    await NativeApiChannel.printReceiptNative(receiptText: payload);
    await NativeApiChannel.triggerNativeHaptic(type: 'click');

    if (mounted) {
      setState(() => _isPrinting = false);
      widget.onPrintConfirmed?.call();
      Navigator.of(context).pop(true);
      AppNotification.showSuccess(
        context,
        widget.order != null
            ? 'Thermal slip printed for Order #${widget.order!.orderNumber}'
            : 'Test thermal slip dispatched to printer!',
        title: 'Thermal Print Dispatched',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posProvider = Provider.of<PosProvider>(context);
    final effectiveProfile = widget.profile ?? posProvider.profile;
    final order = widget.order;
    final paperWidth = _is80mm ? 360.0 : 300.0;
    final pMethod = widget.paymentMethod ?? order?.paymentMethod ?? PaymentMethod.cash;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title ?? 'Thermal Slip Preview',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Realistic ESC/POS Roll Simulation',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Width Toggle (58mm vs 80mm)
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildWidthToggleChip('58mm', !_is80mm, () {
                            if (_is80mm) setState(() => _is80mm = false);
                          }),
                          _buildWidthToggleChip('80mm', _is80mm, () {
                            if (!_is80mm) setState(() => _is80mm = true);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(false),
                      tooltip: 'Close Preview',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // Scrollable Thermal Receipt Sheet
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Center(
                    child: Container(
                      width: paperWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF8), // Authentic off-white thermal paper
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Jagged Tear Edge
                          CustomPaint(
                            size: Size(paperWidth, 10),
                            painter: _ReceiptTearPainter(isTop: true),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: widget.customReceiptText != null && widget.order == null
                                ? _buildCustomTextReceipt(widget.customReceiptText!)
                                : _buildDynamicOrderReceipt(effectiveProfile, order!, pMethod),
                          ),

                          // Bottom Jagged Tear Edge
                          CustomPaint(
                            size: Size(paperWidth, 10),
                            painter: _ReceiptTearPainter(isTop: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel / Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: _isPrinting ? null : _handlePrint,
                        icon: _isPrinting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.print_rounded, size: 20),
                        label: Text(
                          _isPrinting ? 'Printing...' : 'Print Slip 🖨️',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: CulinaryColors.emeraldGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWidthToggleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextReceipt(String rawText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(
          rawText.trim(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.35,
            color: Color(0xFF1E1E1E),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicOrderReceipt(RestaurantProfile profile, Order order, PaymentMethod pMethod) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt);
    final upiPayload = 'upi://pay?pa=${profile.upiId}&pn=${Uri.encodeComponent(profile.name)}&am=${order.totalRupees.toStringAsFixed(2)}&cu=INR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store Header
        Text(
          profile.name.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.8,
            color: Color(0xFF111827),
          ),
        ),
        if (profile.tagline.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            profile.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Color(0xFF374151),
            ),
          ),
        ],
        if (profile.address.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            profile.address,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
        if (profile.phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Ph: ${profile.phone}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Color(0xFF4B5563),
            ),
          ),
        ],

        const SizedBox(height: 6),
        _buildDashedSeparator(),
        const SizedBox(height: 6),

        // Compliance & Bill Details
        _buildMetaRow('FSSAI Lic', profile.fssai.isNotEmpty ? profile.fssai : '11223344556677'),
        _buildMetaRow('GSTIN', profile.isGstEnabled ? profile.gstin : 'Non-GST / Exempt'),
        _buildMetaRow('Bill No', '#${order.orderNumber}', isBoldValue: true),
        _buildMetaRow('Date', formattedDate),
        _buildMetaRow(
          'Order Type',
          order.type == OrderType.dineIn
              ? 'Dine-In (${order.tableName ?? 'Table'})'
              : (order.type == OrderType.takeaway ? 'Takeaway' : 'Delivery'),
        ),
        _buildMetaRow('Cashier', 'POS Counter 01'),

        const SizedBox(height: 6),
        _buildDashedSeparator(),
        const SizedBox(height: 4),

        // Table Header
        const Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                'QTY',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'ITEM',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Text(
              'AMOUNT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildDashedSeparator(),
        const SizedBox(height: 6),

        // Items List
        ...order.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.menuItem.name,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Text(
                      '₹${item.lineTotalRupees.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 1),
                    child: Text(
                      '(${item.notes})',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 4),
        _buildDashedSeparator(),
        const SizedBox(height: 6),

        // Financial Breakdown
        if (order.isTaxInclusive && order.taxBps > 0) ...[
          _buildAmountRow('Taxable Base (Net)', '₹${order.taxableBaseRupees.toStringAsFixed(2)}'),
          _buildAmountRow(
            'CGST (${(order.taxBps / 200).toStringAsFixed(1)}%) [Incl]',
            '₹${order.cgstRupees.toStringAsFixed(2)}',
          ),
          _buildAmountRow(
            'SGST (${(order.taxBps / 200).toStringAsFixed(1)}%) [Incl]',
            '₹${order.sgstRupees.toStringAsFixed(2)}',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 2),
            child: Text(
              '*(Taxes included in menu prices)',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontStyle: FontStyle.italic,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ] else ...[
          _buildAmountRow('Subtotal', '₹${order.subtotalRupees.toStringAsFixed(2)}'),
          if (order.taxBps > 0) ...[
            _buildAmountRow(
              'CGST (${(order.taxBps / 200).toStringAsFixed(1)}%)',
              '₹${order.cgstRupees.toStringAsFixed(2)}',
            ),
            _buildAmountRow(
              'SGST (${(order.taxBps / 200).toStringAsFixed(1)}%)',
              '₹${order.sgstRupees.toStringAsFixed(2)}',
            ),
          ] else ...[
            _buildAmountRow('Tax (Exempt)', '₹0.00'),
          ],
        ],

        if (order.discountPaise > 0)
          _buildAmountRow(
            'Discount',
            '-₹${order.discountRupees.toStringAsFixed(2)}',
            isDiscount: true,
          ),

        if (order.roundOffPaise != 0)
          _buildAmountRow(
            'Round Off',
            '${order.roundOffPaise > 0 ? "+" : ""}₹${order.roundOffRupees.toStringAsFixed(2)}',
          ),

        const SizedBox(height: 6),
        _buildDoubleDashedSeparator(),
        const SizedBox(height: 6),

        // Grand Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'GRAND TOTAL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              '₹${order.totalRupees.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),
        _buildDoubleDashedSeparator(),
        const SizedBox(height: 6),

        // Payment Info
        _buildMetaRow('Payment Mode', pMethod.name.toUpperCase(), isBoldValue: true),

        if (pMethod == PaymentMethod.cash && widget.cashTendered != null && widget.cashTendered! > 0) ...[
          _buildMetaRow('Tendered', '₹${widget.cashTendered!.toStringAsFixed(2)}'),
          _buildMetaRow(
            'Change Due',
            '₹${(widget.changeDue ?? (widget.cashTendered! - order.totalRupees)).clamp(0, double.infinity).toStringAsFixed(2)}',
            isBoldValue: true,
          ),
        ],

        // Dynamic UPI QR Code for quick scan & verification
        if (profile.upiId.isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: upiPayload,
                    version: QrVersions.auto,
                    size: 96.0,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan to Pay / Verify UPI',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    profile.upiId,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),
        _buildDashedSeparator(),
        const SizedBox(height: 8),

        // Footer Note
        const Text(
          '*** THANK YOU! VISIT AGAIN ***',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
            letterSpacing: 0.5,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Fast & Offline POS by RestPos',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8.5,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Color(0xFF4B5563),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: isBoldValue ? FontWeight.w800 : FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: Color(0xFF374151),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDiscount ? const Color(0xFFDC2626) : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedSeparator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF9CA3AF)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDoubleDashedSeparator() {
    return Column(
      children: [
        _buildDashedSeparator(),
        const SizedBox(height: 2),
        _buildDashedSeparator(),
      ],
    );
  }
}

/// Custom painter for jagged / zig-zag thermal paper roll cut edge
class _ReceiptTearPainter extends CustomPainter {
  final bool isTop;

  _ReceiptTearPainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFDF8)
      ..style = PaintingStyle.fill;

    final path = Path();
    const toothWidth = 8.0;
    const toothHeight = 4.0;
    final teethCount = (size.width / toothWidth).ceil();

    if (isTop) {
      path.moveTo(0, size.height);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, size.height - toothHeight);
        path.lineTo((i + 1) * toothWidth, size.height);
      }
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, toothHeight);
        path.lineTo((i + 1) * toothWidth, 0);
      }
      path.lineTo(size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReceiptTearPainter oldDelegate) => false;
}
