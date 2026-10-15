import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/state/app_state.dart';

void main() {
  group('Phase 3: Bills, Anti-Theft Audit & Order Details Sheet', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('Fancy wala active order ORD-13229 matches exact reference spec', () {
      final order = appState.orders.firstWhere((o) => o.id == 'ORD-13229');
      expect(order.status, equals(OrderStatus.pending));
      expect(order.tableName, equals('Fancy wala'));
      expect(order.takenByStaff, equals('Addy'));
      expect(order.items.length, equals(6));

      // Verify exact 6 items
      final itemMap = {for (var i in order.items) i.item.name: i};
      expect(itemMap.containsKey('Milk coffee'), isTrue);
      expect(itemMap['Milk coffee']!.item.price, equals(55.0));

      expect(itemMap.containsKey('Iced americano'), isTrue);
      expect(itemMap['Iced americano']!.item.price, equals(75.0));

      expect(itemMap.containsKey('Cold coffee'), isTrue);
      expect(itemMap['Cold coffee']!.item.price, equals(85.0));

      expect(itemMap.containsKey('Blackcoffe double'), isTrue);
      expect(itemMap['Blackcoffe double']!.item.price, equals(80.0));

      expect(itemMap.containsKey('Milk'), isTrue);
      expect(itemMap['Milk']!.item.price, equals(70.0));

      expect(itemMap.containsKey('C. Chicken Momo - Jhol'), isTrue);
      expect(itemMap['C. Chicken Momo - Jhol']!.item.price, equals(140.0));

      expect(order.subtotal, equals(505.0));
      expect(order.payableAmount, equals(505.0));
    });

    test('Completed orders list contains exactly 17 orders totaling Rs. 3070.00', () {
      final completed =
          appState.orders.where((o) => o.status == OrderStatus.completed).toList();
      expect(completed.length, equals(17));

      final totalCompletedRevenue =
          completed.fold(0.0, (sum, o) => sum + o.payableAmount);
      expect(totalCompletedRevenue, equals(3070.0));

      // Check specific top cards
      final ord13230 = completed.firstWhere((o) => o.id == 'ORD-13230');
      expect(ord13230.tableName, equals('T1'));
      expect(ord13230.payableAmount, equals(120.0));

      final ord13228 = completed.firstWhere((o) => o.id == 'ORD-13228');
      expect(ord13228.tableName, equals('T1'));
      expect(ord13228.payableAmount, equals(70.0));
      expect(ord13228.discountAmount, equals(50.0));

      final ord13227 = completed.firstWhere((o) => o.id == 'ORD-13227');
      expect(ord13227.tableName, equals('Raj Group'));
      expect(ord13227.payableAmount, equals(530.0));

      final ord13226 = completed.firstWhere((o) => o.id == 'ORD-13226');
      expect(ord13226.tableName, equals('Masu wala'));
      expect(ord13226.payableAmount, equals(205.0));

      final ord13225 = completed.firstWhere((o) => o.id == 'ORD-13225');
      expect(ord13225.tableName, equals('T3'));
      expect(ord13225.payableAmount, equals(130.0));

      final ord13211 = completed.firstWhere((o) => o.id == 'ORD-13211');
      expect(ord13211.tableName, equals('T5'));
      expect(ord13211.payableAmount, equals(0.0));

      final ord13210 = completed.firstWhere((o) => o.id == 'ORD-13210');
      expect(ord13210.tableName, equals('T4'));
      expect(ord13210.payableAmount, equals(70.0));
    });

    test('Anti-theft audit log records item quantity decrease and removal', () {
      final initialItemCount = appState.orders.first.items.length;
      final firstItemId = appState.orders.first.items.first.item.id;

      // Decrease quantity
      appState.updateOrderItemQuantity(
        orderId: 'ORD-13229',
        itemId: firstItemId,
        newQuantity: 0,
        staffName: 'Addy',
        reason: 'Customer changed mind',
      );

      final orderAfter =
          appState.orders.firstWhere((o) => o.id == 'ORD-13229');
      expect(orderAfter.hasRemovedItems, isTrue);
      expect(orderAfter.items.length, equals(initialItemCount - 1));
      expect(orderAfter.auditLog.isNotEmpty, isTrue);
      expect(orderAfter.auditLog.first.staffName, equals('Addy'));
      expect(orderAfter.auditLog.first.reason, equals('Customer changed mind'));
    });

    testWidgets('UI Smoke: Bills Screen tabs, filter chips, and order details audit dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SaanKotApp());
      await tester.pumpAndSettle();

      // On Bills Screen by default
      expect(find.text('Order History'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Verify floating total pill on Pending
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.text('Rs. 505.00'), findsWidgets);

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Verify Completed floating total
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.text('Rs. 3070.00'), findsWidgets);

      // Verify subfilter chips on Completed tab
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Item Removed (2)'), findsOneWidget);
      expect(find.text('Item Unserved (1)'), findsOneWidget);

      // Tap "Item Removed (2)" chip
      await tester.tap(find.text('Item Removed (2)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ORD-13208'), findsOneWidget);

      // Tap on the order to open Order Details
      await tester.tap(find.textContaining('ORD-13208'));
      await tester.pumpAndSettle();

      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Tap History to open Audit & History Dialog
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('Order Audit & History'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });
}
