import 'dart:convert';

import 'package:cyclecare/features/tracking/data/cycle_repository.dart';
import 'package:cyclecare/features/tracking/domain/cycle_health_report.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/daily_log_validator.dart';
import 'package:cyclecare/features/tracking/domain/record_summaries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final start = DateTime(2026, 9, 1), end = DateTime(2026, 9, 30);
  final periods = [
    CycleEvent(id: 'a', startDate: start, excludeFromPredictions: true),
    CycleEvent(
      id: 'b',
      startDate: DateTime(2026, 9, 29),
      endDate: DateTime(2026, 10, 3),
    ),
  ];
  final logs = [
    DailyLog(
      date: start,
      flow: FlowIntensity.none,
      painLevel: 0,
      symptoms: const ['Cramps'],
      painInterference: 'No interference',
      medicineTaken: true,
      medicineName: 'sensitive medication',
      medicineDose: 'private dose',
      pregnancyTest: 'Positive',
      ovulationTest: 'Unclear',
      testNote: 'private test note',
      temperatureCelsius: 36.5,
      temperatureContext: const ['Disrupted sleep'],
    ),
    DailyLog(date: DateTime(2026, 9, 2), painInterference: 'Not sure'),
    DailyLog(
      date: DateTime(2026, 9, 29),
      symptoms: const ['Cramps'],
      painInterference: 'Some activities harder',
    ),
  ];

  test(
    'report defaults private, preserving unknown, zero and observation counts',
    () {
      final text = buildCycleHealthReport(
        periods: periods,
        logs: logs,
        options: HealthReportOptions(
          start: start,
          end: end,
          symptoms: const {'Cramps'},
        ),
      );
      expect(text, contains('duration unknown'));
      expect(text, contains('bleeding: None | pain: 0/10'));
      expect(text, contains('3 of 30 days'));
      expect(text, contains('forecast learning excluded'));
      expect(text, contains('logged in 2 of 2 observed cycles'));
      expect(text, contains('1 of 2 assessed days; 1 uncertain'));
      for (final secret in [
        'sensitive medication',
        'private dose',
        'Positive',
        'private test note',
        '36.5',
        'ESTIMATES',
      ]) {
        expect(text, isNot(contains(secret)));
      }
    },
  );

  test(
    'sensitive observations require explicit selection and dates limit entries',
    () {
      final text = buildCycleHealthReport(
        periods: periods,
        logs: logs,
        options: HealthReportOptions(
          start: start,
          end: start,
          includeMedication: true,
          includeTests: true,
          includeEstimates: true,
        ),
      );
      expect(text, contains('sensitive medication'));
      expect(text, contains('LH Unclear; pregnancy test Positive'));
      expect(text, contains('Disrupted sleep'));
      expect(text, contains('ESTIMATES'));
      expect(text, isNot(contains('2026-09-29 |')));
    },
  );

  test(
    'old periods with unknown end do not appear in an unrelated report range',
    () {
      final text = buildCycleHealthReport(
        periods: [CycleEvent(id: 'old', startDate: DateTime(2020, 1, 1))],
        logs: [],
        options: HealthReportOptions(start: start, end: end),
      );
      expect(text, isNot(contains('2020-01-01')));
    },
  );

  test(
    'blank symptom fields never mean symptom-free and comparisons retain coverage',
    () {
      final result = symptomCycleSummaries(periods, [
        ...logs,
        DailyLog(date: DateTime(2026, 9, 3), waterMl: 500),
      ]).single;
      expect(result.observedDays, 2);
      expect(result.observedCycles, 2);
      expect(result.byCycleDay, {1: 2});
      expect(result.beforeNextPeriod, {28: 1});
      expect(result.cycleCounts.values, everyElement(1));
      expect(result.cycleObservedDays.values, everyElement(1));
    },
  );

  test(
    'context and impact round trip; old schema-2 zero stays recorded',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = CycleRepository(await SharedPreferences.getInstance());
      await repository.saveLogs(logs);
      final restored = repository.loadLogs().first;
      expect(restored.painInterference, 'No interference');
      expect(restored.temperatureContext, ['Disrupted sleep']);
      expect(
        restored.copyWith(painInterference: null).painInterference,
        isNull,
      );
      expect(DailyLogValidator.validate(restored), isEmpty);
      final backup =
          jsonDecode(await repository.exportJson()) as Map<String, dynamic>;
      expect((backup['dailyLogs'] as List).first['temperatureContext'], [
        'Disrupted sleep',
      ]);
      final old = DailyLog.fromJson({
        'schema': 2,
        'date': start.toIso8601String(),
        'painLevel': 0,
      });
      expect(old.painLevel, 0);
      expect(old.painInterference, isNull);
      expect(old.temperatureContext, isEmpty);
    },
  );

  test('unknown new choices fail validation without changing observations', () {
    final log = DailyLog(
      date: start,
      painInterference: 'invented',
      temperatureContext: const ['invented'],
    );
    expect(
      DailyLogValidator.validate(log).map((i) => i.field),
      containsAll(['painInterference', 'temperatureContext']),
    );
  });
}
