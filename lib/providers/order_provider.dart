import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import 'table_provider.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [
    Order(
      id: '1001',
      orderNumber: 'ORD-1001',
      type: OrderType.dineIn,
      tableId: 2,
      tableName: 'Table 2',
      status: OrderStatus.open,
      items: [
        OrderItem(
          menuItem: const MenuItem(id: 301, categoryId: 3, name: 'Paneer Butter Masala', pricePaise: 31000),
          quantity: 2,
          unitPricePaise: 31000,
        ),
        OrderItem(
          menuItem: const MenuItem(id: 401, categoryId: 4, name: 'Butter Naan', pricePaise: 5500),
          quantity: 4,
          unitPricePaise: 5500,
        ),
      ],
      subtotalPaise: 84000,
      taxBps: 500,
      discountPaise: 0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 32)),
    ),
    Order(
      id: '1002',
      orderNumber: 'ORD-1002',
      type: OrderType.dineIn,
      tableId: 4,
      tableName: 'Table 4',
      status: OrderStatus.billed,
      items: [
        OrderItem(
          menuItem: const MenuItem(id: 303, categoryId: 3, name: 'Butter Chicken Handi', pricePaise: 38000),
          quantity: 2,
          unitPricePaise: 38000,
        ),
        OrderItem(
          menuItem: const MenuItem(id: 404, categoryId: 4, name: 'Chicken Dum Biryani', pricePaise: 34000),
          quantity: 2,
          unitPricePaise: 34000,
        ),
        OrderItem(
          menuItem: const MenuItem(id: 402, categoryId: 4, name: 'Garlic Naan', pricePaise: 6500),
          quantity: 3,
          unitPricePaise: 6500,
        ),
      ],
      subtotalPaise: 163500,
      taxBps: 500,
      discountPaise: 5000,
      createdAt: DateTime.now().subtract(const Duration(minutes: 54)),
    ),
    Order(
      id: '1000',
      orderNumber: 'ORD-1000',
      type: OrderType.takeaway,
      status: OrderStatus.paid,
      paymentMethod: PaymentMethod.upi,
      items: [
        OrderItem(
          menuItem: const MenuItem(id: 201, categoryId: 2, name: 'Paneer Tikka (6 pcs)', pricePaise: 24000),
          quantity: 1,
          unitPricePaise: 24000,
        ),
        OrderItem(
          menuItem: const MenuItem(id: 103, categoryId: 1, name: 'Sweet Mango Lassi', pricePaise: 9000),
          quantity: 2,
          unitPricePaise: 9000,
        ),
      ],
      subtotalPaise: 42000,
      taxBps: 500,
      discountPaise: 0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 75)),
      completedAt: DateTime.now().subtract(const Duration(minutes: 70)),
    ),
    Order(
      id: '999',
      orderNumber: 'ORD-0999',
      type: OrderType.dineIn,
      tableId: 6,
      tableName: 'Table 6',
      status: OrderStatus.completed,
      paymentMethod: PaymentMethod.cash,
      items: [
        OrderItem(
          menuItem: const MenuItem(id: 304, categoryId: 3, name: 'Mutton Rogan Josh', pricePaise: 46000),
          quantity: 1,
          unitPricePaise: 46000,
        ),
        OrderItem(
          menuItem: const MenuItem(id: 401, categoryId: 4, name: 'Butter Naan', pricePaise: 5500),
          quantity: 2,
          unitPricePaise: 5500,
        ),
      ],
      subtotalPaise: 57000,
      taxBps: 500,
      discountPaise: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
      completedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
  ];

  List<Order> get orders => List.unmodifiable(_orders.where((o) => !o.isDeleted).toList());
  List<Order> get allOrdersIncludingDeleted => List.unmodifiable(_orders);
  List<Order> get deletedOrders => List.unmodifiable(_orders.where((o) => o.isDeleted).toList());

  List<Order> get activeOrders => _orders.where((o) => !o.isDeleted && (o.status == OrderStatus.open || o.status == OrderStatus.billed)).toList();
  List<Order> get completedOrders => _orders.where((o) => !o.isDeleted && (o.status == OrderStatus.paid || o.status == OrderStatus.completed)).toList();

  int get totalRevenuePaise => completedOrders.fold(0, (sum, o) => sum + o.totalPaise);
  double get totalRevenueRupees => totalRevenuePaise / 100.0;

  int get orderCount => _orders.length;

  double get averageTicketValueRupees {
    final paid = completedOrders;
    if (paid.isEmpty) return 0.0;
    return totalRevenueRupees / paid.length;
  }

  int get itemsSoldToday {
    final now = DateTime.now();
    final todayOrders = completedOrders.where((o) =>
        o.createdAt.year == now.year &&
        o.createdAt.month == now.month &&
        o.createdAt.day == now.day);
    return todayOrders.fold<int>(0, (sum, o) => sum + o.items.fold<int>(0, (s, i) => s + i.quantity));
  }

  int get itemsSoldThisWeek {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final weekOrders = completedOrders.where((o) => o.createdAt.isAfter(sevenDaysAgo));
    return weekOrders.fold<int>(0, (sum, o) => sum + o.items.fold<int>(0, (s, i) => s + i.quantity));
  }

  int get itemsSoldThisMonth {
    final now = DateTime.now();
    final monthOrders = completedOrders.where((o) =>
        o.createdAt.year == now.year &&
        o.createdAt.month == now.month);
    return monthOrders.fold<int>(0, (sum, o) => sum + o.items.fold<int>(0, (s, i) => s + i.quantity));
  }

  Map<PaymentMethod, double> get paymentDistribution {
    final map = <PaymentMethod, double>{
      PaymentMethod.cash: 0,
      PaymentMethod.upi: 0,
      PaymentMethod.card: 0,
      PaymentMethod.credit: 0,
    };
    for (final order in completedOrders) {
      if (order.paymentMethod != null) {
        map[order.paymentMethod!] = (map[order.paymentMethod!] ?? 0) + order.totalRupees;
      }
    }
    return map;
  }

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status, {PaymentMethod? method}) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        status: status,
        paymentMethod: method ?? _orders[index].paymentMethod,
        completedAt: (status == OrderStatus.paid || status == OrderStatus.completed) ? DateTime.now() : null,
      );
      notifyListeners();
    }
  }

  void cancelOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(status: OrderStatus.cancelled);
      notifyListeners();
    }
  }

  void editOrder(
    String orderId, {
    required List<OrderItem> items,
    int? discountPaise,
    String? customerPhone,
    OrderType? type,
    int? tableId,
    String? tableName,
    TableProvider? tableProvider,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final old = _orders[index];
      final newSubtotal = items.fold<int>(0, (sum, i) => sum + i.lineTotalPaise);
      final newDiscount = discountPaise ?? old.discountPaise;

      final updated = old.copyWith(
        items: items,
        subtotalPaise: newSubtotal,
        discountPaise: newDiscount,
        customerPhone: customerPhone ?? old.customerPhone,
        type: type ?? old.type,
        tableId: tableId ?? old.tableId,
        tableName: tableName ?? old.tableName,
        isEdited: true,
        editedAt: DateTime.now(),
      );
      _orders[index] = updated;

      // Synchronize Table bill if order is linked to a table
      if (updated.tableId != null && tableProvider != null) {
        if (updated.status == OrderStatus.billed) {
          tableProvider.markBilled(updated.tableId!, updated.totalPaise);
        } else if (updated.status == OrderStatus.open) {
          tableProvider.occupyTable(
            updated.tableId!,
            int.tryParse(updated.id) ?? 1,
            updated.totalPaise,
          );
        }
      }

      notifyListeners();
    }
  }

  void deleteOrder(String orderId, {TableProvider? tableProvider}) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final old = _orders[index];
      _orders[index] = old.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
        status: OrderStatus.cancelled,
      );

      // If active order on table, free the table immediately
      if (old.tableId != null && tableProvider != null) {
        tableProvider.freeTable(old.tableId!);
      }

      notifyListeners();
    }
  }

  void restoreOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        isDeleted: false,
        deletedAt: null,
      );
      notifyListeners();
    }
  }

  void replaceAllOrders(List<Order> newOrders) {
    _orders.clear();
    _orders.addAll(newOrders);
    notifyListeners();
  }
}

