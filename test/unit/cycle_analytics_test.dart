import 'package:cyclecare/features/tracking/domain/cycle_analytics.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prefs = CyclePreferences(
    averageCycleLength: 28,
    averagePeriodLength: 5,
    lutealPhaseLength: 14,
  );

  /// A fixed reference point, so nothing here depends on the day the suite runs.
  final anchor = DateTime(2026, 6, 1);

  CycleEvent period(int daysBeforeAnchor, {int? length}) {
    final start = anchor.subtract(Duration(days: daysBeforeAnchor));
    return CycleEvent(
      id: 'p$daysBeforeAnchor',
      startDate: start,
      endDate: length == null ? null : start.add(Duration(days: length - 1)),
    );
  }

  DailyLog log(
    int daysBeforeAnchor, {
    List<String> symptoms = const [],
    String? mood,
    int pain = 0,
    double? temperature,
    double? weight,
  }) {
    return DailyLog(
      date: anchor.subtract(Duration(days: daysBeforeAnchor)),
      symptoms: symptoms,
      mood: mood,
      painLevel: pain,
      temperatureCelsius: temperature,
      weightKg: weight,
    );
  }

  group('cycleHistory', () {
    test('is empty until two periods exist', () {
      final analytics = CycleAnalytics(
        periods: [period(2, length: 5)],
        logs: const [],
        preferences: prefs,
      );
      expect(analytics.cycleHistory(), isEmpty);
    });

    test('measures each completed cycle and excludes the in-progress one', () {
      final analytics = CycleAnalytics(
        // Starts at 2, 30 and 58 days ago: two completed cycles of 28 days.
        periods: [
          period(2, length: 5),
          period(30, length: 4),
          period(58, length: 6),
        ],
        logs: const [],
        preferences: prefs,
      );

      final history = analytics.cycleHistory();
      expect(history.length, 2);
      expect(history.every((record) => record.length == 28), isTrue);
      // Newest completed cycle first.
      expect(history.first.start.isAfter(history.last.start), isTrue);
      expect(history.first.periodLength, 4);
    });

    test('drops implausible gaps rather than reporting them as cycles', () {
      final analytics = CycleAnalytics(
        periods: [period(2), period(30), period(430)],
        logs: const [],
        preferences: prefs,
      );
      expect(analytics.cycleHistory().length, 1);
    });

    test('deviation is measured against the supplied average', () {
      final analytics = CycleAnalytics(
        periods: [period(0), period(31)],
        logs: const [],
        preferences: prefs,
      );
      expect(analytics.cycleHistory().single.deviationFrom(28), 3);
    });
  });

  group('symptomPatterns', () {
    test('needs a full cycle of context before reporting anything', () {
      final analytics = CycleAnalytics(
        periods: [period(2)],
        logs: [log(1, symptoms: ['Cramps'])],
        preferences: prefs,
      );
      expect(analytics.symptomPatterns(), isEmpty);
    });

    test('detects a symptom concentrated in the menstrual phase', () {
      // One 28-day cycle starting 30 days before the anchor. Days 1-5 are
      // menstrual, so logs 30..26 days ago fall in that phase.
      final analytics = CycleAnalytics(
        periods: [period(2), period(30)],
        logs: [
          log(30, symptoms: ['Cramps']),
          log(29, symptoms: ['Cramps']),
          log(28, symptoms: ['Cramps']),
          log(27, symptoms: ['Cramps']),
          log(26, symptoms: ['Cramps']),
        ],
        preferences: prefs,
      );

      final pattern = analytics
          .symptomPatterns()
          .firstWhere((p) => p.symptom == 'Cramps');

      expect(pattern.dominantPhase, CyclePhase.menstrual);
      expect(pattern.occurrences, 5);
      expect(pattern.shareInDominantPhase, 1.0);
      // Menstrual days are 5 of 28, so a symptom appearing only there is
      // roughly 5.6x more likely than chance.
      expect(pattern.lift, greaterThan(4));
      expect(pattern.isMeaningful, isTrue);
    });

    test('a symptom spread evenly across the cycle is not meaningful', () {
      // Distributed in proportion to each phase's length, so no phase is
      // over-represented: 1 menstrual (5 days), 2 follicular (7), 1 ovulation
      // (3), 4 luteal (13). Cycle day N sits (31 - N) days before the anchor.
      const evenlySpreadDaysBefore = [
        28, // cycle day 3  — menstrual
        24, // day 7        — follicular
        20, // day 11       — follicular
        17, // day 14       — ovulation
        13, // day 18       — luteal
        10, // day 21       — luteal
        7, // day 24        — luteal
        4, // day 27        — luteal
      ];

      final analytics = CycleAnalytics(
        periods: [period(2), period(30)],
        logs: [
          for (final day in evenlySpreadDaysBefore)
            log(day, symptoms: ['Headache']),
        ],
        preferences: prefs,
      );

      final pattern = analytics
          .symptomPatterns()
          .firstWhere((p) => p.symptom == 'Headache');
      // Plenty of observations, but no real concentration — so it stays out of
      // the UI. This is the guard against reporting noise as a finding.
      expect(pattern.occurrences, 8);
      expect(pattern.lift, lessThan(1.4));
      expect(pattern.isMeaningful, isFalse);
    });

    test('a real cluster seen only twice is withheld for sample size', () {
      final analytics = CycleAnalytics(
        periods: [period(2), period(30)],
        logs: [
          log(30, symptoms: ['Nausea']),
          log(29, symptoms: ['Nausea']),
        ],
        preferences: prefs,
      );

      final pattern =
          analytics.symptomPatterns().firstWhere((p) => p.symptom == 'Nausea');
      expect(pattern.lift, greaterThan(1.4));
      // Effect is strong but only 2 observations, so it stays hidden.
      expect(pattern.occurrences, 2);
      expect(pattern.isMeaningful, isFalse);
    });
  });

  group('temperatureAnalysis', () {
    test('reports no data when nothing is logged', () {
      final analytics = CycleAnalytics(
        periods: [period(10)],
        logs: const [],
        preferences: prefs,
      );
      final analysis = analytics.temperatureAnalysis(reference: anchor);
      expect(analysis.points, isEmpty);
      expect(analysis.hasEnoughData, isFalse);
      expect(analysis.coverline, isNull);
    });

    test('finds a sustained rise and draws a coverline above the baseline', () {
      // A cycle that began 14 days before the anchor. Six low readings, then
      // three clearly raised ones.
      final temperatures = <int, double>{
        13: 36.40,
        12: 36.42,
        11: 36.38,
        10: 36.41,
        9: 36.39,
        8: 36.40,
        7: 36.65,
        6: 36.68,
        5: 36.70,
      };

      final analytics = CycleAnalytics(
        periods: [period(14)],
        logs: [
          for (final entry in temperatures.entries)
            log(entry.key, temperature: entry.value),
        ],
        preferences: prefs,
      );

      final analysis = analytics.temperatureAnalysis(reference: anchor);
      expect(analysis.points.length, 9);
      expect(analysis.hasEnoughData, isTrue);
      expect(analysis.coverline, isNotNull);
      // Baseline high is 36.42, so the coverline sits just above it.
      expect(analysis.coverline, closeTo(36.52, 0.001));
      // The rise begins on the 7th reading, which is cycle day 8.
      expect(analysis.thermalShiftDay, 8);
    });

    test('does not call a single warm morning a thermal shift', () {
      final temperatures = <int, double>{
        13: 36.40,
        12: 36.42,
        11: 36.38,
        10: 36.41,
        9: 36.39,
        8: 36.40,
        7: 36.70, // one restless night
        6: 36.41,
        5: 36.40,
      };

      final analytics = CycleAnalytics(
        periods: [period(14)],
        logs: [
          for (final entry in temperatures.entries)
            log(entry.key, temperature: entry.value),
        ],
        preferences: prefs,
      );

      final analysis = analytics.temperatureAnalysis(reference: anchor);
      expect(analysis.thermalShiftDay, isNull);
      expect(analysis.coverline, isNull);
    });
  });

  group('logging consistency', () {
    test('streak counts back from today and stops at the first gap', () {
      final analytics = CycleAnalytics(
        periods: [period(10)],
        logs: [log(0), log(1), log(2), log(4)],
        preferences: prefs,
      );
      expect(analytics.loggingStreak(reference: anchor), 3);
    });

    test('an unlogged today does not break yesterday\'s streak', () {
      final analytics = CycleAnalytics(
        periods: [period(10)],
        logs: [log(1), log(2), log(3)],
        preferences: prefs,
      );
      expect(analytics.loggingStreak(reference: anchor), 3);
    });

    test('streak is zero with no logs at all', () {
      final analytics = CycleAnalytics(
        periods: [period(10)],
        logs: const [],
        preferences: prefs,
      );
      expect(analytics.loggingStreak(reference: anchor), 0);
    });

    test('consistency is the share of the window that has a log', () {
      final analytics = CycleAnalytics(
        periods: [period(30)],
        logs: [for (var i = 0; i < 5; i++) log(i)],
        preferences: prefs,
      );
      expect(
        analytics.loggingConsistency(days: 10, reference: anchor),
        closeTo(0.5, 0.0001),
      );
    });
  });

  group('aggregates', () {
    test('top symptoms are ranked by frequency', () {
      final analytics = CycleAnalytics(
        periods: [period(2), period(30)],
        logs: [
          log(1, symptoms: ['Cramps', 'Bloating']),
          log(2, symptoms: ['Cramps']),
          log(3, symptoms: ['Cramps']),
          log(4, symptoms: ['Bloating']),
          log(5, symptoms: ['Acne']),
        ],
        preferences: prefs,
      );

      final top = analytics.topSymptoms();
      expect(top.first.symptom, 'Cramps');
      expect(top.first.count, 3);
      expect(top.length, 3);
    });

    test('mood distribution ignores empty moods', () {
      final analytics = CycleAnalytics(
        periods: [period(2)],
        logs: [
          log(1, mood: 'Calm'),
          log(2, mood: 'Calm'),
          log(3, mood: 'Sad'),
          log(4),
        ],
        preferences: prefs,
      );

      final moods = analytics.moodDistribution();
      expect(moods.length, 2);
      expect(moods.first.mood, 'Calm');
      expect(moods.first.count, 2);
    });

    test('pain average only counts days where pain was recorded', () {
      final analytics = CycleAnalytics(
        periods: [period(2)],
        logs: [log(1, pain: 6), log(2, pain: 4), log(3)],
        preferences: prefs,
      );
      expect(analytics.averagePainLevel(), 5);
    });

    test('averages are null rather than zero when nothing is logged', () {
      final analytics = CycleAnalytics(
        periods: [period(2)],
        logs: [log(1)],
        preferences: prefs,
      );
      expect(analytics.averagePainLevel(), isNull);
      expect(analytics.averageSleepHours(), isNull);
      expect(analytics.averageWaterMl(), isNull);
    });

    test('weight trend is ordered oldest to newest', () {
      final analytics = CycleAnalytics(
        periods: [period(2)],
        logs: [
          log(1, weight: 61.0),
          log(5, weight: 60.0),
          log(3, weight: 60.5),
        ],
        preferences: prefs,
      );

      final trend = analytics.weightTrend();
      expect(trend.map((p) => p.value).toList(), [60.0, 60.5, 61.0]);
    });
  });
}
