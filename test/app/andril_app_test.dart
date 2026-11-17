import 'package:flutter_test/flutter_test.dart';
import 'package:andril_mobile/app/andril_app.dart';

void main() {
  testWidgets('starter shell identifies all three product modules', (tester) async {
    await tester.pumpWidget(const AndrilApp());
    expect(find.text('Learning  •  Hobbies  •  Social'), findsOneWidget);
    expect(find.text('ANDRIL'), findsOneWidget);
    expect(find.text('Flutter folder structure scaffold'), findsOneWidget);
  });
}
