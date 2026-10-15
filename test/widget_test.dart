import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Saan KOT Smoke Test - Bottom navigation & Order history loads',
      (WidgetTester tester) async {
    // Build SaanKotApp and trigger a frame.
    await tester.pumpWidget(const SaanKotApp());
    await tester.pumpAndSettle();

    // Verify 4 main bottom navigation items are displayed
    expect(find.text('Bills'), findsWidgets);
    expect(find.text('Take Order'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);

    // Verify initial Order History screen loads with pre-populated order
    expect(find.text('Order History'), findsOneWidget);
    expect(find.textContaining('Fancy wala'), findsWidgets);
  });
}
