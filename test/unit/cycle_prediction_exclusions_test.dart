import 'dart:convert';

import 'package:cyclecare/features/settings/application/backup_service.dart';
import 'package:cyclecare/features/tracking/data/cycle_repository.dart';
import 'package:cyclecare/features/tracking/domain/cycle_analytics.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/domain/prediction_evaluation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = CyclePredictionService();
  const preferences = CyclePreferences();
  final origin = DateTime(2025, 1, 1);
  List<CycleEvent> history({bool excluded = false}) => [
    CycleEvent(id: 'a', startDate: origin),
    CycleEvent(
      id: 'b',
      startDate: origin.add(const Duration(days: 28)),
      excludeFromPredictions: excluded,
      predictionExclusionReason: 'Travel',
    ),
    CycleEvent(id: 'c', startDate: origin.add(const Duration(days: 78))),
    CycleEvent(id: 'd', startDate: origin.add(const Duration(days: 106))),
  ];

  test('excluded cycle retains boundaries and shared analytics agree', () {
    final periods = history(excluded: true);
    final prediction = service.buildPrediction(
      periods: periods,
      preferences: preferences,
      referenceDate: origin.add(const Duration(days: 110)),
    )!;
    final analytics = CycleAnalytics(
      periods: periods,
      logs: const [],
      preferences: preferences,
    );
    expect(prediction.cyclesTracked, 2);
    expect(prediction.excludedCycles, 1);
    expect(prediction.averageCycleLength, 28);
    expect(analytics.cycleHistory().map((c) => c.length), [28, 28]);
    expect(analytics.cycleHistory(includeExcluded: true).length, 3);
    expect(periods.length, 4);
    expect(prediction.estimateExplanation, contains('2 completed cycles'));
    expect(
      prediction.estimateExplanation,
      contains('not a clinically validated probability'),
    );
  });

  test(
    'all excluded samples use settings and remain anchored to actual start',
    () {
      final periods = history()
          .map((event) => event.copyWith(excludeFromPredictions: true))
          .toList();
      final result = service.buildPrediction(
        periods: periods,
        preferences: preferences,
        referenceDate: origin.add(const Duration(days: 170)),
      )!;
      expect(result.cyclesTracked, 0);
      expect(result.estimateBasis, contains('setting'));
      expect(result.nextPeriodStart, origin.add(const Duration(days: 134)));
      expect(result.daysLate, 36);
    },
  );

  test('future starts never influence a current forecast', () {
    final result = service.buildPrediction(
      periods: history(),
      preferences: preferences,
      referenceDate: origin.add(const Duration(days: 30)),
    )!;
    expect(result.cyclesTracked, 1);
    expect(result.nextPeriodStart, origin.add(const Duration(days: 56)));
    expect(
      service.buildPrediction(
        periods: [history().last],
        preferences: preferences,
        referenceDate: origin,
      ),
      isNull,
    );
  });

  test(
    'walk-forward uses only prior starts and the same weighted predictor',
    () {
      final periods = history();
      final replay = PredictionEvaluation.run(
        periods: periods,
        preferences: preferences,
        through: origin.add(const Duration(days: 120)),
      );
      expect(replay.points.map((point) => point.trainingCycles), [0, 1, 2]);
      expect(replay.points.map((point) => point.absoluteErrorDays), [
        0,
        22,
        11,
      ]);
      final truncated = PredictionEvaluation.run(
        periods: periods.take(3).toList(),
        preferences: preferences,
        through: origin.add(const Duration(days: 120)),
      );
      expect(
        truncated.points.map((p) => p.predictedStart),
        replay.points.take(2).map((p) => p.predictedStart),
      );
      expect(replay.meanAbsoluteErrorDays, 11);
    },
  );

  test('legacy exclusion defaults and nullable reason round trip', () {
    final legacy = CycleEvent.fromJson({
      'id': 'old',
      'startDate': '2025-01-01',
    });
    expect(legacy.excludeFromPredictions, isFalse);
    expect(legacy.predictionExclusionReason, isNull);
    final excluded = history(excluded: true)[1];
    expect(
      CycleEvent.fromJson(excluded.toJson()).predictionExclusionReason,
      'Travel',
    );
    expect(
      excluded
          .copyWith(predictionExclusionReason: null)
          .predictionExclusionReason,
      isNull,
    );
  });

  test(
    'walk-forward replays weighted history rather than a different baseline',
    () {
      final starts = [0, 20, 40, 80, 108];
      final replay = PredictionEvaluation.run(
        periods: [
          for (final offset in starts)
            CycleEvent(
              id: '$offset',
              startDate: origin.add(Duration(days: offset)),
            ),
        ],
        preferences: preferences,
        through: origin.add(const Duration(days: 120)),
      );
      // Latest completed gaps at the last forecast: 40, 20, 20.
      // Recency weights 3, 2, 1 give 30 days; a plain mean would give 27.
      expect(
        replay.points.last.predictedStart,
        origin.add(const Duration(days: 110)),
      );
      expect(replay.points.last.absoluteErrorDays, 2);
    },
  );

  test('exclusion survives local storage and backup inspection', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = CycleRepository(prefs);
    await repository.savePeriods(history(excluded: true));
    expect(repository.loadPeriods()[1].excludeFromPredictions, isTrue);
    final exported = await repository.exportJson();
    expect(
      (jsonDecode(exported) as Map)['periods'][1]['predictionExclusionReason'],
      'Travel',
    );
    final check = const BackupService().inspect(exported) as BackupReady;
    expect(check.preview.periods[1].excludeFromPredictions, isTrue);
    expect(check.preview.periods[1].predictionExclusionReason, 'Travel');
  });
}
