import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare/features/app/cyclecare_app.dart';

void main() {
  testWidgets('CycleCareApp renders MaterialApp', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CycleCareApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
