import 'package:cyclecare/features/tracking/domain/cycle_analytics.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 2, 1);
  final temperatures = [
    36.40,
    36.42,
    36.38,
    36.41,
    36.39,
    36.40,
    36.65,
    36.68,
    36.70,
  ];
  List<DailyLog> readings() => [
    for (var i = 0; i < temperatures.length; i++)
      DailyLog(
        date: start.add(Duration(days: i)),
        temperatureCelsius: temperatures[i],
        temperatureContext: const ['Usual conditions'],
      ),
  ];
  TemperatureAnalysis analyse(List<DailyLog> logs) => CycleAnalytics(
    periods: [CycleEvent(id: 'cycle', startDate: start)],
    logs: logs,
    preferences: const CyclePreferences(),
  ).temperatureAnalysis(reference: start.add(const Duration(days: 12)));

  test('explicit usual conditions allow descriptive rise pattern', () {
    final result = analyse(readings());
    expect(result.points, hasLength(9));
    expect(result.coverline, closeTo(36.52, 0.001));
    expect(result.thermalShiftDay, 7);
  });

  test(
    'missing context stays unknown and cannot establish undisturbed pattern',
    () {
      final result = analyse(
        readings()
            .map((log) => log.copyWith(temperatureContext: const []))
            .toList(),
      );
      expect(result.points, hasLength(9));
      expect(result.points.every((point) => point.context.isEmpty), isTrue);
      expect(result.coverline, isNull);
      expect(result.thermalShiftDay, isNull);
    },
  );

  for (final context in [
    'Disrupted sleep',
    'Illness or fever',
    'Different measurement time',
    'Alcohol',
    'Other disturbance',
  ]) {
    test(
      '$context reading remains visible but cannot complete rise window',
      () {
        final logs = readings();
        logs[7] = logs[7].copyWith(temperatureContext: [context]);
        final result = analyse(logs);
        expect(result.points, hasLength(9));
        expect(result.points[7].celsius, 36.68);
        expect(result.points[7].context, [context]);
        expect(result.thermalShiftDay, isNull);
        expect(result.coverline, isNull);
      },
    );
  }

  test('usual conditions combined with disturbance is not undisturbed', () {
    final logs = readings();
    logs[6] = logs[6].copyWith(
      temperatureContext: const ['Usual conditions', 'Illness or fever'],
    );
    expect(analyse(logs).thermalShiftDay, isNull);
  });

  for (final missingIndex in [2, 7]) {
    test(
      'missing day $missingIndex cannot be compressed into consecutive readings',
      () {
        final logs = readings()..removeAt(missingIndex);
        // Add a later reading so there are still nine points: count alone is
        // insufficient when the six baseline and three high days have a gap.
        logs.add(
          DailyLog(
            date: start.add(const Duration(days: 10)),
            temperatureCelsius: 36.72,
            temperatureContext: const ['Usual conditions'],
          ),
        );
        final result = analyse(logs);
        expect(result.points, hasLength(9));
        expect(result.thermalShiftDay, isNull);
        expect(result.coverline, isNull);
      },
    );
  }

  test(
    'future and prior-cycle readings do not enter current descriptive pattern',
    () {
      final result = analyse([
        DailyLog(
          date: start.subtract(const Duration(days: 1)),
          temperatureCelsius: 39.0,
          temperatureContext: const ['Illness or fever'],
        ),
        ...readings(),
        DailyLog(
          date: start.add(const Duration(days: 13)),
          temperatureCelsius: 39.0,
          temperatureContext: const ['Illness or fever'],
        ),
      ]);
      expect(result.points, hasLength(9));
      expect(result.points.every((point) => point.celsius < 37), isTrue);
      expect(result.thermalShiftDay, 7);
    },
  );
}
