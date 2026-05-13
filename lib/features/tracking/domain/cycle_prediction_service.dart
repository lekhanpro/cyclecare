import 'dart:math';

import '../../../core/utils/date_helpers.dart';
import 'cycle_models.dart';

class CyclePredictionService {
  const CyclePredictionService();

  CyclePrediction? buildPrediction({
    required List<CycleEvent> periods,
    required CyclePreferences preferences,
    DateTime? referenceDate,
  }) {
    final today = dateOnly(referenceDate ?? DateTime.now());
    final normalized = periods.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final unique = <DateTime, CycleEvent>{};
    for (final period in normalized) {
      unique.putIfAbsent(dateOnly(period.startDate), () => period);
    }
    final ordered = unique.values.toList();
    if (ordered.isEmpty) {
      return null;
    }

    final cycleLengths = <int>[];
    for (var i = 0; i < ordered.length - 1; i++) {
      final current = dateOnly(ordered[i].startDate);
      final previous = dateOnly(ordered[i + 1].startDate);
      final days = current.difference(previous).inDays;
      if (days >= 15 && days <= 90) {
        cycleLengths.add(days);
      }
    }

    final averageCycleLength = _averageCycleLength(
      cycleLengths,
      preferences.averageCycleLength,
    );
    final averagePeriodLength = _averagePeriodLength(
      ordered,
      preferences.averagePeriodLength,
    );

    final lastStart = dateOnly(ordered.first.startDate);
    final expectedPeriodStart = lastStart.add(Duration(days: averageCycleLength));
    var nextPeriodStart = expectedPeriodStart;
    final isLate = today.isAfter(expectedPeriodStart);
    if (isLate) {
      nextPeriodStart = expectedPeriodStart;
    } else {
      while (nextPeriodStart.isBefore(today)) {
        nextPeriodStart = nextPeriodStart.add(Duration(days: averageCycleLength));
      }
    }

    final nextPeriodEnd = nextPeriodStart.add(
      Duration(days: averagePeriodLength - 1),
    );
    final ovulationDate = nextPeriodStart.subtract(
      Duration(days: preferences.lutealPhaseLength),
    );
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));
    final cycleDay = today.difference(lastStart).inDays + 1;
    final ovulationCycleDay = averageCycleLength - preferences.lutealPhaseLength;
    final phase = _phaseFor(
      cycleDay: cycleDay,
      periodLength: averagePeriodLength,
      ovulationDay: ovulationCycleDay,
    );
    final stdDev = _standardDeviation(cycleLengths);
    final variabilityScore = (1 - (stdDev / 12)).clamp(0.05, 1).toDouble();
    final sampleScore = (cycleLengths.length / 6).clamp(0.25, 1).toDouble();
    final daysLate = isLate ? today.difference(expectedPeriodStart).inDays : 0;

    return CyclePrediction(
      nextPeriodStart: nextPeriodStart,
      nextPeriodEnd: nextPeriodEnd,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      averageCycleLength: averageCycleLength,
      averagePeriodLength: averagePeriodLength,
      confidence:
          (variabilityScore * 0.7 + sampleScore * 0.3).clamp(0.1, 0.99).toDouble(),
      isIrregular: stdDev >= 4.5,
      cycleDay: cycleDay < 1 ? 1 : cycleDay,
      daysUntilPeriod: isLate ? 0 : nextPeriodStart.difference(today).inDays,
      phase: phase,
      isLate: isLate,
      daysLate: daysLate,
    );
  }

  String _phaseFor({
    required int cycleDay,
    required int periodLength,
    required int ovulationDay,
  }) {
    if (cycleDay <= periodLength) return 'Menstrual';
    if (cycleDay < ovulationDay - 2) return 'Follicular';
    if (cycleDay <= ovulationDay + 1) return 'Ovulation';
    return 'Luteal';
  }

  int _averageCycleLength(List<int> lengths, int fallback) {
    if (lengths.isEmpty) {
      return fallback.clamp(21, 45) as int;
    }
    if (lengths.length < 3) {
      return (lengths.reduce((a, b) => a + b) / lengths.length)
          .round()
          .clamp(21, 45) as int;
    }
    var weight = lengths.length.toDouble();
    var total = 0.0;
    var totalWeight = 0.0;
    for (final length in lengths) {
      total += length * weight;
      totalWeight += weight;
      weight = max(1, weight - 1);
    }
    return (total / totalWeight).round().clamp(21, 45) as int;
  }

  int _averagePeriodLength(List<CycleEvent> periods, int fallback) {
    final lengths = periods
        .where((period) => period.endDate != null)
        .map((period) => dateOnly(period.endDate!).difference(dateOnly(period.startDate)).inDays + 1)
        .where((length) => length >= 1 && length <= 14)
        .toList();
    if (lengths.isEmpty) {
      return fallback.clamp(2, 10) as int;
    }
    return (lengths.reduce((a, b) => a + b) / lengths.length).round().clamp(2, 10) as int;
  }

  double _standardDeviation(List<int> values) {
    if (values.isEmpty) {
      return 0;
    }
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((value) => pow(value - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
}
