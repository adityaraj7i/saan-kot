import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Flow 1 & 2: Table Order -> Menu Punch -> Discount & Cash Checkout',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const SaanKotApp());
    await tester.pumpAndSettle();

    // 1. Switch to "Take Order" tab
    await tester.tap(find.text('Take Order'));
    await tester.pumpAndSettle();
    expect(find.text('Manage Orders'), findsOneWidget);

    // Verify empty table "Masu wala" exists at top
    expect(find.text('Masu wala'), findsOneWidget);

    // Tap on empty table "Masu wala" to create order
    await tester.tap(find.text('Masu wala'));
    await tester.pumpAndSettle();

    // Now in Restaurant Menu
    expect(find.text('Restaurant Menu'), findsOneWidget);
    expect(find.text('Order for Masu wala'), findsOneWidget);

    // Add items: Tap '+' on Black Coffee (in Coffee category)
    final addButtons = find.byIcon(Icons.add_rounded);
    expect(addButtons, findsWidgets);
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    // Sticky KOT Bar appears with "1 Items"
    expect(find.text('1 Items'), findsOneWidget);
    expect(find.text('Save & View Bill'), findsOneWidget);

    // Tap "Save & View Bill"
    await tester.tap(find.text('Save & View Bill'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Order Details bottom sheet pops up
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Table : Masu wala'), findsOneWidget);

    // Test quick discount: Tap '5% Off' chip
    await tester.tap(find.text('5% Off'));
    await tester.pumpAndSettle();
    expect(find.text('Discount (Rs.)'), findsOneWidget);

    // Test payment selection: Tap "Cash"
    await tester.tap(find.text('Cash').first);
    await tester.pumpAndSettle();

    // Enter cash given (Rs. 500)
    await tester.tap(find.text('Rs. 500'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Return Change:'), findsOneWidget);

    // Checkout
    await tester.tap(find.widgetWithText(ElevatedButton, 'Checkout'));
    await tester.pumpAndSettle();

    // Now back on Bills screen, verify checkout snackbar
    expect(find.textContaining('Payment collected for Masu wala'), findsOneWidget);
  });

  testWidgets('Flow 3: Customer Credit Checkout updates My Customers & Analytics',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const SaanKotApp());
    await tester.pumpAndSettle();

    // Verify initial pending order exists: "Fancy wala | ORD-13229"
    expect(find.textContaining('Fancy wala | ORD-13229'), findsOneWidget);

    // Tap on "Fancy wala" order card to open Order Details
    await tester.tap(find.textContaining('Fancy wala | ORD-13229'));
    await tester.pumpAndSettle();

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Table : Fancy wala'), findsOneWidget);

    // Select "Customer Credit" payment method
    await tester.tap(find.text('Customer Credit'));
    await tester.pumpAndSettle();

    // Customer Credit Box appears
    expect(find.text('Assign to Customer Credit Khata'), findsOneWidget);

    // Complete Checkout with Customer Credit
    await tester.tap(find.widgetWithText(ElevatedButton, 'Checkout'));
    await tester.pumpAndSettle();

    // Navigate to "Customers" tab
    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();
    expect(find.text('My Customers'), findsOneWidget);

    // Navigate to "Analytics" tab
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Analytics Dashboard'), findsOneWidget);
    expect(find.text('Revenue Overview'), findsOneWidget);
    expect(find.text('Payment Collections'), findsOneWidget);
    expect(find.text('Credit Analytics (Khata)'), findsOneWidget);
    expect(find.text('Top Sellings Leaderboard'), findsOneWidget);

    // Test toggle Top vs Non
    await tester.tap(find.text('Non').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Top').first);
    await tester.pumpAndSettle();
  });
}
