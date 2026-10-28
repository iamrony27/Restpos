class UpiHelper {
  /// Generates a standard Bharat-spec UPI deep link / QR string
  static String buildUpiQrString({
    required String upiId,
    required String payeeName,
    required double amountRupees,
    required String orderNumber,
    String currency = 'INR',
  }) {
    final cleanUpi = Uri.encodeComponent(upiId);
    final cleanName = Uri.encodeComponent(payeeName);
    final formattedAmount = amountRupees.toStringAsFixed(2);
    final cleanNote = Uri.encodeComponent('Bill $orderNumber');

    return 'upi://pay?pa=$cleanUpi&pn=$cleanName&am=$formattedAmount&cu=$currency&tn=$cleanNote';
  }
}
