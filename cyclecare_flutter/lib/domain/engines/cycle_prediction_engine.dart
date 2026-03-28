import 'dart:math' as math;
import '../entities/period.dart';
import '../entities/cycle.dart';

class CyclePredictionEngine {
  PredictionResult? buildPrediction({
    required List<Period> periods,
    DateTime? referenceDate,
    int fallbackCycleLength = 28,
    int fallbackPeriodLength = 5,
    int lutealPhaseLength = 14,
  }) {
    final ref = referenceDate ?? DateTime.now();
    
    // Normalize periods
    final normalized = periods
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    
    // Remove duplicates by start date
    final uniquePeriods = <Period>[];
    final seenDates = <DateTime>{};
    for (final period in normalized) {
      if (!seenDates.contains(period.startDate)) {
        uniquePeriods.add(period);
        seenDates.add(period.startDate);
      }
    }

    if (uniquePeriods.isEmpty) return null;

    // Calculate cycle lengths
    final cycleLengths = <int>[];
    for (int i = 0; i < uniquePeriods.length - 1; i++) {
      final current = uniquePeriods[i];
      final previous = uniquePeriods[i + 1];
      final length = current.startDate.difference(previous.startDate).inDays;
      if (length >= 15 && length <= 90) {
        cycleLengths.add(length);
      }
    }

    // Calculate average cycle length
    final int averageCycleLength;
    if (cycleLengths.isEmpty) {
      averageCycleLength = fallbackCycleLength;
    } else if (cycleLengths.length < 3) {
      averageCycleLength = (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length)
          .round()
          .clamp(21, 40);
    } else {
      averageCycleLength = _weightedCycleAverage(cycleLengths);
    }

    // Calculate period lengths
    final periodLengths = uniquePeriods
        .where((p) => p.endDate != null)
        .map((p) => p.endDate!.difference(p.startDate).inDays + 1)
        .where((length) => length >= 1 && length <= 14)
        .toList();

    final int averagePeriodLength;
    if (periodLengths.isEmpty) {
      averagePeriodLength = fallbackPeriodLength;
    } else {
      averagePeriodLength = (periodLengths.reduce((a, b) => a + b) / periodLengths.length)
          .round()
          .clamp(2, 10);
    }

    // Predict next period start
    final lastStart = uniquePeriods.first.startDate;
    DateTime nextPeriodStart;
    
    if (lastStart.isAfter(ref)) {
      nextPeriodStart = lastStart;
    } else {
      nextPeriodStart = lastStart;
      while (!nextPeriodStart.isAfter(ref)) {
        nextPeriodStart = nextPeriodStart.add(Duration(days: averageCycleLength));
      }
    }

    final nextPeriodEnd = nextPeriodStart.add(Duration(days: averagePeriodLength - 1));
    final ovulationDate = nextPeriodStart.subtract(Duration(days: lutealPhaseLength));
    final fertileWindowStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileWindowEnd = ovulationDate.add(const Duration(days: 1));

    // Calculate confidence
    final stdDeviation = _standardDeviation(cycleLengths);
    final variabilityScore = (1.0 - (stdDeviation / 12.0)).clamp(0.05, 1.0);
    final sampleScore = (cycleLengths.length / 6.0).clamp(0.25, 1.0);
    final confidenceScore = (variabilityScore * 0.7 + sampleScore * 0.3).clamp(0.1, 0.99);

    return PredictionResult(
      nextPeriodStart: nextPeriodStart,
      nextPeriodEnd: nextPeriodEnd,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      averageCycleLength: averageCycleLength,
      averagePeriodLength: averagePeriodLength,
      variabilityScore: variabilityScore,
      confidenceScore: confidenceScore,
      isIrregular: stdDeviation >= 4.5,
      cycleLengthStdDeviation: stdDeviation,
    );
  }

  int _weightedCycleAverage(List<int> cycleLengths) {
    double weight = cycleLengths.length.toDouble();
    double weightedTotal = 0.0;
    double totalWeight = 0.0;
    
    for (final length in cycleLengths) {
      weightedTotal += length * weight;
      totalWeight += weight;
      weight = (weight - 1.0).clamp(1.0, double.infinity);
    }
    
    return (weightedTotal / totalWeight).round().clamp(21, 40);
  }

  double _standardDeviation(List<int> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((v) => math.pow(v - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    
    return math.sqrt(variance);
  }
}
