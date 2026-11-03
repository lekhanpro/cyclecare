import 'package:cyclecare/features/tracking/domain/cycle_analytics.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/insights_extras.dart';
import 'package:flutter_test/flutter_test.dart';

/// Five period starts, so four completed cycles of 28, 30, 26 and 28 days:
///   Jan 1 → Jan 29 → Feb 28 → Mar 26 → Apr 23 (in progress)
final _starts = [
  DateTime(2026, 1, 1),
  DateTime(2026, 1, 29),
  DateTime(2026, 2, 28),
  DateTime(2026, 3, 26),
  DateTime(2026, 4, 23),
];

CycleAnalytics _analytics({List<DailyLog> logs = const [], int cycles = 5}) {
  final starts = _starts.take(cycles).toList();
  return CycleAnalytics(
    periods: [
      for (var i = 0; i < starts.length; i++)
        CycleEvent(
          id: 'p$i',
          startDate: starts[i],
          endDate: starts[i].add(const Duration(days: 4)),
        ),
    ],
    logs: logs,
    preferences: const CyclePreferences(),
  );
}

void main() {
  group('regularityScore', () {
    test('a 4-day range is regular, with the numbers behind it', () {
      final r = regularityScore(_analytics())!;
      expect(r.bucket, Regularity.regular);
      expect(r.cycles, 4);
      expect(r.shortest, 26);
      expect(r.longest, 30);
      expect(r.spreadDays, closeTo(1.414, 0.01));
    });

    test('needs at least three completed cycles', () {
      expect(regularityScore(_analytics(cycles: 3)), isNull); // 2 cycles
      expect(regularityScore(_analytics(cycles: 4)), isNotNull); // 3 cycles
    });
  });

  group('predictionAccuracy', () {
    test('replays each cycle against the live predictor with earlier history', () {
      final p = predictionAccuracy(_analytics())!;
      // Cycle 3 predicted from mean(28, 30) = 29, actual 26: three days early.
      // Cycle 4 predicted from mean(28, 30, 26) = 28, actual 28: exact.
      expect(p.checks.map((c) => c.errorDays), [-3, 0]);
      expect(p.averageAbsoluteError, 1.5);
      expect(p.withinTwoDays, 1);
    });
  });

  group('by phase', () {
    // Jan 2-4 are cycle days 2-4: inside the 5-day period, so menstrual.
    final logs = [
      DailyLog(date: DateTime(2026, 1, 2), mood: 'Tired', sleepHours: 6),
      DailyLog(
          date: DateTime(2026, 1, 3), mood: 'Tired', sleepHours: 8, waterMl: 1500),
      DailyLog(date: DateTime(2026, 1, 4), mood: 'Calm'),
      // Inside the cycle still in progress: no completed cycle, no phase.
      DailyLog(date: DateTime(2026, 4, 24), mood: 'Happy', sleepHours: 2),
    ];

    test('mood shares per phase', () {
      final m = moodByPhase(_analytics(logs: logs));
      expect(m.keys, [CyclePhase.menstrual]);
      expect(m[CyclePhase.menstrual]!['Tired'], closeTo(2 / 3, 1e-9));
      expect(m[CyclePhase.menstrual]!['Calm'], closeTo(1 / 3, 1e-9));
    });

    test('sleep averages with the day count, ignoring unphased logs', () {
      final s = sleepByPhase(_analytics(logs: logs))[CyclePhase.menstrual]!;
      expect(s.value, 7);
      expect(s.days, 2);
    });

    test('zero water is treated as not logged', () {
      final w = waterByPhase(_analytics(logs: logs))[CyclePhase.menstrual]!;
      expect(w.value, 1500);
      expect(w.days, 1);
    });
  });

  group('symptomHeatmap', () {
    test('counts each symptom by cycle day, most logged first', () {
      final logs = [
        for (final start in _starts.take(4))
          DailyLog(date: start, symptoms: const ['Cramps']),
        DailyLog(date: DateTime(2026, 1, 10), symptoms: const ['Headache']),
      ];
      final h = symptomHeatmap(_analytics(logs: logs))!;
      expect(h.symptoms, ['Cramps', 'Headache']);
      expect(h.cycleLength, 28);
      expect(h.cycles, 4);
      expect(h.counts['Cramps']![0], 4); // day 1 in every cycle
      expect(h.counts['Headache']![9], 1); // Jan 10 is cycle day 10
    });

    test('is null with no symptoms logged', () {
      expect(symptomHeatmap(_analytics()), isNull);
    });
  });

  test('cycleComparison is like for like up to today', () {
    final logs = [
      for (final start in _starts.take(4))
        DailyLog(date: start, symptoms: const ['Cramps'], painLevel: 4),
      DailyLog(date: _starts[4], symptoms: const ['Cramps'], painLevel: 6),
    ];
    final c = cycleComparison(
      _analytics(logs: logs),
      today: DateTime(2026, 4, 25),
    )!;
    expect(c.dayToday, 3);
    expect(c.averageLength, 28);
    expect(c.symptomDaysThisCycle, 1);
    expect(c.averageSymptomDaysByNow, 1);
    expect(c.averagePainThisCycle, 6);
    expect(c.averagePainOverall, closeTo(4.4, 1e-9));
  });

  test('cycleComparison skips past cycles with nothing logged', () {
    // Only the first cycle has a log in its first three days.
    final logs = [
      DailyLog(date: _starts[0], symptoms: const ['Cramps']),
      DailyLog(date: _starts[4], symptoms: const ['Cramps']),
    ];
    final c = cycleComparison(
      _analytics(logs: logs),
      today: DateTime(2026, 4, 25),
    )!;
    expect(c.averageSymptomDaysByNow, 1); // not 0.25 from three empty cycles
  });

  test('cycleComparison has no usual value when no past cycle was logged',
      () {
    final logs = [DailyLog(date: _starts[4], symptoms: const ['Cramps'])];
    final c = cycleComparison(
      _analytics(logs: logs),
      today: DateTime(2026, 4, 25),
    )!;
    expect(c.averageSymptomDaysByNow, isNull);
  });

  test('loggingPerCycle counts distinct days, oldest first', () {
    final logs = [
      DailyLog(date: DateTime(2026, 1, 2)),
      DailyLog(date: DateTime(2026, 1, 3)),
      DailyLog(date: DateTime(2026, 1, 3, 20)), // same day twice
      DailyLog(date: DateTime(2026, 2, 1)),
    ];
    final l = loggingPerCycle(_analytics(logs: logs));
    expect(l.map((c) => c.daysLogged), [2, 1, 0, 0]);
    expect(l.first.share, closeTo(2 / 28, 1e-9));
  });
}
