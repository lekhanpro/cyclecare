import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyclecare/features/app/cyclecare_app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CycleCareApp()),
    );
    await tester.pump(const Duration(seconds: 1));
    // App should render something (splash or home)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
