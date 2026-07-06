import 'package:flutter_test/flutter_test.dart';
import 'package:sello/app.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SelloApp());

    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Sello'), findsOneWidget);
  });
}
