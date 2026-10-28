enum TableStatus { available, occupied, billed, reserved }

class RestaurantTable {
  final int id;
  final String name;
  final int seatingCapacity;
  final TableStatus status;
  final int? activeOrderId;
  final DateTime? occupiedSince;
  final int currentBillPaise;

  const RestaurantTable({
    required this.id,
    required this.name,
    this.seatingCapacity = 4,
    this.status = TableStatus.available,
    this.activeOrderId,
    this.occupiedSince,
    this.currentBillPaise = 0,
  });

  int get elapsedMinutes {
    if (occupiedSince == null) return 0;
    return DateTime.now().difference(occupiedSince!).inMinutes;
  }

  RestaurantTable copyWith({
    int? id,
    String? name,
    int? seatingCapacity,
    TableStatus? status,
    int? activeOrderId,
    bool clearActiveOrder = false,
    DateTime? occupiedSince,
    bool clearOccupiedSince = false,
    int? currentBillPaise,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      status: status ?? this.status,
      activeOrderId: clearActiveOrder ? null : (activeOrderId ?? this.activeOrderId),
      occupiedSince: clearOccupiedSince ? null : (occupiedSince ?? this.occupiedSince),
      currentBillPaise: currentBillPaise ?? this.currentBillPaise,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'seating_capacity': seatingCapacity,
      'status': status.name,
      'active_order_id': activeOrderId,
      'occupied_since': occupiedSince?.toIso8601String(),
      'current_bill_paise': currentBillPaise,
    };
  }

  factory RestaurantTable.fromMap(Map<String, dynamic> map) {
    TableStatus parseStatus(String? name) {
      for (final s in TableStatus.values) {
        if (s.name == name) return s;
      }
      return TableStatus.available;
    }

    return RestaurantTable(
      id: map['id'] as int,
      name: map['name'] as String,
      seatingCapacity: (map['seating_capacity'] as int?) ?? 4,
      status: parseStatus(map['status'] as String?),
      activeOrderId: map['active_order_id'] as int?,
      occupiedSince: map['occupied_since'] != null
          ? DateTime.tryParse(map['occupied_since'] as String)
          : null,
      currentBillPaise: (map['current_bill_paise'] as int?) ?? 0,
    );
  }
}

