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
    DateTime? occupiedSince,
    int? currentBillPaise,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      status: status ?? this.status,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      occupiedSince: occupiedSince ?? this.occupiedSince,
      currentBillPaise: currentBillPaise ?? this.currentBillPaise,
    );
  }
}
