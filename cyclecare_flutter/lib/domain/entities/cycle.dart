import 'package:flutter/foundation.dart';
import 'enums.dart';

@immutable
class Cycle {
  final int id;
  final DateTime startDate;
  final DateTime? endDate;
  final int length;
  final int periodLength;
  final DateTime? ovulationDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;

  const Cycle({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.length,
    required this.periodLength,
    this.ovulationDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
  });
}

@immutable
class CyclePrediction {
  final DateTime nextPeriodStart;
  final DateTime nextPeriodEnd;
  final DateTime nextOvulation;
  final DateTime nextFertileWindowStart;
  final DateTime nextFertileWindowEnd;
  final double confidence;
  final double variabilityScore;
  final bool isIrregular;
  final int averageCycleLength;
  final int averagePeriodLength;
  final double cycleLengthStdDeviation;

  const CyclePrediction({
    required this.nextPeriodStart,
    required this.nextPeriodEnd,
    required this.nextOvulation,
    required this.nextFertileWindowStart,
    required this.nextFertileWindowEnd,
    required this.confidence,
    required this.variabilityScore,
    required this.isIrregular,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.cycleLengthStdDeviation,
  });
}

@immutable
class CycleInsights {
  final int averageCycleLength;
  final int averagePeriodLength;
  final double cycleRegularity;
  final int totalCyclesTracked;
  final List<Symptom> commonSymptoms;
  final List<int> cycleLengthTrend;
  final List<int> periodLengthTrend;

  const CycleInsights({
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.cycleRegularity,
    required this.totalCyclesTracked,
    required this.commonSymptoms,
    this.cycleLengthTrend = const [],
    this.periodLengthTrend = const [],
  });
}

@immutable
class PredictionResult {
  final DateTime nextPeriodStart;
  final DateTime nextPeriodEnd;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final int averageCycleLength;
  final int averagePeriodLength;
  final double variabilityScore;
  final double confidenceScore;
  final bool isIrregular;
  final double cycleLengthStdDeviation;

  const PredictionResult({
    required this.nextPeriodStart,
    required this.nextPeriodEnd,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.variabilityScore,
    required this.confidenceScore,
    required this.isIrregular,
    required this.cycleLengthStdDeviation,
  });

  CyclePrediction toCyclePrediction() {
    return CyclePrediction(
      nextPeriodStart: nextPeriodStart,
      nextPeriodEnd: nextPeriodEnd,
      nextOvulation: ovulationDate,
      nextFertileWindowStart: fertileWindowStart,
      nextFertileWindowEnd: fertileWindowEnd,
      confidence: confidenceScore,
      variabilityScore: variabilityScore,
      isIrregular: isIrregular,
      averageCycleLength: averageCycleLength,
      averagePeriodLength: averagePeriodLength,
      cycleLengthStdDeviation: cycleLengthStdDeviation,
    );
  }
}
