enum StockLogType {
  purchase,
  saleDeduction,
  adjustmentWastage,
}

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minThreshold;
  final double unitCost;
  final bool isDirectRetail;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minThreshold,
    this.unitCost = 0.0,
    this.isDirectRetail = false,
  });

  bool get isLowStock => currentStock <= minThreshold;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? minThreshold,
    double? unitCost,
    bool? isDirectRetail,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minThreshold: minThreshold ?? this.minThreshold,
      unitCost: unitCost ?? this.unitCost,
      isDirectRetail: isDirectRetail ?? this.isDirectRetail,
    );
  }
}

class RecipeIngredient {
  final String inventoryItemId;
  final String inventoryItemName;
  final double quantityRequired;
  final String unit;

  const RecipeIngredient({
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.quantityRequired,
    required this.unit,
  });

  RecipeIngredient copyWith({
    String? inventoryItemId,
    String? inventoryItemName,
    double? quantityRequired,
    String? unit,
  }) {
    return RecipeIngredient(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      inventoryItemName: inventoryItemName ?? this.inventoryItemName,
      quantityRequired: quantityRequired ?? this.quantityRequired,
      unit: unit ?? this.unit,
    );
  }
}

class RecipeBOM {
  final String menuItemId;
  final String menuItemName;
  final List<RecipeIngredient> ingredients;

  const RecipeBOM({
    required this.menuItemId,
    required this.menuItemName,
    required this.ingredients,
  });

  RecipeBOM copyWith({
    String? menuItemId,
    String? menuItemName,
    List<RecipeIngredient>? ingredients,
  }) {
    return RecipeBOM(
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}

class StockLogEntry {
  final String id;
  final DateTime timestamp;
  final String inventoryItemId;
  final String inventoryItemName;
  final double changeAmount;
  final String unit;
  final StockLogType type;
  final String? orderId;
  final String? note;

  const StockLogEntry({
    required this.id,
    required this.timestamp,
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.changeAmount,
    required this.unit,
    required this.type,
    this.orderId,
    this.note,
  });
}
