import 'package:flutter_test/flutter_test.dart';
import 'package:smarthome/main.dart'; // only if pubspec.yaml name is smarthome

void main() {
  testWidgets('Shows Login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHomeApp());
    await tester.pumpAndSettle();
    // adjust the expectation to something your app actually shows
    expect(find.text('Login'), findsOneWidget);
  });
}