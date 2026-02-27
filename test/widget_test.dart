import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('app boots and shows Arabic title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('وريد'), findsOneWidget);
  });
}

