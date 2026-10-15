import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/services/thermal_printer_service.dart';
import 'package:flutter_application_1/models/menu_item_model.dart';
import 'package:flutter_application_1/models/order_model.dart';
import 'package:flutter_application_1/state/app_state.dart';
import 'package:flutter_application_1/state/app_state_scope.dart';
import 'package:flutter_application_1/screens/analytics/settings_sheet.dart';
import 'package:flutter_application_1/screens/analytics/analytics_screen.dart';
import 'package:flutter_application_1/screens/bills/bills_screen.dart';

void main() {
  group('Phase 6: Thermal Printer & Formatter Engine Tests', () {
    test('ThermalFormatter produces exact 32-column lines for 58mm KOT', () {
      final kot = KotPrintData(
        kotNumber: 'KOT #1042',
        tableName: 'Fancy wala',
        serverName: 'Addy',
        timestamp: DateTime(2026, 10, 8, 16, 56),
        items: [
          OrderLineItem(
            item: MenuItem(
              id: 'm1',
              name: 'Milk coffee',
              category: 'Coffee',
              price: 55.0,
              code: 'COF-01',
            ),
            quantity: 2,
          ),
          OrderLineItem(
            item: MenuItem(
              id: 'm12',
              name: 'C. Chicken Momo - Jhol',
              category: 'Momo & Noodles',
              price: 140.0,
              code: 'MOM-01',
            ),
            quantity: 1,
          ),
        ],
        notes: 'Extra spicy jhol',
      );

      final output = ThermalFormatter.formatKot(kot, paperSize: PaperSize.mm58);

      expect(output.contains('*** SAAN KOT ***'), isTrue);
      expect(output.contains('KITCHEN ORDER TICKET'), isTrue);
      expect(output.contains('FANCY WALA'), isTrue);
      expect(output.contains('KOT #1042'), isTrue);
      expect(output.contains('Addy'), isTrue);
      expect(output.contains('x2'), isTrue);
      expect(output.contains('x1'), isTrue);
      expect(output.contains('NOTE: Extra spicy jhol'), isTrue);

      // Verify each non-empty line does not exceed 32 characters
      final lines = output.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          expect(line.length, lessThanOrEqualTo(32),
              reason: 'Line exceeds 32 chars: "$line"');
        }
      }
    });

    test('ThermalFormatter produces exact 48-column lines for 80mm Customer Receipt', () {
      final order = OrderModel(
        id: 'ORD-13229',
        tableName: 'Fancy wala',
        takenByStaff: 'Addy',
        createdAt: DateTime(2026, 10, 8, 16, 56),
        items: [
          OrderLineItem(
            item: MenuItem(
              id: 'm1',
              name: 'Milk coffee',
              category: 'Coffee',
              price: 55.0,
              code: 'COF-01',
            ),
            quantity: 1,
          ),
          OrderLineItem(
            item: MenuItem(
              id: 'm12',
              name: 'C. Chicken Momo - Jhol',
              category: 'Momo & Noodles',
              price: 140.0,
              code: 'MOM-01',
            ),
            quantity: 1,
          ),
        ],
      );

      final output = ThermalFormatter.formatCustomerReceipt(
        order,
        paperSize: PaperSize.mm80,
        cafeName: 'SAAN CAFE & LOUNGE',
        branch: 'Kathmandu Main Branch',
        panNumber: '609823412',
        serverName: 'Addy',
      );

      expect(output.contains('SAAN CAFE & LOUNGE'), isTrue);
      expect(output.contains('Kathmandu Main Branch'), isTrue);
      expect(output.contains('VAT / PAN: 609823412'), isTrue);
      expect(output.contains('ORD-13229'), isTrue);
      expect(output.contains('Fancy wala'), isTrue);
      expect(output.contains('Addy'), isTrue);
      expect(output.contains('Rs. 195.00'), isTrue);

      final lines = output.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          expect(line.length, lessThanOrEqualTo(48),
              reason: 'Line exceeds 48 chars: "$line"');
        }
      }
    });

    test('ThermalFormatter formats End-of-Day Z-Report matching exact reference metrics', () {
      final zReport = ThermalFormatter.formatZReport(
        totalRevenue: 3070.0,
        totalDiscount: 140.0,
        totalOrders: 18,
        cashRevenue: 290.0,
        fonepayRevenue: 250.0,
        walletRevenue: 0.0,
        bankRevenue: 0.0,
        creditSales: 845.0,
        creditCollectedCash: 6820.0,
        totalDrawerCash: 7110.0,
        totalCollection: 7360.0,
        lowStockCount: 3,
        paperSize: PaperSize.mm80,
        cashier: 'Addy',
      );

      expect(zReport.contains('END-OF-DAY Z-REPORT'), isTrue);
      expect(zReport.contains('Rs. 3070.00'), isTrue);
      expect(zReport.contains('Rs. 140.00'), isTrue);
      expect(zReport.contains('Rs. 290.00'), isTrue);
      expect(zReport.contains('Rs. 250.00'), isTrue);
      expect(zReport.contains('Rs. 6820.00'), isTrue);
      expect(zReport.contains('Rs. 7110.00'), isTrue);
      expect(zReport.contains('Rs. 7360.00'), isTrue);
      expect(zReport.contains('3 item(s)'), isTrue);
    });

    test('EscPosGenerator produces valid ESC/POS byte sequence', () {
      const sampleText = 'TEST RECEIPT\n';
      final bytes = EscPosGenerator.generateBytes(sampleText, cut: true);

      // Verify ESC @ (0x1B, 0x40) init
      expect(bytes[0], equals(0x1B));
      expect(bytes[1], equals(0x40));

      // Verify paper cut command (GS V 65 16: 0x1D, 0x56, 0x41, 0x10)
      final len = bytes.length;
      expect(bytes[len - 4], equals(0x1D));
      expect(bytes[len - 3], equals(0x56));
      expect(bytes[len - 2], equals(0x41));
      expect(bytes[len - 1], equals(0x10));
    });
  });

  group('Phase 6: Multi-Tenant State & Baseline Reset Tests', () {
    test('AppState initializes with reference cafe multi-tenant context', () {
      final appState = AppState();

      expect(appState.tenantName, equals('Saan Cafe & Lounge'));
      expect(appState.tenantId, equals('tnt_ktm_001'));
      expect(appState.activeBranch, equals('Kathmandu Main Branch'));
      expect(appState.activeStaff, equals('Addy'));
      expect(appState.printerPaperSize, equals(PaperSize.mm58));
      expect(appState.printerConnectionMode, equals(PrinterConnectionMode.bluetooth));
      expect(appState.autoCutPaper, isTrue);
    });

    test('AppState resetToBaselineData restores all entities and financial counters', () {
      final appState = AppState();

      // Mutate state
      appState.checkoutOrder(
        orderId: 'ORD-13229',
        method: PaymentMethod.cash,
        cashGiven: 600.0,
      );
      expect(appState.orders.where((o) => o.status == OrderStatus.pending).isEmpty, isTrue);

      // Reset to baseline
      appState.resetToBaselineData();

      // Verify baseline restoration
      final pendingOrders = appState.orders.where((o) => o.status == OrderStatus.pending).toList();
      expect(pendingOrders.length, equals(1));
      expect(pendingOrders.first.id, equals('ORD-13229'));
      expect(pendingOrders.first.tableName, equals('Fancy wala'));
      expect(pendingOrders.first.payableAmount, equals(505.0));

      // Verify financial metrics
      expect(appState.immediateCashRevenue, equals(290.0));
      expect(appState.immediateFonepayRevenue, equals(250.0));
      expect(appState.creditCollectedCash, equals(6820.0));
      expect(appState.totalCollectionsToday, equals(7360.0));
      expect(appState.totalPastCreditDues, equals(4890.0));
    });
  });

  group('Phase 6: UI Widget Previews & Modal Wiring Tests', () {
    testWidgets('ThermalReceiptPreviewModal renders paper preview and toggles size',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ThermalReceiptPreviewModal.show(
                    context: context,
                    title: 'Customer Receipt',
                    subtitle: 'Fancy wala • ORD-13229',
                    formattedText58mm: '58MM TEST CONTENT',
                    formattedText80mm: '80MM TEST CONTENT',
                    initialPaperSize: PaperSize.mm58,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Receipt'), findsOneWidget);
      expect(find.text('Fancy wala • ORD-13229'), findsOneWidget);
      expect(find.text('58MM TEST CONTENT'), findsOneWidget);

      // Tap 80mm size chip
      await tester.tap(find.text('80mm'));
      await tester.pumpAndSettle();

      expect(find.text('80MM TEST CONTENT'), findsOneWidget);
      expect(find.text('Print to Thermal'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
    });

    testWidgets('SettingsSheet renders multi-tenant and printer controls',
        (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Branch & Printer Settings'), findsOneWidget);
      expect(find.text('Saan Cafe & Lounge'), findsOneWidget);
      expect(find.text('Tenant ID: tnt_ktm_001'), findsOneWidget);
      expect(find.text('Test Print Sample KOT', skipOffstage: false), findsOneWidget);
      expect(find.text('Reset Demo Data to Baseline', skipOffstage: false), findsOneWidget);
      expect(find.text('All records synced • Offline-First Ready', skipOffstage: false), findsOneWidget);
    });

    testWidgets('AnalyticsScreen top PDF button opens End-of-Day Z-Report Modal',
        (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: const MaterialApp(
            home: AnalyticsScreen(),
          ),
        ),
      );

      // Tap top-left PDF export icon
      final pdfIconFinder = find.byTooltip('End-of-Day Z-Report');
      expect(pdfIconFinder, findsOneWidget);

      await tester.tap(pdfIconFinder);
      await tester.pumpAndSettle();

      // Verify Z-Report modal opens
      expect(find.text('End-of-Day Z-Report'), findsOneWidget);
      expect(find.textContaining('Terminal #01'), findsOneWidget);
      expect(find.text('Print to Thermal'), findsOneWidget);
    });

    testWidgets('BillsScreen top PDF button opens Daily Order Register Report',
        (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          notifier: appState,
          child: const MaterialApp(
            home: BillsScreen(),
          ),
        ),
      );

      // Tap top PDF export icon
      final pdfIconFinder = find.byTooltip('Daily Order Register');
      expect(pdfIconFinder, findsOneWidget);

      await tester.tap(pdfIconFinder);
      await tester.pumpAndSettle();

      // Verify Daily Order Register Modal opens
      expect(find.text('Daily Order Register Report'), findsOneWidget);
      expect(find.textContaining('Pending'), findsWidgets);
      expect(find.textContaining('Completed'), findsWidgets);
      expect(find.text('Copy Register'), findsOneWidget);
    });
  });
}
