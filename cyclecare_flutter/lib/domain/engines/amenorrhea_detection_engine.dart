import '../entities/period.dart';
import '../entities/daily_log.dart';
import '../entities/amenorrhea_result.dart';
import '../entities/enums.dart';

class AmenorrheaDetectionEngine {
  AmenorrheaResult? detectAmenorrhea({
    required List<Period> periods,
    required List<DailyLog> recentLogs,
    bool isPregnant = false,
    bool isBreastfeeding = false,
    bool isMenopause = false,
  }) {
    // Don't alert if in pregnancy, breastfeeding, or menopause mode
    if (isPregnant || isBreastfeeding || isMenopause) {
      return null;
    }

    if (periods.isEmpty) return null;

    final lastPeriod = periods.reduce((a, b) => 
        a.startDate.isAfter(b.startDate) ? a : b);
    
    final daysSinceLastPeriod = DateTime.now()
        .difference(lastPeriod.startDate)
        .inDays;

    final severity = AmenorrheaSeverity.fromDays(daysSinceLastPeriod);

    if (severity == AmenorrheaSeverity.none) {
      return null;
    }

    final contributingFactors = _analyzeContributingFactors(
      recentLogs,
      daysSinceLastPeriod,
    );
    
    final recommendations = _generateRecommendations(
      severity,
      contributingFactors,
    );

    return AmenorrheaResult(
      severity: severity,
      daysSinceLastPeriod: daysSinceLastPeriod,
      lastPeriodDate: lastPeriod.startDate,
      contributingFactors: contributingFactors,
      recommendations: recommendations,
    );
  }

  List<String> _analyzeContributingFactors(
    List<DailyLog> logs,
    int daysSince,
  ) {
    final factors = <String>[];

    if (logs.isEmpty) return factors;

    // Analyze stress levels from mood logs
    final stressfulMoods = logs.where((log) {
      final mood = log.mood?.name.toLowerCase() ?? '';
      return mood == 'stressed' || mood == 'anxious';
    }).length;

    if (stressfulMoods > logs.length * 0.3) {
      factors.add('High stress levels detected');
    }

    // Analyze weight changes
    final weights = logs
        .where((log) => log.weightKg != null)
        .map((log) => log.weightKg!)
        .toList();

    if (weights.length >= 2) {
      final weightChange = weights.last - weights.first;
      final percentChange = (weightChange / weights.first) * 100;
      
      if (percentChange > 10) {
        factors.add('Significant weight gain detected');
      } else if (percentChange < -10) {
        factors.add('Significant weight loss detected');
      }
    }

    // Analyze exercise patterns
    final highExerciseDays = logs
        .where((log) => log.exerciseMinutes > 90)
        .length;

    if (highExerciseDays > logs.length * 0.5) {
      factors.add('Intense exercise routine');
    }

    // Check for PCOS-related symptoms
    final pcosSymptoms = logs
        .expand((log) => log.symptoms)
        .where((symptom) {
          final name = symptom.name.toLowerCase();
          return name.contains('acne') || name.contains('weight');
        })
        .length;

    if (pcosSymptoms > 5) {
      factors.add('PCOS-related symptoms present');
    }

    return factors;
  }

  List<String> _generateRecommendations(
    AmenorrheaSeverity severity,
    List<String> factors,
  ) {
    final recommendations = <String>[];

    switch (severity) {
      case AmenorrheaSeverity.mild:
        recommendations.add('Monitor for a few more days');
        recommendations.add('Consider taking a pregnancy test if sexually active');
        recommendations.add('Track any unusual symptoms');
        break;
      case AmenorrheaSeverity.moderate:
        recommendations.add('Take a pregnancy test if sexually active');
        recommendations.add('Schedule a consultation with your healthcare provider');
        recommendations.add('Continue tracking symptoms and patterns');
        break;
      case AmenorrheaSeverity.severe:
        recommendations.add('Consult a healthcare provider as soon as possible');
        recommendations.add('Take a pregnancy test if you haven\'t already');
        recommendations.add('Bring your cycle tracking data to your appointment');
        break;
      case AmenorrheaSeverity.none:
        break;
    }

    // Add factor-specific recommendations
    if (factors.any((f) => f.toLowerCase().contains('stress'))) {
      recommendations.add('Practice stress management techniques');
    }
    if (factors.any((f) => f.toLowerCase().contains('weight'))) {
      recommendations.add('Discuss weight changes with your doctor');
    }
    if (factors.any((f) => f.toLowerCase().contains('exercise'))) {
      recommendations.add('Consider moderating exercise intensity');
    }
    if (factors.any((f) => f.toLowerCase().contains('pcos'))) {
      recommendations.add('Discuss PCOS screening with your healthcare provider');
    }

    return recommendations;
  }
}
