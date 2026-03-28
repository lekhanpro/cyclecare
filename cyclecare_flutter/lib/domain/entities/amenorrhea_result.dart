import 'package:flutter/foundation.dart';

enum AmenorrheaSeverity {
  none,
  mild,
  moderate,
  severe;
  
  String get displayName {
    switch (this) {
      case AmenorrheaSeverity.none:
        return 'Normal';
      case AmenorrheaSeverity.mild:
        return 'Slightly Delayed';
      case AmenorrheaSeverity.moderate:
        return 'Delayed';
      case AmenorrheaSeverity.severe:
        return 'Missed Period';
    }
  }
  
  String get description {
    switch (this) {
      case AmenorrheaSeverity.none:
        return 'Your cycle is within normal range';
      case AmenorrheaSeverity.mild:
        return 'Your period is a few days late';
      case AmenorrheaSeverity.moderate:
        return 'Your period is significantly delayed';
      case AmenorrheaSeverity.severe:
        return 'You have missed multiple cycles';
    }
  }
  
  int get thresholdDays {
    switch (this) {
      case AmenorrheaSeverity.none:
        return 0;
      case AmenorrheaSeverity.mild:
        return 35;
      case AmenorrheaSeverity.moderate:
        return 60;
      case AmenorrheaSeverity.severe:
        return 90;
    }
  }
  
  static AmenorrheaSeverity fromDays(int days) {
    if (days >= 90) return AmenorrheaSeverity.severe;
    if (days >= 60) return AmenorrheaSeverity.moderate;
    if (days >= 35) return AmenorrheaSeverity.mild;
    return AmenorrheaSeverity.none;
  }
}

@immutable
class AmenorrheaResult {
  final AmenorrheaSeverity severity;
  final int daysSinceLastPeriod;
  final DateTime? lastPeriodDate;
  final List<String> contributingFactors;
  final List<String> recommendations;
  final bool dismissed;

  const AmenorrheaResult({
    required this.severity,
    required this.daysSinceLastPeriod,
    this.lastPeriodDate,
    this.contributingFactors = const [],
    this.recommendations = const [],
    this.dismissed = false,
  });

  AmenorrheaResult copyWith({
    AmenorrheaSeverity? severity,
    int? daysSinceLastPeriod,
    DateTime? lastPeriodDate,
    List<String>? contributingFactors,
    List<String>? recommendations,
    bool? dismissed,
  }) {
    return AmenorrheaResult(
      severity: severity ?? this.severity,
      daysSinceLastPeriod: daysSinceLastPeriod ?? this.daysSinceLastPeriod,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      contributingFactors: contributingFactors ?? this.contributingFactors,
      recommendations: recommendations ?? this.recommendations,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'severity': severity.name,
      'daysSinceLastPeriod': daysSinceLastPeriod,
      'lastPeriodDate': lastPeriodDate?.toIso8601String(),
      'contributingFactors': contributingFactors,
      'recommendations': recommendations,
      'dismissed': dismissed,
    };
  }

  factory AmenorrheaResult.fromJson(Map<String, dynamic> json) {
    return AmenorrheaResult(
      severity: AmenorrheaSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AmenorrheaSeverity.none,
      ),
      daysSinceLastPeriod: json['daysSinceLastPeriod'] as int,
      lastPeriodDate: json['lastPeriodDate'] != null
          ? DateTime.parse(json['lastPeriodDate'] as String)
          : null,
      contributingFactors:
          (json['contributingFactors'] as List<dynamic>?)?.cast<String>() ?? [],
      recommendations:
          (json['recommendations'] as List<dynamic>?)?.cast<String>() ?? [],
      dismissed: json['dismissed'] as bool? ?? false,
    );
  }
}
