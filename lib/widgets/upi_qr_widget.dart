import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/upi_helper.dart';

class UpiQrWidget extends StatelessWidget {
  final String upiId;
  final String payeeName;
  final double amountRupees;
  final String orderNumber;
  final double qrSize;

  const UpiQrWidget({
    super.key,
    required this.upiId,
    required this.payeeName,
    required this.amountRupees,
    required this.orderNumber,
    this.qrSize = 220,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upiPayload = UpiHelper.buildUpiQrString(
      upiId: upiId,
      payeeName: payeeName,
      amountRupees: amountRupees,
      orderNumber: orderNumber,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: upiPayload,
            version: QrVersions.auto,
            size: qrSize,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1E293B),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          CurrencyFormatter.formatRupees(amountRupees),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2_rounded, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 6),
            Text(
              'Scan with GPay, PhonePe, Paytm, BHIM',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
