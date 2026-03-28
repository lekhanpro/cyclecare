import 'dart:math';

class CyclePrediction {
  final DateTime nextPeriodDate;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final double confidenceScore;
  final String currentPhase;
  final int cycleDay;
  final int daysUntilPeriod;

  CyclePrediction({
    required this.nextPeriodDate,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.confidenceScore,
    required this.currentPhase,
    required this.cycleDay,
    required this.daysUntilPeriod,
  });
}

class CyclePredictionEngine {
  /// Weighted moving average prediction with symptom correlation
  static CyclePrediction predict({
    required List<DateTime> periodStartDates,
    int defaultCycleLength = 28,
    int defaultPeriodLength = 5,
    List<String>? cervicalMucusHistory,
    List<double>? temperatureHistory,
  }) {
    if (periodStartDates.isEmpty) {
      final now = DateTime.now();
      return _defaultPrediction(now, defaultCycleLength, defaultPeriodLength);
    }

    final sorted = List<DateTime>.from(periodStartDates)..sort();
    final lastPeriod = sorted.last;

    // Calculate cycle lengths
    final cycleLengths = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff >= 18 && diff <= 60) cycleLengths.add(diff);
    }

    int predictedCycleLength;
    double confidence;

    if (cycleLengths.isEmpty) {
      predictedCycleLength = defaultCycleLength;
      confidence = 0.3;
    } else if (cycleLengths.length == 1) {
      predictedCycleLength = cycleLengths.first;
      confidence = 0.5;
    } else {
      // Weighted moving average - recent cycles weigh more
      double weightedSum = 0;
      double weightTotal = 0;
      for (int i = 0; i < cycleLengths.length; i++) {
        final weight = (i + 1).toDouble(); // More recent = higher weight
        weightedSum += cycleLengths[i] * weight;
        weightTotal += weight;
      }
      predictedCycleLength = (weightedSum / weightTotal).round();

      // Confidence based on consistency
      final stdDev = _standardDeviation(cycleLengths);
      confidence = max(0.3, min(0.95, 1.0 - (stdDev / 10.0)));
    }

    // Adjust with cervical mucus data if available
    if (cervicalMucusHistory != null && cervicalMucusHistory.contains('Egg-white')) {
      confidence = min(0.95, confidence + 0.05);
    }

    // Adjust with temperature data (BBT shift)
    if (temperatureHistory != null && temperatureHistory.length >= 7) {
      final hasShift = _detectTemperatureShift(temperatureHistory);
      if (hasShift) confidence = min(0.95, confidence + 0.05);
    }

    final nextPeriod = lastPeriod.add(Duration(days: predictedCycleLength));
    final ovulationDay = predictedCycleLength - 14;
    final ovulationDate = lastPeriod.add(Duration(days: ovulationDay));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    final now = DateTime.now();
    final daysSinceLastPeriod = now.difference(lastPeriod).inDays;
    final cycleDay = daysSinceLastPeriod + 1;
    final daysUntil = nextPeriod.difference(now).inDays;

    String phase;
    if (cycleDay <= defaultPeriodLength) {
      phase = 'Menstrual';
    } else if (cycleDay < ovulationDay - 2) {
      phase = 'Follicular';
    } else if (cycleDay <= ovulationDay + 2) {
      phase = 'Ovulation';
    } else {
      phase = 'Luteal';
    }

    return CyclePrediction(
      nextPeriodDate: nextPeriod,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      confidenceScore: confidence,
      currentPhase: phase,
      cycleDay: cycleDay > 0 ? cycleDay : 1,
      daysUntilPeriod: daysUntil > 0 ? daysUntil : 0,
    );
  }

  static CyclePrediction _defaultPrediction(
      DateTime now, int cycleLength, int periodLength) {
    final nextPeriod = now.add(Duration(days: cycleLength));
    final ovulationDay = cycleLength - 14;
    return CyclePrediction(
      nextPeriodDate: nextPeriod,
      ovulationDate: now.add(Duration(days: ovulationDay)),
      fertileWindowStart: now.add(Duration(days: ovulationDay - 5)),
      fertileWindowEnd: now.add(Duration(days: ovulationDay + 1)),
      confidenceScore: 0.3,
      currentPhase: 'Unknown',
      cycleDay: 1,
      daysUntilPeriod: cycleLength,
    );
  }

  static double _standardDeviation(List<int> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  static bool _detectTemperatureShift(List<double> temps) {
    if (temps.length < 7) return false;
    final mid = temps.length ~/ 2;
    final firstHalf = temps.sublist(0, mid);
    final secondHalf = temps.sublist(mid);
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    return (secondAvg - firstAvg) >= 0.2; // 0.2°C shift indicates ovulation
  }

  /// Perimenopause-adapted prediction with wider windows
  static CyclePrediction predictPerimenopause({
    required List<DateTime> periodStartDates,
  }) {
    final prediction = predict(
      periodStartDates: periodStartDates,
      defaultCycleLength: 35,
      defaultPeriodLength: 6,
    );
    return CyclePrediction(
      nextPeriodDate: prediction.nextPeriodDate,
      ovulationDate: prediction.ovulationDate,
      fertileWindowStart:
          prediction.fertileWindowStart.subtract(const Duration(days: 2)),
      fertileWindowEnd: prediction.fertileWindowEnd.add(const Duration(days: 2)),
      confidenceScore: prediction.confidenceScore * 0.7, // Lower confidence
      currentPhase: prediction.currentPhase,
      cycleDay: prediction.cycleDay,
      daysUntilPeriod: prediction.daysUntilPeriod,
    );
  }
}
