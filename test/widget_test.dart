import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_campus/main.dart';

void main() {
  testWidgets('Smoke test aplikasi', (WidgetTester tester) async {
    await tester.pumpWidget(const LostAndFoundApp());
  });
}
