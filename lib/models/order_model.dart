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

  Map<String, dynamic> toMap() {
    return {
      'menu_item': menuItem.toMap(),
      'quantity': quantity,
      'unit_price_paise': unitPricePaise,
      'notes': notes,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItem: MenuItem.fromMap(map['menu_item'] as Map<String, dynamic>),
      quantity: (map['quantity'] as int?) ?? 1,
      unitPricePaise: (map['unit_price_paise'] as int?) ?? 0,
      notes: map['notes'] as String?,
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'type': type.name,
      'table_id': tableId,
      'table_name': tableName,
      'status': status.name,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal_paise': subtotalPaise,
      'tax_bps': taxBps,
      'discount_paise': discountPaise,
      'round_off_paise': roundOffPaise,
      'is_tax_inclusive': isTaxInclusive,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'payment_method': paymentMethod?.name,
      'customer_phone': customerPhone,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    OrderType parseType(String? name) {
      for (final t in OrderType.values) {
        if (t.name == name) return t;
      }
      return OrderType.dineIn;
    }

    OrderStatus parseStatus(String? name) {
      for (final s in OrderStatus.values) {
        if (s.name == name) return s;
      }
      return OrderStatus.paid;
    }

    PaymentMethod? parsePayment(String? name) {
      if (name == null) return null;
      for (final p in PaymentMethod.values) {
        if (p.name == name) return p;
      }
      return null;
    }

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((itemMap) => OrderItem.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    return Order(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String,
      type: parseType(map['type'] as String?),
      tableId: map['table_id'] as int?,
      tableName: map['table_name'] as String?,
      status: parseStatus(map['status'] as String?),
      items: itemsList,
      subtotalPaise: (map['subtotal_paise'] as int?) ?? 0,
      taxBps: (map['tax_bps'] as int?) ?? 500,
      discountPaise: (map['discount_paise'] as int?) ?? 0,
      roundOffPaise: (map['round_off_paise'] as int?) ?? 0,
      isTaxInclusive: (map['is_tax_inclusive'] as bool?) ?? false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      paymentMethod: parsePayment(map['payment_method'] as String?),
      customerPhone: map['customer_phone'] as String?,
    );
  }
}

