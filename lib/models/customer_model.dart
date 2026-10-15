import 'order_model.dart';

class CustomerCreditTransaction {
  final String id;
  final DateTime date;
  final String orderId;
  final double amount;
  final bool isPayment; // true if settled/paid off, false if credit added
  final PaymentMethod? paymentMethod;
  final double creditDiscount;
  final bool isStaffAdvance;
  final String note;

  CustomerCreditTransaction({
    required this.id,
    required this.date,
    required this.orderId,
    required this.amount,
    required this.isPayment,
    this.paymentMethod,
    this.creditDiscount = 0.0,
    this.isStaffAdvance = false,
    required this.note,
  });

  CustomerCreditTransaction copyWith({
    String? id,
    DateTime? date,
    String? orderId,
    double? amount,
    bool? isPayment,
    PaymentMethod? paymentMethod,
    double? creditDiscount,
    bool? isStaffAdvance,
    String? note,
  }) {
    return CustomerCreditTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      isPayment: isPayment ?? this.isPayment,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      creditDiscount: creditDiscount ?? this.creditDiscount,
      isStaffAdvance: isStaffAdvance ?? this.isStaffAdvance,
      note: note ?? this.note,
    );
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double totalDue;
  final String initials;
  final int avatarColorValue;
  final bool isStaff;
  final List<CustomerCreditTransaction> transactions;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.address = 'Kathmandu, Nepal',
    this.totalDue = 0.0,
    required this.initials,
    required this.avatarColorValue,
    this.isStaff = false,
    this.transactions = const [],
  });

  bool get hasDues => totalDue > 0.01;

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    double? totalDue,
    String? initials,
    int? avatarColorValue,
    bool? isStaff,
    List<CustomerCreditTransaction>? transactions,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalDue: totalDue ?? this.totalDue,
      initials: initials ?? this.initials,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      isStaff: isStaff ?? this.isStaff,
      transactions: transactions ?? this.transactions,
    );
  }
}
