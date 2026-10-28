import 'package:flutter/foundation.dart';
import '../models/table_model.dart';
import '../services/local_storage_service.dart';

class TableProvider extends ChangeNotifier {
  final List<RestaurantTable> _tables = [
    const RestaurantTable(id: 1, name: 'Table 1', seatingCapacity: 2, status: TableStatus.available),
    const RestaurantTable(id: 2, name: 'Table 2', seatingCapacity: 4, status: TableStatus.available),
    const RestaurantTable(id: 3, name: 'Table 3', seatingCapacity: 4, status: TableStatus.available),
    const RestaurantTable(id: 4, name: 'Table 4', seatingCapacity: 6, status: TableStatus.available),
    const RestaurantTable(id: 5, name: 'Table 5', seatingCapacity: 2, status: TableStatus.available),
    const RestaurantTable(id: 6, name: 'Table 6', seatingCapacity: 4, status: TableStatus.available),
    const RestaurantTable(id: 7, name: 'Table 7 (Booth)', seatingCapacity: 6, status: TableStatus.available),
    const RestaurantTable(id: 8, name: 'Table 8 (Family)', seatingCapacity: 8, status: TableStatus.available),
    const RestaurantTable(id: 9, name: 'Table 9 (Rooftop)', seatingCapacity: 4, status: TableStatus.available),
    const RestaurantTable(id: 10, name: 'Table 10 (Rooftop)', seatingCapacity: 4, status: TableStatus.available),
  ];

  Future<void> loadFromStorage() async {
    final saved = await LocalStorageService.loadTables();
    if (saved != null && saved.isNotEmpty) {
      _tables.clear();
      _tables.addAll(saved);
      notifyListeners();
    }
  }

  void _persist() {
    LocalStorageService.saveTables(_tables);
  }

  List<RestaurantTable> get tables => List.unmodifiable(_tables);

  int get availableCount => _tables.where((t) => t.status == TableStatus.available).length;
  int get occupiedCount => _tables.where((t) => t.status == TableStatus.occupied).length;
  int get billedCount => _tables.where((t) => t.status == TableStatus.billed).length;

  RestaurantTable? getTableById(int id) {
    try {
      return _tables.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void occupyTable(int tableId, int orderId, int initialBillPaise) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      _tables[index] = _tables[index].copyWith(
        status: TableStatus.occupied,
        activeOrderId: orderId,
        occupiedSince: DateTime.now(),
        currentBillPaise: initialBillPaise,
      );
      _persist();
      notifyListeners();
    }
  }

  void markBilled(int tableId, int totalPaise) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      _tables[index] = _tables[index].copyWith(
        status: TableStatus.billed,
        currentBillPaise: totalPaise,
      );
      _persist();
      notifyListeners();
    }
  }

  void freeTable(int tableId) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      _tables[index] = _tables[index].copyWith(
        status: TableStatus.available,
        clearActiveOrder: true,
        clearOccupiedSince: true,
        currentBillPaise: 0,
      );
      _persist();
      notifyListeners();
    }
  }

  void transferTable(int fromTableId, int toTableId) {
    final fromIdx = _tables.indexWhere((t) => t.id == fromTableId);
    final toIdx = _tables.indexWhere((t) => t.id == toTableId);

    if (fromIdx >= 0 && toIdx >= 0 && _tables[toIdx].status == TableStatus.available) {
      final fromTable = _tables[fromIdx];
      _tables[toIdx] = _tables[toIdx].copyWith(
        status: TableStatus.occupied,
        activeOrderId: fromTable.activeOrderId,
        occupiedSince: fromTable.occupiedSince,
        currentBillPaise: fromTable.currentBillPaise,
      );
      _tables[fromIdx] = _tables[fromIdx].copyWith(
        status: TableStatus.available,
        clearActiveOrder: true,
        clearOccupiedSince: true,
        currentBillPaise: 0,
      );
      _persist();
      notifyListeners();
    }
  }

  void addTable({
    required String name,
    required int seatingCapacity,
    TableStatus status = TableStatus.available,
  }) {
    final nextId = _tables.isEmpty ? 1 : (_tables.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1);
    _tables.add(RestaurantTable(
      id: nextId,
      name: name,
      seatingCapacity: seatingCapacity,
      status: status,
    ));
    _persist();
    notifyListeners();
  }

  void updateTable(
    int tableId, {
    required String name,
    required int seatingCapacity,
    TableStatus? status,
  }) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index >= 0) {
      _tables[index] = _tables[index].copyWith(
        name: name,
        seatingCapacity: seatingCapacity,
        status: status ?? _tables[index].status,
      );
      _persist();
      notifyListeners();
    }
  }

  void deleteTable(int tableId) {
    _tables.removeWhere((t) => t.id == tableId);
    _persist();
    notifyListeners();
  }

  void replaceAllTables(List<RestaurantTable> newTables) {
    _tables.clear();
    _tables.addAll(newTables);
    _persist();
    notifyListeners();
  }
}

