import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import '../models/restaurant_profile.dart';
import '../services/local_storage_service.dart';

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
  Future<void> loadProfileFromStorage() async {
    final saved = await LocalStorageService.loadProfile();
    if (saved != null) {
      _profile = saved;
      notifyListeners();
    }
  }

  void _persistProfile() {
    LocalStorageService.saveProfile(_profile);
  }

  int _selectedCategoryId = 0; // 0 = All categories
  String _searchQuery = '';
  OrderType _orderType = OrderType.dineIn;
  int? _selectedTableId;
  String? _selectedTableName;
  int _discountPaise = 0;
  final List<CartLine> _cart = [];
  RestaurantProfile _profile = const RestaurantProfile();

  RestaurantProfile get profile => _profile;
  int get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  OrderType get orderType => _orderType;
  int? get selectedTableId => _selectedTableId;
  String? get selectedTableName => _selectedTableName;
  int get discountPaise => _discountPaise;
  List<CartLine> get cart => List.unmodifiable(_cart);

  bool get isGstEnabled => _profile.isGstEnabled;
  double get gstRatePercent => _profile.gstRatePercent;
  bool get isRoundOffEnabled => _profile.isRoundOffEnabled;
  bool get isTaxInclusive => _profile.isTaxInclusive;
  String get fssaiNumber => _profile.fssai;
  String get gstin => _profile.gstin;

  bool _isPrinterConnected = true;
  bool get isPrinterConnected => _isPrinterConnected;
  String get printerName => 'Thermal ESC/POS 58mm';

  void togglePrinterConnection() {
    _isPrinterConnected = !_isPrinterConnected;
    notifyListeners();
  }

  void setPrinterConnected(bool connected) {
    _isPrinterConnected = connected;
    notifyListeners();
  }

  int get totalItemCount => _cart.fold(0, (sum, line) => sum + line.quantity);

  int get subtotalPaise => _cart.fold(0, (sum, line) => sum + line.lineTotalPaise);

  int get taxBps => _profile.isGstEnabled ? (_profile.gstRatePercent * 100).round() : 0;

  int get taxableBasePaise {
    final net = (subtotalPaise - _discountPaise).clamp(0, double.infinity).toInt();
    if (!_profile.isGstEnabled || !_profile.isTaxInclusive || taxBps == 0) {
      return net;
    }
    return (net * 10000) ~/ (10000 + taxBps);
  }

  int get taxPaise {
    if (!_profile.isGstEnabled || taxBps == 0) return 0;
    final net = (subtotalPaise - _discountPaise).clamp(0, double.infinity).toInt();
    if (_profile.isTaxInclusive) {
      return net - taxableBasePaise;
    }
    return (net * taxBps) ~/ 10000;
  }

  int get exactTotalPaise {
    final net = (subtotalPaise - _discountPaise).clamp(0, double.infinity).toInt();
    if (_profile.isTaxInclusive) {
      return net;
    }
    return net + taxPaise;
  }

  int get roundOffAdjustmentPaise {
    if (!_profile.isRoundOffEnabled) return 0;
    final rounded = ((exactTotalPaise / 100.0).round()) * 100;
    return rounded - exactTotalPaise;
  }

  int get totalPaise => exactTotalPaise + roundOffAdjustmentPaise;

  double get taxableBaseRupees => taxableBasePaise / 100.0;
  double get subtotalRupees => subtotalPaise / 100.0;
  double get taxRupees => taxPaise / 100.0;
  double get discountRupees => _discountPaise / 100.0;
  double get roundOffAdjustmentRupees => roundOffAdjustmentPaise / 100.0;
  double get totalRupees => totalPaise / 100.0;

  void updateProfile(RestaurantProfile newProfile) {
    _profile = newProfile;
    _persistProfile();
    notifyListeners();
  }

  void setGstEnabled(bool enabled) {
    _profile = _profile.copyWith(isGstEnabled: enabled);
    _persistProfile();
    notifyListeners();
  }

  void setTaxInclusive(bool isInclusive) {
    _profile = _profile.copyWith(isTaxInclusive: isInclusive);
    _persistProfile();
    notifyListeners();
  }

  void setGstRatePercent(double rate) {
    _profile = _profile.copyWith(gstRatePercent: rate, defaultTaxBps: (rate * 100).round());
    _persistProfile();
    notifyListeners();
  }

  void setRoundOffEnabled(bool enabled) {
    _profile = _profile.copyWith(isRoundOffEnabled: enabled);
    _persistProfile();
    notifyListeners();
  }

  void setFssaiNumber(String number) {
    _profile = _profile.copyWith(fssai: number);
    _persistProfile();
    notifyListeners();
  }

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
      roundOffPaise: roundOffAdjustmentPaise,
      isTaxInclusive: _profile.isTaxInclusive,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      paymentMethod: paymentMethod,
    );

    clearCart();
    return order;
  }
}
