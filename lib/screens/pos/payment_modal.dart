import 'package:flutter/material.dart';
import '../../core/animations/bouncing_button.dart';
import '../../core/channels/native_api_channel.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../widgets/upi_qr_widget.dart';

class PaymentModal extends StatefulWidget {
  final Order order;
  final VoidCallback onPaymentConfirmed;

  const PaymentModal({
    super.key,
    required this.order,
    required this.onPaymentConfirmed,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  double _cashTendered = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cashTendered = widget.order.totalRupees;
  }

  void _addCashTender(double amount) {
    NativeApiChannel.triggerNativeHaptic();
    setState(() {
      _cashTendered += amount;
    });
  }

  Future<void> _completePayment() async {
    setState(() => _isProcessing = true);

    // Call native Android thermal print hook
    final receiptPayload = '''
    SPICE GARDEN RESTAURANT
    Order #${widget.order.orderNumber}
    ${widget.order.type == OrderType.dineIn ? widget.order.tableName ?? 'Dine-In' : 'Takeaway'}
    --------------------------------
    ${widget.order.items.map((i) => '${i.quantity}x ${i.menuItem.name} - ₹${i.lineTotalRupees.toStringAsFixed(0)}').join('\n')}
    --------------------------------
    Subtotal: ₹${widget.order.subtotalRupees.toStringAsFixed(0)}
    GST (5%): ₹${widget.order.taxRupees.toStringAsFixed(0)}
    TOTAL: ₹${widget.order.totalRupees.toStringAsFixed(0)}
    Payment: ${_selectedMethod.name.toUpperCase()}
    --------------------------------
    Thank You! Visit Again.
    ''';

    await NativeApiChannel.printReceiptNative(receiptText: receiptPayload);
    await NativeApiChannel.triggerNativeHaptic(type: 'click');

    if (mounted) {
      widget.onPaymentConfirmed();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment confirmed! Receipt printed for ${widget.order.orderNumber}'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRupees = widget.order.totalRupees;
    final changeDue = (_cashTendered - totalRupees).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Settlement',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${widget.order.orderNumber} • ${widget.order.items.length} items',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatRupees(totalRupees),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Payment Method Segmented Tabs
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(
                  value: PaymentMethod.upi,
                  icon: Icon(Icons.qr_code_2_rounded),
                  label: Text('UPI QR'),
                ),
                ButtonSegment(
                  value: PaymentMethod.cash,
                  icon: Icon(Icons.payments_rounded),
                  label: Text('Cash'),
                ),
                ButtonSegment(
                  value: PaymentMethod.card,
                  icon: Icon(Icons.credit_card_rounded),
                  label: Text('Card'),
                ),
              ],
              selected: {_selectedMethod},
              onSelectionChanged: (newSet) {
                NativeApiChannel.triggerNativeHaptic();
                setState(() => _selectedMethod = newSet.first);
              },
            ),

            const SizedBox(height: 24),

            // Dynamic Payment View
            if (_selectedMethod == PaymentMethod.upi) ...[
              UpiQrWidget(
                upiId: 'spicegarden@icici',
                payeeName: 'Spice Garden Restaurant',
                amountRupees: totalRupees,
                orderNumber: widget.order.orderNumber,
              ),
            ] else if (_selectedMethod == PaymentMethod.cash) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tendered Cash', style: theme.textTheme.bodyMedium),
                          Text(
                            CurrencyFormatter.formatRupees(_cashTendered),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Change Due', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            CurrencyFormatter.formatRupees(changeDue.toDouble()),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Quick Tender Denominations', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [100.0, 200.0, 500.0, 2000.0].map((denomination) {
                          return ActionChip(
                            label: Text('+₹${denomination.toInt()}'),
                            onPressed: () => _addCashTender(denomination),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.credit_card_rounded, size: 48, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text('Swipe or Tap on POS Terminal', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Supports Visa, Mastercard, RuPay & Amex', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Confirm & Print Button
            BouncingButton(
              onPressed: _isProcessing ? null : _completePayment,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: _isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm & Print Receipt (ESC/POS)',
                            style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }
}
