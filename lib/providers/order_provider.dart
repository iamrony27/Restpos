import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../services/local_storage_service.dart';
import 'table_provider.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];

  Future<void> loadFromStorage() async {
    final saved = await LocalStorageService.loadOrders();
    if (saved != null) {
      _orders.clear();
      _orders.addAll(saved);
      notifyListeners();
    }
  }

  void _persist() {
    LocalStorageService.saveOrders(_orders);
  }

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
    _persist();
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
      _persist();
      notifyListeners();
    }
  }

  void cancelOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(status: OrderStatus.cancelled);
      _persist();
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

      _persist();
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

      _persist();
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
      _persist();
      notifyListeners();
    }
  }

  void replaceAllOrders(List<Order> newOrders) {
    _orders.clear();
    _orders.addAll(newOrders);
    _persist();
    notifyListeners();
  }

  void clearAllOrders({TableProvider? tableProvider}) {
    _orders.clear();
    LocalStorageService.clearOrders();
    if (tableProvider != null) {
      for (final table in tableProvider.tables) {
        if (table.status != TableStatus.available) {
          tableProvider.freeTable(table.id);
        }
      }
    }
    notifyListeners();
  }
}

