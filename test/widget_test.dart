// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:mono/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MonoApp());

    // Verify that app title is shown
    expect(find.text('Mono'), findsOneWidget);
  });
}
