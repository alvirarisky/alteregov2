import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alterego_app/main.dart';

void main() {
  testWidgets('Select persona from Home opens Chat tab', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Choose a persona'), findsOneWidget);

    await tester.tap(find.text('Past Self'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Chat'), findsWidgets);
    expect(find.text('Talking to: Past Self'), findsOneWidget);
  });
}
