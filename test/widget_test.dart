import 'package:flutter_test/flutter_test.dart';

import 'package:campus_supply/main.dart';

void main() {
  testWidgets('Campus Supply app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusSupplyApp());

    // Allow the initial splash animation/timer to start.
    await tester.pump();

    expect(find.byType(CampusSupplyApp), findsOneWidget);
  });
}
