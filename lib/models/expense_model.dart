class Expense {
  final String id;
  final String category; // Supplies, Utilities, Wages, Rent, Maintenance
  final String description;
  final int amountPaise;
  final DateTime date;
  final String? vendor;
  final String? paymentMethod;

  const Expense({
    required this.id,
    required this.category,
    required this.description,
    required this.amountPaise,
    required this.date,
    this.vendor,
    this.paymentMethod = 'Cash',
  });

  double get amountRupees => amountPaise / 100.0;
}
