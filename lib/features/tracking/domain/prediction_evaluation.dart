import '../../../core/utils/date_helpers.dart';
import 'cycle_models.dart';
import 'cycle_prediction_service.dart';
import 'cycle_samples.dart';

class PredictionEvaluationPoint {
  const PredictionEvaluationPoint({
    required this.actualStart,
    required this.predictedStart,
    required this.trainingCycles,
    required this.cycleStart,
  });
  final DateTime actualStart;
  final DateTime predictedStart;
  final int trainingCycles;
  final DateTime cycleStart;
  int get errorDays => predictedStart.difference(actualStart).inDays;
  int get absoluteErrorDays => errorDays.abs();
}

/// Walk-forward replay: forecast the next start at each prior recorded start,
/// using no later starts or later bleeding end dates. Current user exclusions
/// are retrospective annotations; this cannot reconstruct when they were set.
class PredictionEvaluation {
  const PredictionEvaluation(this.points);
  final List<PredictionEvaluationPoint> points;

  static PredictionEvaluation run({
    required List<CycleEvent> periods,
    required CyclePreferences preferences,
    DateTime? through,
  }) {
    final ordered = CycleSamples(
      periods,
      through: through,
    ).ordered.reversed.toList();
    final points = <PredictionEvaluationPoint>[];
    for (var i = 1; i < ordered.length; i++) {
      final origin = dateOnly(ordered[i - 1].startDate);
      // Exclusion describes the cycle being evaluated, not the target period.
      if (ordered[i - 1].excludeFromPredictions) continue;
      final history = ordered
          .take(i)
          .map(
            (event) => CycleEvent(
              id: event.id,
              startDate: event.startDate,
              endDate:
                  event.endDate != null &&
                      !dateOnly(event.endDate!).isAfter(origin)
                  ? event.endDate
                  : null,
              excludeFromPredictions: event.excludeFromPredictions,
              predictionExclusionReason: event.predictionExclusionReason,
            ),
          )
          .toList();
      final prediction = const CyclePredictionService().buildPrediction(
        periods: history,
        preferences: preferences,
        referenceDate: origin,
      );
      if (prediction == null) continue;
      points.add(
        PredictionEvaluationPoint(
          actualStart: dateOnly(ordered[i].startDate),
          predictedStart: prediction.nextPeriodStart,
          trainingCycles: prediction.cyclesTracked,
          cycleStart: origin,
        ),
      );
    }
    return PredictionEvaluation(List.unmodifiable(points));
  }

  double? get meanAbsoluteErrorDays => points.isEmpty
      ? null
      : points.fold<int>(0, (sum, point) => sum + point.absoluteErrorDays) /
            points.length;
}
