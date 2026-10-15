class TableModel {
  final String id;
  final String name;
  final bool isOccupied;
  final String? activeOrderId;
  final int orderCount;
  final double runningTotal;
  final int elapsedMinutes;
  final bool isCustomGroup;

  TableModel({
    required this.id,
    required this.name,
    this.isOccupied = false,
    this.activeOrderId,
    this.orderCount = 0,
    this.runningTotal = 0.0,
    this.elapsedMinutes = 0,
    this.isCustomGroup = false,
  });

  TableModel copyWith({
    String? id,
    String? name,
    bool? isOccupied,
    String? activeOrderId,
    int? orderCount,
    double? runningTotal,
    int? elapsedMinutes,
    bool? isCustomGroup,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isOccupied: isOccupied ?? this.isOccupied,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      orderCount: orderCount ?? this.orderCount,
      runningTotal: runningTotal ?? this.runningTotal,
      elapsedMinutes: elapsedMinutes ?? this.elapsedMinutes,
      isCustomGroup: isCustomGroup ?? this.isCustomGroup,
    );
  }
}
