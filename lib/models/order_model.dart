import 'menu_item_model.dart';

enum OrderStatus { pending, completed, cancelled }

enum PaymentMethod { cash, fonepay, esewa, customerCredit, bank }

enum DiscountPreset { none, percent5, percent10, flat20, flat50, custom }

class OrderAuditEntry {
  final String id;
  final DateTime timestamp;
  final String staffName;
  final String actionDescription;
  final String? reason;
  final String? itemName;
  final int? previousQty;
  final int? newQty;

  OrderAuditEntry({
    required this.id,
    required this.timestamp,
    required this.staffName,
    required this.actionDescription,
    this.reason,
    this.itemName,
    this.previousQty,
    this.newQty,
  });
}

class OrderModel {
  final String id;
  final String tableName;
  final DateTime createdAt;
  final String takenByStaff;
  final List<OrderLineItem> items;
  final OrderStatus status;
  final double discountAmount;
  final DiscountPreset discountPreset;
  final PaymentMethod? paymentMethod;
  final double cashGiven;
  final double cashReturn;
  final String? customerId;
  final String? customerName;
  final bool hasRemovedItems;
  final bool hasUnservedItems;
  final List<OrderAuditEntry> auditLog;

  OrderModel({
    required this.id,
    required this.tableName,
    required this.createdAt,
    this.takenByStaff = 'Addy',
    required this.items,
    this.status = OrderStatus.pending,
    this.discountAmount = 0.0,
    this.discountPreset = DiscountPreset.none,
    this.paymentMethod,
    this.cashGiven = 0.0,
    this.cashReturn = 0.0,
    this.customerId,
    this.customerName,
    this.hasRemovedItems = false,
    this.hasUnservedItems = false,
    this.auditLog = const [],
  });

  double get subtotal =>
      items.fold(0.0, (sum, lineItem) => sum + lineItem.totalPrice);

  double get payableAmount =>
      (subtotal - discountAmount).clamp(0.0, double.infinity);

  int get totalItemCount =>
      items.fold(0, (count, lineItem) => count + lineItem.quantity);

  OrderModel copyWith({
    String? id,
    String? tableName,
    DateTime? createdAt,
    String? takenByStaff,
    List<OrderLineItem>? items,
    OrderStatus? status,
    double? discountAmount,
    DiscountPreset? discountPreset,
    PaymentMethod? paymentMethod,
    double? cashGiven,
    double? cashReturn,
    String? customerId,
    String? customerName,
    bool? hasRemovedItems,
    bool? hasUnservedItems,
    List<OrderAuditEntry>? auditLog,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      createdAt: createdAt ?? this.createdAt,
      takenByStaff: takenByStaff ?? this.takenByStaff,
      items: items ?? this.items,
      status: status ?? this.status,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPreset: discountPreset ?? this.discountPreset,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashGiven: cashGiven ?? this.cashGiven,
      cashReturn: cashReturn ?? this.cashReturn,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      hasRemovedItems: hasRemovedItems ?? this.hasRemovedItems,
      hasUnservedItems: hasUnservedItems ?? this.hasUnservedItems,
      auditLog: auditLog ?? this.auditLog,
    );
  }
}
