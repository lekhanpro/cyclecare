import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cyclecare_flutter/presentation/app.dart';

void main() {
  testWidgets('CycleCareApp renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CycleCareApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
