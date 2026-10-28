import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import '../models/restaurant_profile.dart';

class CartLine {
  final MenuItem item;
  int quantity;
  String? notes;

  CartLine({
    required this.item,
    this.quantity = 1,
    this.notes,
  });

  int get lineTotalPaise => item.pricePaise * quantity;
}

class PosProvider extends ChangeNotifier {
  int _selectedCategoryId = 0; // 0 = All categories
  String _searchQuery = '';
  OrderType _orderType = OrderType.dineIn;
  int? _selectedTableId;
  String? _selectedTableName;
  int _discountPaise = 0;
  final List<CartLine> _cart = [];
  final RestaurantProfile profile = const RestaurantProfile();

  int get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  OrderType get orderType => _orderType;
  int? get selectedTableId => _selectedTableId;
  String? get selectedTableName => _selectedTableName;
  int get discountPaise => _discountPaise;
  List<CartLine> get cart => List.unmodifiable(_cart);

  int get totalItemCount => _cart.fold(0, (sum, line) => sum + line.quantity);

  int get subtotalPaise => _cart.fold(0, (sum, line) => sum + line.lineTotalPaise);

  int get taxBps => profile.defaultTaxBps; // 500 = 5%

  int get taxPaise {
    final taxable = (subtotalPaise - _discountPaise).clamp(0, double.infinity).toInt();
    return (taxable * taxBps) ~/ 10000;
  }

  int get totalPaise {
    final sub = subtotalPaise - _discountPaise;
    return (sub.clamp(0, double.infinity).toInt() + taxPaise);
  }

  double get subtotalRupees => subtotalPaise / 100.0;
  double get taxRupees => taxPaise / 100.0;
  double get discountRupees => _discountPaise / 100.0;
  double get totalRupees => totalPaise / 100.0;

  void selectCategory(int categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setOrderType(OrderType type) {
    _orderType = type;
    if (type == OrderType.takeaway) {
      _selectedTableId = null;
      _selectedTableName = null;
    }
    notifyListeners();
  }

  void selectTable(int id, String name) {
    _selectedTableId = id;
    _selectedTableName = name;
    _orderType = OrderType.dineIn;
    notifyListeners();
  }

  void clearTable() {
    _selectedTableId = null;
    _selectedTableName = null;
    notifyListeners();
  }

  void addToCart(MenuItem item) {
    final index = _cart.indexWhere((line) => line.item.id == item.id);
    if (index >= 0) {
      _cart[index].quantity += 1;
    } else {
      _cart.add(CartLine(item: item, quantity: 1));
    }
    notifyListeners();
  }

  void decrementQuantity(int itemId) {
    final index = _cart.indexWhere((line) => line.item.id == itemId);
    if (index >= 0) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity -= 1;
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeFromCart(int itemId) {
    _cart.removeWhere((line) => line.item.id == itemId);
    notifyListeners();
  }

  void updateLineNotes(int itemId, String notes) {
    final index = _cart.indexWhere((line) => line.item.id == itemId);
    if (index >= 0) {
      _cart[index].notes = notes.trim().isEmpty ? null : notes.trim();
      notifyListeners();
    }
  }

  void setDiscountPaise(int discount) {
    _discountPaise = discount.clamp(0, subtotalPaise);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _discountPaise = 0;
    _selectedTableId = null;
    _selectedTableName = null;
    notifyListeners();
  }

  Order buildOrder({required PaymentMethod paymentMethod}) {
    final orderNum = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final items = _cart.map((line) => OrderItem(
      menuItem: line.item,
      quantity: line.quantity,
      unitPricePaise: line.item.pricePaise,
      notes: line.notes,
    )).toList();

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderNumber: orderNum,
      type: _orderType,
      tableId: _selectedTableId,
      tableName: _selectedTableName,
      status: OrderStatus.paid,
      items: items,
      subtotalPaise: subtotalPaise,
      taxBps: taxBps,
      discountPaise: _discountPaise,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      paymentMethod: paymentMethod,
    );

    clearCart();
    return order;
  }
}
