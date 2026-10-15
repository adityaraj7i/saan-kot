import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/state/app_state.dart';

void main() {
  group('Saan KOT Phase 1 & 2 Seed Data and Table Audit', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('All exact tables are present and correctly seeded', () {
      final tableNames = appState.tables.map((t) => t.name).toList();

      // Check standard tables T1 through T11
      for (int i = 1; i <= 11; i++) {
        expect(tableNames.contains('T$i'), isTrue,
            reason: 'Table T$i should exist');
      }

      // Check named customer/cafe groups
      final expectedNamedTables = [
        'Fancy wala',
        'Masu wala',
        'Parlor wala',
        'Pack',
        'Raj Group',
        'Dipesh Vai',
        'Navin Vaii',
        'Bharat Oli',
        'Ridam',
        'Bijay',
      ];

      for (var name in expectedNamedTables) {
        expect(tableNames.contains(name), isTrue,
            reason: 'Named table/group "$name" should exist');
      }

      // Verify active order ORD-13229 for Fancy wala
      final fancyWalaTable =
          appState.tables.firstWhere((t) => t.name == 'Fancy wala');
      expect(fancyWalaTable.isOccupied, isTrue);
      expect(fancyWalaTable.activeOrderId, equals('ORD-13229'));
      expect(fancyWalaTable.runningTotal, equals(505.0));

      final fancyOrder =
          appState.orders.firstWhere((o) => o.id == 'ORD-13229');
      expect(fancyOrder.tableName, equals('Fancy wala'));
      expect(fancyOrder.payableAmount, equals(505.0));
      expect(fancyOrder.takenByStaff, equals('Addy'));
    });

    test('All 7 required menu categories and items are present with exact prices', () {
      final categories =
          appState.menuItems.map((m) => m.category).toSet().toList();

      final expectedCategories = [
        'Coffee',
        'Cold Beverages',
        'Hookah',
        'Premium Hookah',
        'Momo & Noodles',
        'Smoke',
        'Tea',
      ];

      for (var cat in expectedCategories) {
        expect(categories.contains(cat), isTrue,
            reason: 'Menu category "$cat" must exist');
      }

      // Verify specific items and prices
      final blackCoffee =
          appState.menuItems.firstWhere((m) => m.name == 'Black Coffee');
      expect(blackCoffee.price, equals(50.0));

      final lemonMint =
          appState.menuItems.firstWhere((m) => m.name == 'Lemon Mint Soda');
      expect(lemonMint.price, equals(125.0));

      final chickenMomo =
          appState.menuItems.firstWhere((m) => m.name == 'C. Chicken Momo - Jhol');
      expect(chickenMomo.price, equals(140.0));

      final suryaRed =
          appState.menuItems.firstWhere((m) => m.name == 'Surya Red (Stick)');
      expect(suryaRed.category, equals('Smoke'));
      expect(suryaRed.price, equals(25.0));

      final milkTea = appState.menuItems
          .firstWhere((m) => m.name == 'Milk Tea (Special Dudh Chiya)');
      expect(milkTea.category, equals('Tea'));
      expect(milkTea.price, equals(50.0));
    });

    test('All exact reference customers are present with correct dues', () {
      final customerMap = {for (var c in appState.customers) c.name: c};

      final expectedCustomers = [
        'Ajaya',
        'Bharat Bhanja',
        'Bijay',
        'Gyalzan S',
        'Himal',
        'Jar Wala',
      ];

      for (var name in expectedCustomers) {
        expect(customerMap.containsKey(name), isTrue,
            reason: 'Customer "$name" should exist');
      }

      // Check Himal specifically
      final himal = customerMap['Himal']!;
      expect(himal.totalDue, equals(4890.0));
      expect(himal.initials, equals('H'));

      // Check Ajaya
      final ajaya = customerMap['Ajaya']!;
      expect(ajaya.totalDue, equals(0.0));
      expect(ajaya.initials, equals('A'));

      // Check Bharat Bhanja
      final bb = customerMap['Bharat Bhanja']!;
      expect(bb.initials, equals('BB'));

      // Check Gyalzan S
      final gs = customerMap['Gyalzan S']!;
      expect(gs.initials, equals('GS'));
    });

    testWidgets('UI Smoke: Screen 2 Take Order grid displays new tables',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SaanKotApp());
      await tester.pumpAndSettle();

      // Tap Take Order tab
      await tester.tap(find.text('Take Order'));
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Manage Orders'), findsOneWidget);

      // Verify tables in grid
      expect(find.text('Fancy wala'), findsWidgets);
      expect(find.text('Masu wala'), findsOneWidget);
      expect(find.text('Parlor wala'), findsOneWidget);
      expect(find.text('Raj Group'), findsOneWidget);
      expect(find.text('Dipesh Vai'), findsOneWidget);
      // Filter using search bar to test quick lookup and "+ Add Table" card
      await tester.enterText(find.byType(TextField).first, 'Masu');
      await tester.pumpAndSettle();
      expect(find.text('Masu wala'), findsOneWidget);
      expect(find.text('+ Add Table'), findsOneWidget);
    });
  });
}
