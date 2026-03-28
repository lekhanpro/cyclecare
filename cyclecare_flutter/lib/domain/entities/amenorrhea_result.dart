import 'package:freezed_annotation/freezed_annotation.dart';

part 'amenorrhea_result.freezed.dart';
part 'amenorrhea_result.g.dart';

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

@freezed
class AmenorrheaResult with _$AmenorrheaResult {
  const factory AmenorrheaResult({
    required AmenorrheaSeverity severity,
    required int daysSinceLastPeriod,
    DateTime? lastPeriodDate,
    @Default([]) List<String> contributingFactors,
    @Default([]) List<String> recommendations,
    @Default(false) bool dismissed,
  }) = _AmenorrheaResult;

  factory AmenorrheaResult.fromJson(Map<String, dynamic> json) => 
      _$AmenorrheaResultFromJson(json);
}
