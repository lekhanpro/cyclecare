import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_log.freezed.dart';
part 'daily_log.g.dart';

@freezed
class DailyLog with _$DailyLog {
  const factory DailyLog({
    required int id,
    required DateTime date,
    String? flow,
    String? mood,
    @Default([]) List<String> symptoms,
    String? discharge,
    double? weightKg,
    double? temperature,
    String? ovulationTest,
    String? pregnancyTest,
    bool? intimacy,
    @Default(0) int waterMl,
    String? cervicalMucus,
    bool? sexualActivity,
    double? sleepHours,
    @Default(0) int exerciseMinutes,
    @Default('') String notes,
  }) = _DailyLog;

  factory DailyLog.fromJson(Map<String, dynamic> json) => _$DailyLogFromJson(json);
}
