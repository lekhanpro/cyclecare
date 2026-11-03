import 'dart:convert';
import 'package:cyclecare/features/tracking/presentation/health_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../shots/shot_harness.dart';

void main() {
  testWidgets(
    'report preview defaults private and copies exactly the opted-in preview',
    (tester) async {
      final seed = ShotSeed.typical();
      final logs =
          jsonDecode(seed['cyclecare.daily_logs.v1'] as String) as List;
      (logs.first as Map<String, dynamic>).addAll(<String, dynamic>{
        'medicineTaken': true,
        'medicineName': 'Private medicine',
        'pregnancyTest': 'Positive',
        'testNote': 'Private observation',
      });
      seed['cyclecare.daily_logs.v1'] = jsonEncode(logs);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData')
            copied = (call.arguments as Map)['text'] as String;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpShotScreen(
        tester,
        const HealthReportScreen(),
        prefs: seed,
        height: 1800,
      );
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(checkbox.value, isFalse);
      }
      await tester.tap(find.text('Preview report'));
      await settleShot(tester);
      var preview = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      expect(preview, isNot(contains('Private medicine')));
      expect(preview, isNot(contains('Private observation')));
      expect(preview, isNot(contains('ESTIMATES —')));
      expect(copied, isNull);
      await tester.tap(find.text('Edit selection'));
      await settleShot(tester);
      await tester.tap(find.text('Include medication'));
      await tester.tap(find.text('Include reproductive observations'));
      await tester.tap(find.text('Include calendar estimate'));
      await tester.tap(find.text('Preview report'));
      await settleShot(tester);
      preview = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      expect(preview, contains('Private medicine'));
      expect(preview, contains('Private observation'));
      expect(preview, contains('ESTIMATES —'));
      expect(copied, isNull);
      await tester.tap(find.text('Copy report'));
      await settleShot(tester);
      expect(copied, preview);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
