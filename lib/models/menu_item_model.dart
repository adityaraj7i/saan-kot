class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isLowStock;
  final int stockCount;
  final String code;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.isLowStock = false,
    this.stockCount = 50,
    required this.code,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    bool? isLowStock,
    int? stockCount,
    String? code,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isLowStock: isLowStock ?? this.isLowStock,
      stockCount: stockCount ?? this.stockCount,
      code: code ?? this.code,
    );
  }
}

class OrderLineItem {
  final MenuItem item;
  int quantity;

  OrderLineItem({
    required this.item,
    required this.quantity,
  });

  double get totalPrice => item.price * quantity;

  OrderLineItem copyWith({
    MenuItem? item,
    int? quantity,
  }) {
    return OrderLineItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}
