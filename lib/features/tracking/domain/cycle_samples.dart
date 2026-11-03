import '../../../core/utils/date_helpers.dart';
import 'cycle_models.dart';

/// Shared history selection for forecasts, analytics and retrospective checks.
/// Excluding a cycle never joins its neighbours into an artificial long cycle.
class CycleSamples {
  CycleSamples(List<CycleEvent> periods, {DateTime? through}) {
    final cutoff = dateOnly(through ?? DateTime.now());
    final unique = <DateTime, CycleEvent>{};
    for (final event in periods) {
      final start = dateOnly(event.startDate);
      if (start.isAfter(cutoff)) continue;
      final existing = unique[start];
      // A duplicate must not accidentally undo an explicit exclusion.
      if (existing == null || event.excludeFromPredictions) {
        unique[start] = event;
      }
    }
    ordered = unique.values.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  late final List<CycleEvent> ordered;

  List<CompletedCycleSample> get completed => [
    for (var i = 0; i + 1 < ordered.length; i++)
      CompletedCycleSample(ordered[i + 1], ordered[i]),
  ];

  List<CompletedCycleSample> get included =>
      completed.where((sample) => sample.isIncluded).toList();
}

class CompletedCycleSample {
  const CompletedCycleSample(this.event, this.nextEvent);
  final CycleEvent event;
  final CycleEvent nextEvent;
  int get length => dateOnly(
    nextEvent.startDate,
  ).difference(dateOnly(event.startDate)).inDays;
  bool get isInLearningRange => length >= 15 && length <= 90;
  bool get isIncluded => !event.excludeFromPredictions && isInLearningRange;
}
