import 'menu_item.dart';

enum OrderType { dineIn, takeaway, delivery }
enum OrderStatus { open, billed, paid, completed, cancelled }
enum PaymentMethod { cash, upi, card, credit }

class OrderItem {
  final MenuItem menuItem;
  int quantity;
  final int unitPricePaise;
  final String? notes;

  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    required this.unitPricePaise,
    this.notes,
  });

  int get lineTotalPaise => unitPricePaise * quantity;
  double get lineTotalRupees => lineTotalPaise / 100.0;
}

class Order {
  final String id;
  final String orderNumber;
  final OrderType type;
  final int? tableId;
  final String? tableName;
  final OrderStatus status;
  final List<OrderItem> items;
  final int subtotalPaise;
  final int taxBps; // e.g. 500 = 5.0% GST, 0 = Non-GST
  final int discountPaise;
  final int roundOffPaise; // Can be positive or negative paise adjustment
  final bool isTaxInclusive;
  final DateTime createdAt;
  final DateTime? completedAt;
  final PaymentMethod? paymentMethod;
  final String? customerPhone;

  Order({
    required this.id,
    required this.orderNumber,
    required this.type,
    this.tableId,
    this.tableName,
    this.status = OrderStatus.open,
    required this.items,
    required this.subtotalPaise,
    this.taxBps = 500, // 5% default GST
    this.discountPaise = 0,
    this.roundOffPaise = 0,
    this.isTaxInclusive = false,
    required this.createdAt,
    this.completedAt,
    this.paymentMethod,
    this.customerPhone,
  });

  int get taxableBasePaise {
    final net = (subtotalPaise - discountPaise).clamp(0, double.infinity).toInt();
    if (!isTaxInclusive || taxBps == 0) {
      return net;
    }
    return (net * 10000) ~/ (10000 + taxBps);
  }

  int get taxPaise {
    final net = (subtotalPaise - discountPaise).clamp(0, double.infinity).toInt();
    if (taxBps == 0) return 0;
    if (isTaxInclusive) {
      return net - taxableBasePaise;
    }
    return (net * taxBps) ~/ 10000;
  }

  int get exactTotalPaise {
    final net = (subtotalPaise - discountPaise).clamp(0, double.infinity).toInt();
    if (isTaxInclusive) {
      return net;
    }
    return net + taxPaise;
  }

  int get totalPaise => exactTotalPaise + roundOffPaise;

  double get taxableBaseRupees => taxableBasePaise / 100.0;
  double get subtotalRupees => subtotalPaise / 100.0;
  double get taxRupees => taxPaise / 100.0;
  double get cgstRupees => (taxPaise / 2) / 100.0;
  double get sgstRupees => (taxPaise / 2) / 100.0;
  double get discountRupees => discountPaise / 100.0;
  double get roundOffRupees => roundOffPaise / 100.0;
  double get totalRupees => totalPaise / 100.0;

  Order copyWith({
    String? id,
    String? orderNumber,
    OrderType? type,
    int? tableId,
    String? tableName,
    OrderStatus? status,
    List<OrderItem>? items,
    int? subtotalPaise,
    int? taxBps,
    int? discountPaise,
    int? roundOffPaise,
    bool? isTaxInclusive,
    DateTime? createdAt,
    DateTime? completedAt,
    PaymentMethod? paymentMethod,
    String? customerPhone,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      type: type ?? this.type,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      taxBps: taxBps ?? this.taxBps,
      discountPaise: discountPaise ?? this.discountPaise,
      roundOffPaise: roundOffPaise ?? this.roundOffPaise,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
}
