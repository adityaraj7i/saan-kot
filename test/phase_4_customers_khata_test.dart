import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/state/app_state.dart';

void main() {
  group('Phase 4: My Customers, Khata Credit Ledger & Settlement Engine', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('All 6 reference cafe customers have exact avatar colors and phones', () {
      final customerMap = {for (var c in appState.customers) c.name: c};
      expect(customerMap.length, equals(6));

      // 1. Ajaya (Amber #D97706, 9812345678, No Dues)
      final ajaya = customerMap['Ajaya']!;
      expect(ajaya.initials, equals('A'));
      expect(ajaya.avatarColorValue, equals(0xFFD97706));
      expect(ajaya.phone, equals('9812345678'));
      expect(ajaya.totalDue, equals(0.0));

      // 2. Bharat Bhanja (Indigo #6366F1, 9866234475, No Dues)
      final bb = customerMap['Bharat Bhanja']!;
      expect(bb.initials, equals('BB'));
      expect(bb.avatarColorValue, equals(0xFF6366F1));
      expect(bb.phone, equals('9866234475'));
      expect(bb.totalDue, equals(0.0));

      // 3. Bijay (Emerald #10B981, 9845896631, No Dues)
      final bijay = customerMap['Bijay']!;
      expect(bijay.initials, equals('B'));
      expect(bijay.avatarColorValue, equals(0xFF10B981));
      expect(bijay.phone, equals('9845896631'));
      expect(bijay.totalDue, equals(0.0));

      // 4. Gyalzan S (Purple #7C3AED, 9865741236, No Dues)
      final gs = customerMap['Gyalzan S']!;
      expect(gs.initials, equals('GS'));
      expect(gs.avatarColorValue, equals(0xFF7C3AED));
      expect(gs.phone, equals('9865741236'));
      expect(gs.totalDue, equals(0.0));

      // 5. Himal (Deep Purple #6D28D9, 9846849186, Due: Rs. 4890.00)
      final himal = customerMap['Himal']!;
      expect(himal.initials, equals('H'));
      expect(himal.avatarColorValue, equals(0xFF6D28D9));
      expect(himal.phone, equals('9846849186'));
      expect(himal.totalDue, equals(4890.0));
      expect(himal.transactions.length, equals(2));

      // 6. Jar Wala (Burnt Orange #C2410C, 9866556525, No Dues)
      final jw = customerMap['Jar Wala']!;
      expect(jw.initials, equals('JW'));
      expect(jw.avatarColorValue, equals(0xFFC2410C));
      expect(jw.phone, equals('9866556525'));
      expect(jw.totalDue, equals(0.0));
    });

    test('Baseline financial collection reconciliation matches reference spec', () {
      // Immediate order collection baselines
      expect(appState.immediateCashRevenue, equals(290.0));
      expect(appState.immediateFonepayRevenue, equals(250.0));
      expect(appState.immediateWalletRevenue, equals(0.0));
      expect(appState.immediateBankRevenue, equals(0.0));
      expect(appState.creditSalesRevenue, equals(845.0));

      // Seeded historical credit collections today
      expect(appState.creditCollectedCash, equals(6820.0));
      expect(appState.creditCollectedFonepay, equals(0.0));
      expect(appState.creditCollectedWallet, equals(0.0));
      expect(appState.creditCollectedBank, equals(0.0));
      expect(appState.creditDiscountGiven, equals(0.0));
      expect(appState.staffCreditAddedToAdvance, equals(0.0));

      // Total collection summary
      expect(appState.totalCashCollected, equals(7110.0)); // 290 + 6820
      expect(appState.totalFonepayCollected, equals(250.0));
      expect(appState.totalCollectionsToday, equals(7360.0)); // 7110 + 250
    });

    test('Customer search filters across name, phone, and address', () {
      appState.setCustomerSearchQuery('Himal');
      final matchName = appState.customers.where((c) {
        final q = appState.customerSearchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q);
      }).toList();
      expect(matchName.length, equals(1));
      expect(matchName.first.name, equals('Himal'));

      appState.setCustomerSearchQuery('9846849186');
      final matchPhone = appState.customers.where((c) {
        final q = appState.customerSearchQuery.toLowerCase();
        return c.phone.toLowerCase().contains(q);
      }).toList();
      expect(matchPhone.length, equals(1));
      expect(matchPhone.first.name, equals('Himal'));

      appState.setCustomerSearchQuery('Patan');
      final matchAddress = appState.customers.where((c) {
        final q = appState.customerSearchQuery.toLowerCase();
        return c.address.toLowerCase().contains(q);
      }).toList();
      expect(matchAddress.length, equals(1));
      expect(matchAddress.first.name, equals('Ajaya'));
    });

    test('Add new customer and staff advance tracking', () {
      final initialCount = appState.customers.length;

      // Add regular customer
      appState.addCustomer(
        name: 'Sunil Thapa',
        phone: '9841122334',
        address: 'Baneshwor, Kathmandu',
        initialDue: 500.0,
        isStaff: false,
      );

      expect(appState.customers.length, equals(initialCount + 1));
      final sunil = appState.customers.firstWhere((c) => c.name == 'Sunil Thapa');
      expect(sunil.initials, equals('ST'));
      expect(sunil.totalDue, equals(500.0));
      expect(sunil.isStaff, isFalse);
      expect(sunil.transactions.length, equals(1));
      expect(sunil.transactions.first.orderId, equals('OPENING_DUE'));

      // Add staff member
      appState.addCustomer(
        name: 'Addy Cashier',
        phone: '9801122334',
        address: 'Staff Quarter',
        initialDue: 1200.0,
        isStaff: true,
      );

      final addy = appState.customers.firstWhere((c) => c.name == 'Addy Cashier');
      expect(addy.isStaff, isTrue);
      expect(addy.totalDue, equals(1200.0));

      // Settle staff due as Staff Advance
      appState.settleCustomerCredit(
        customerId: addy.id,
        amount: 1200.0,
        isStaffAdvance: true,
      );

      final addyAfter =
          appState.customers.firstWhere((c) => c.name == 'Addy Cashier');
      expect(addyAfter.totalDue, equals(0.0));
      expect(appState.staffCreditAddedToAdvance, equals(1200.0));
    });

    test('Settle Himal credit due with credit discount and multiple payment methods', () {
      final himal = appState.customers.firstWhere((c) => c.id == 'c_himal');
      expect(himal.totalDue, equals(4890.0));

      // Partial settlement: Rs. 2000 cash + Rs. 90 discount
      appState.settleCustomerCredit(
        customerId: himal.id,
        amount: 2000.0,
        creditDiscount: 90.0,
        method: PaymentMethod.cash,
        note: 'Partial cash payment with discount',
      );

      final himalPartial =
          appState.customers.firstWhere((c) => c.id == 'c_himal');
      expect(himalPartial.totalDue, equals(2800.0)); // 4890 - 2000 - 90 = 2800
      expect(appState.creditCollectedCash, equals(6820.0 + 2000.0)); // 8820.0
      expect(appState.creditDiscountGiven, equals(90.0));

      // Final settlement: Rs. 2800 via Fonepay
      appState.settleCustomerCredit(
        customerId: himal.id,
        amount: 2800.0,
        method: PaymentMethod.fonepay,
        note: 'Full balance payment via Fonepay QR',
      );

      final himalCleared =
          appState.customers.firstWhere((c) => c.id == 'c_himal');
      expect(himalCleared.totalDue, equals(0.0));
      expect(himalCleared.hasDues, isFalse);
      expect(appState.creditCollectedFonepay, equals(2800.0));
      expect(appState.totalFonepayCollected, equals(250.0 + 2800.0)); // 3050.0
    });

    test('Manual due entry adds to customer due and updates credit sales revenue', () {
      final bb = appState.customers.firstWhere((c) => c.id == 'c_bharat_bhanja');
      expect(bb.totalDue, equals(0.0));
      final initialCreditSales = appState.creditSalesRevenue;

      appState.addManualCustomerDue(
        customerId: bb.id,
        amount: 750.0,
        note: 'Past Hookah Tab',
      );

      final bbUpdated =
          appState.customers.firstWhere((c) => c.id == 'c_bharat_bhanja');
      expect(bbUpdated.totalDue, equals(750.0));
      expect(bbUpdated.transactions.first.orderId, equals('MANUAL_DUE'));
      expect(appState.creditSalesRevenue, equals(initialCreditSales + 750.0));
    });

    testWidgets('UI Smoke: Customers Screen, Khata Sheet, and Statement Dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SaanKotApp());
      await tester.pumpAndSettle();

      // Switch to Customers tab
      await tester.tap(find.text('Customers'));
      await tester.pumpAndSettle();

      // Verify Header & Outstanding banner
      expect(find.text('My Customers'), findsOneWidget);
      expect(find.text('Total Outstanding Credit:'), findsOneWidget);
      expect(find.text('Rs. 4890.00'), findsWidgets);

      // Verify customer cards visible
      expect(find.text('Himal'), findsOneWidget);
      expect(find.text('Ajaya'), findsOneWidget);
      expect(find.text('Bharat Bhanja'), findsOneWidget);
      expect(find.text('No Dues'), findsWidgets);

      // Tap on Himal's card to open CustomerKhataSheet
      await tester.tap(find.text('Himal'));
      await tester.pumpAndSettle();

      // Verify sheet content
      expect(find.text('Outstanding Credit Due'), findsOneWidget);
      expect(find.text('Settle Credit / Receive Payment'), findsOneWidget);
      expect(find.text('Full Due (Rs. 4890.00)'), findsOneWidget);
      expect(find.text('Share Statement'), findsOneWidget);
      expect(find.text('Add Due'), findsOneWidget);

      // Tap "Share Statement" to open Statement Preview Dialog
      await tester.tap(find.text('Share Statement'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Statement'), findsOneWidget);
      expect(find.text('Copy Statement'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Test "Full Due" chip populates amount and record settlement
      await tester.tap(find.text('Full Due (Rs. 4890.00)'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Record Settlement'));
      await tester.pumpAndSettle();

      // Verify Himal now shows "All credit cleared" / "Khata Account Status"
      expect(find.text('Khata Account Status'), findsOneWidget);
      expect(find.text('All credit cleared'), findsOneWidget);

      // Close the sheet
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      // Verify on main customer screen, Himal now shows No Dues
      expect(find.text('No Dues'), findsWidgets);
    });
  });
}
