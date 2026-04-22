import 'package:flutter_test/flutter_test.dart';
import 'package:recruitment/main.dart';

void main() {
  testWidgets('user can open all candidates from dashboard navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Sign in to Portal →'), findsOneWidget);

    await tester.tap(find.text('Sign in to Portal →'));
    await tester.pumpAndSettle();

    expect(find.text('DASHBOARD'), findsOneWidget);

    await tester.tap(find.text('ALL CANDIDATES'));
    await tester.pumpAndSettle();

    expect(find.text('Durgadevi'), findsOneWidget);
    expect(find.text('Showing 1-1 of 1 records'), findsOneWidget);
  });
}
