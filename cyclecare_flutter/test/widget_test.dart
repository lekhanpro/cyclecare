import 'package:flutter_test/flutter_test.dart';

import 'package:cyclecare_flutter/features/app/cyclecare_app.dart';

void main() {
  testWidgets('CycleCare app smoke test', (tester) async {
    await tester.pumpWidget(const CycleCareApp());
    await tester.pump();
    expect(find.text('CycleCare'), findsWidgets);
  });
}
