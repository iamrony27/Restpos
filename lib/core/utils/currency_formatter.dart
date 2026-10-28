import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrNoDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String formatPaise(int paise, {bool hideZeroDecimals = true}) {
    final rupees = paise / 100.0;
    if (hideZeroDecimals && (rupees.truncateToDouble() == rupees)) {
      return _inrNoDecimals.format(rupees);
    }
    return _inrFormatter.format(rupees);
  }

  static String formatRupees(double rupees, {bool hideZeroDecimals = true}) {
    if (hideZeroDecimals && (rupees.truncateToDouble() == rupees)) {
      return _inrNoDecimals.format(rupees);
    }
    return _inrFormatter.format(rupees);
  }
}
