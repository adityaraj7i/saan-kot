import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/state/app_state.dart';
import 'package:flutter_application_1/state/app_state_scope.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/models/inventory_model.dart';
import 'package:flutter_application_1/screens/inventory/inventory_screen.dart';

void main() {
  group('Phase 5: Analytics Dashboard & Stocks/Inventory Recipe BOM Engine', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('Section 1: Total Revenue Bento Grid figures match reference cafe baseline', () {
      expect(appState.totalRevenue, equals(3070.0));
      expect(appState.totalDiscountsGiven, equals(140.0));
      expect(appState.totalOrdersCount, equals(18));
      expect(double.parse(appState.avgOrderValue.toStringAsFixed(2)), equals(170.56));
    });

    test('Section 2: Payment Collections match reference cafe baseline', () {
      expect(appState.immediateCashRevenue, equals(290.0));
      expect(appState.immediateFonepayRevenue, equals(250.0));
      expect(appState.immediateWalletRevenue, equals(0.0));
      expect(appState.immediateBankRevenue, equals(0.0));
    });

    test('Section 3 & 4: Credit Analytics & Credit Collections Breakdown match reference cafe baseline', () {
      expect(appState.creditSalesRevenue, equals(845.0));
      expect(appState.creditCollectedCash, equals(6820.0));
      expect(appState.creditDiscountGiven, equals(0.0));
      expect(appState.totalPastCreditDues, equals(4890.0));

      expect(appState.creditCollectedFonepay, equals(0.0));
      expect(appState.creditCollectedWallet, equals(0.0));
      expect(appState.creditCollectedBank, equals(0.0));
      expect(appState.staffCreditAddedToAdvance, equals(0.0));
    });

    test('Section 5: Total Collection Summary matches reference cafe baseline', () {
      expect(appState.totalCollectionsToday, equals(7360.0));
      expect(appState.totalCashCollected, equals(7110.0)); // 290 + 6820
      expect(appState.totalFonepayCollected, equals(250.0)); // 250 + 0
      expect(appState.totalWalletCollected, equals(0.0));
      expect(appState.totalBankCollected, equals(0.0));
    });

    test('Section 6: Order Status Summary counts match reference cafe baseline', () {
      expect(appState.totalCompletedOrdersCount, equals(17));
      expect(appState.totalPendingOrdersCount, equals(1));
      expect(appState.totalCancelledOrdersCount, equals(0));
    });

    test('Section 7A: Top Categories Leaderboard & Non-Selling Toggle', () {
      // Top view default
      appState.toggleAnalyticsCategoriesTopOnly(true);
      final topCats = appState.topCategoriesLeaderboard;
      expect(topCats.length, equals(5));

      // 1. Smoke (13 sold, Rs. 300.00)
      expect(topCats[0]['category'], equals('Smoke'));
      expect(topCats[0]['sold'], equals(13));
      expect(topCats[0]['revenue'], equals(300.0));

      // 2. Tea (7 sold, Rs. 230.00)
      expect(topCats[1]['category'], equals('Tea'));
      expect(topCats[1]['sold'], equals(7));
      expect(topCats[1]['revenue'], equals(230.0));

      // 3. Momo & Noodles (4 sold, Rs. 615.00)
      expect(topCats[2]['category'], equals('Momo & Noodles'));
      expect(topCats[2]['sold'], equals(4));
      expect(topCats[2]['revenue'], equals(615.0));

      // 4. Chips (1 sold, Rs. 10.00)
      expect(topCats[3]['category'], equals('Chips'));
      expect(topCats[3]['sold'], equals(1));
      expect(topCats[3]['revenue'], equals(10.0));

      // 5. Hookah (1 sold, Rs. 230.00)
      expect(topCats[4]['category'], equals('Hookah'));
      expect(topCats[4]['sold'], equals(1));
      expect(topCats[4]['revenue'], equals(230.0));

      // Non-Selling categories view
      appState.toggleAnalyticsCategoriesTopOnly(false);
      final nonCats = appState.topCategoriesLeaderboard;
      expect(nonCats.every((c) => (c['sold'] as int) == 0), isTrue);
      expect(nonCats.any((c) => c['category'] == 'Premium Hookah'), isTrue);
      expect(nonCats.any((c) => c['category'] == 'Cold Beverages'), isTrue);
    });

    test('Section 7B: Top Sellings Leaderboard & Non-Selling Toggle', () {
      // Top view default
      appState.toggleAnalyticsItemsTopOnly(true);
      final topItems = appState.topSellingItemsLeaderboard;
      expect(topItems.length, equals(5));

      // 1. Surya Red (8 sold, Rs. 200.00)
      expect(topItems[0]['name'], equals('Surya Red'));
      expect(topItems[0]['sold'], equals(8));
      expect(topItems[0]['revenue'], equals(200.0));

      // 2. Shikhar ice (5 sold, Rs. 100.00)
      expect(topItems[1]['name'], equals('Shikhar ice'));
      expect(topItems[1]['sold'], equals(5));
      expect(topItems[1]['revenue'], equals(100.0));

      // 3. Regular tea (5 sold, Rs. 150.00)
      expect(topItems[2]['name'], equals('Regular tea'));
      expect(topItems[2]['sold'], equals(5));
      expect(topItems[2]['revenue'], equals(150.0));

      // 4. Chiken Keema Noodles (2 sold, Rs. 335.00)
      expect(topItems[3]['name'], equals('Chiken Keema Noodles'));
      expect(topItems[3]['sold'], equals(2));
      expect(topItems[3]['revenue'], equals(335.0));

      // 5. C. Chicken Momo - Jhol (2 sold, Rs. 280.00)
      expect(topItems[4]['name'], equals('C. Chicken Momo - Jhol'));
      expect(topItems[4]['sold'], equals(2));
      expect(topItems[4]['revenue'], equals(280.0));

      // Non-Selling items view
      appState.toggleAnalyticsItemsTopOnly(false);
      final nonItems = appState.topSellingItemsLeaderboard;
      expect(nonItems.every((it) => (it['sold'] as int) == 0), isTrue);
      expect(nonItems.any((it) => it['name'] == 'Night Queen Premium'), isTrue);
    });

    test('Inventory: Pre-seeded with 11 items and exactly 3 low-stock alert items', () {
      expect(appState.inventoryItems.length, equals(11));
      expect(appState.lowStockItemsCount, equals(3));

      final itemMap = {for (var i in appState.inventoryItems) i.id: i};
      expect(itemMap['inv_surya_red']!.isLowStock, isTrue); // 12 <= 20
      expect(itemMap['inv_shikhar']!.isLowStock, isTrue); // 8 <= 15
      expect(itemMap['inv_coffee_beans']!.isLowStock, isTrue); // 450 <= 500
      expect(itemMap['inv_milk']!.isLowStock, isFalse); // 6500 > 2000
    });

    test('Recipe BOM: Order checkout automatically deducts raw ingredient balances and logs entries', () {
      final initialCoffee = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_coffee_beans')
          .currentStock;
      final initialMilk = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_milk')
          .currentStock;
      final initialMomo = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_chicken_momo')
          .currentStock;

      expect(initialCoffee, equals(450.0));
      expect(initialMilk, equals(6500.0));
      expect(initialMomo, equals(120.0));

      // Checkout active order ORD-13229 (Fancy wala)
      appState.checkoutOrder(
        orderId: 'ORD-13229',
        method: PaymentMethod.cash,
        cashGiven: 600.0,
      );

      final updatedCoffee = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_coffee_beans')
          .currentStock;
      final updatedMilk = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_milk')
          .currentStock;
      final updatedMomo = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_chicken_momo')
          .currentStock;

      // Deduction:
      // Milk coffee (15g coffee, 150ml milk) +
      // Iced americano (18g coffee, 1 water) +
      // Cold coffee (15g coffee, 120ml milk) +
      // Blackcoffe double (20g coffee) +
      // Milk (200ml milk) +
      // C. Chicken Momo - Jhol (10 pcs momo)
      // Coffee deducted = 15 + 18 + 15 + 20 = 68g -> 450 - 68 = 382g
      // Milk deducted = 150 + 120 + 200 = 470ml -> 6500 - 470 = 6030ml
      // Momo deducted = 10 pcs -> 120 - 10 = 110 pcs
      expect(updatedCoffee, equals(382.0));
      expect(updatedMilk, equals(6030.0));
      expect(updatedMomo, equals(110.0));

      // Verify stock log entries were created
      final saleLogs = appState.stockLogs
          .where((l) => l.orderId == 'ORD-13229')
          .toList();
      expect(saleLogs.isNotEmpty, isTrue);
      expect(saleLogs.any((l) => l.inventoryItemId == 'inv_coffee_beans'), isTrue);
    });

    test('Inventory: Purchase Stock and Adjust Stock update balances and audit logs', () {
      // 1. Purchase stock
      final initialSurya = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_surya_red')
          .currentStock; // 12
      appState.purchaseStock(
        inventoryItemId: 'inv_surya_red',
        quantity: 50.0,
        cost: 900.0,
        supplierNote: 'Distributor Invoice #891',
      );
      final afterPurchaseSurya = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_surya_red')
          .currentStock;
      expect(afterPurchaseSurya, equals(initialSurya + 50.0)); // 62.0

      final purLog = appState.stockLogs.first;
      expect(purLog.type, equals(StockLogType.purchase));
      expect(purLog.changeAmount, equals(50.0));
      expect(purLog.note, contains('Distributor Invoice #891'));

      // 2. Adjust stock (Wastage / Audit)
      appState.adjustStock(
        inventoryItemId: 'inv_coffee_beans',
        newStock: 350.0,
        reason: 'Spoilage/Wastage',
      );
      final afterAdjustCoffee = appState.inventoryItems
          .firstWhere((i) => i.id == 'inv_coffee_beans')
          .currentStock;
      expect(afterAdjustCoffee, equals(350.0));

      final adjLog = appState.stockLogs.first;
      expect(adjLog.type, equals(StockLogType.adjustmentWastage));
      expect(adjLog.note, contains('Spoilage/Wastage'));
    });

    testWidgets('UI: AnalyticsScreen renders all cards, profile badge A, and Inventory shortcut',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const SaanKotApp());
      await tester.pumpAndSettle();

      // Navigate to Analytics
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      expect(find.text('Analytics Dashboard'), findsOneWidget);
      expect(find.text('A'), findsOneWidget); // Profile avatar
      expect(find.text('Revenue Overview'), findsOneWidget);
      expect(find.text('Stocks & Recipe BOM Engine'), findsOneWidget);
      expect(find.text('Payment Collections'), findsOneWidget);
      expect(find.text('Credit Analytics (Khata)'), findsOneWidget);
      expect(find.text('Credit Collections Breakdown'), findsOneWidget);
      expect(find.text('Total Collection Summary'), findsOneWidget);
      expect(find.text('Order Status Summary'), findsOneWidget);
      expect(find.text('Top Categories'), findsAtLeast(1));
      expect(find.text('Top Sellings Leaderboard'), findsAtLeast(1));

      // Verify date range pills
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('UI: InventoryScreen renders 4 tabs and opens purchase sheet',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const InventoryScreen(),
          builder: (ctx, child) => AppStateScope(
            notifier: appState,
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stocks & Inventory (BOM)'), findsOneWidget);
      expect(find.text('All Stock'), findsOneWidget);
      expect(find.text('Low / Out (3)'), findsOneWidget);
      expect(find.text('Recipes (BOM)'), findsOneWidget);
      expect(find.text('Stock Log'), findsOneWidget);

      // Open + Purchase Sheet
      await tester.tap(find.text('+ Purchase'));
      await tester.pumpAndSettle();

      expect(find.text('Restock / Purchase Stock'), findsOneWidget);
      expect(find.text('Confirm Stock Purchase'), findsOneWidget);
    });
  });
}
