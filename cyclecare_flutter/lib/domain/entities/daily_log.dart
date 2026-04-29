import 'package:flutter/foundation.dart';

@immutable
class DailyLog {
  final int id;
  final DateTime date;
  final String? flow;
  final String? mood;
  final List<String> symptoms;
  final String? discharge;
  final double? weightKg;
  final double? temperature;
  final String? ovulationTest;
  final String? pregnancyTest;
  final bool? intimacy;
  final int waterMl;
  final String? cervicalMucus;
  final bool? sexualActivity;
  final double? sleepHours;
  final int exerciseMinutes;
  final String notes;

  const DailyLog({
    required this.id,
    required this.date,
    this.flow,
    this.mood,
    this.symptoms = const [],
    this.discharge,
    this.weightKg,
    this.temperature,
    this.ovulationTest,
    this.pregnancyTest,
    this.intimacy,
    this.waterMl = 0,
    this.cervicalMucus,
    this.sexualActivity,
    this.sleepHours,
    this.exerciseMinutes = 0,
    this.notes = '',
  });

  DailyLog copyWith({
    int? id,
    DateTime? date,
    String? flow,
    String? mood,
    List<String>? symptoms,
    String? discharge,
    double? weightKg,
    double? temperature,
    String? ovulationTest,
    String? pregnancyTest,
    bool? intimacy,
    int? waterMl,
    String? cervicalMucus,
    bool? sexualActivity,
    double? sleepHours,
    int? exerciseMinutes,
    String? notes,
  }) {
    return DailyLog(
      id: id ?? this.id,
      date: date ?? this.date,
      flow: flow ?? this.flow,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      discharge: discharge ?? this.discharge,
      weightKg: weightKg ?? this.weightKg,
      temperature: temperature ?? this.temperature,
      ovulationTest: ovulationTest ?? this.ovulationTest,
      pregnancyTest: pregnancyTest ?? this.pregnancyTest,
      intimacy: intimacy ?? this.intimacy,
      waterMl: waterMl ?? this.waterMl,
      cervicalMucus: cervicalMucus ?? this.cervicalMucus,
      sexualActivity: sexualActivity ?? this.sexualActivity,
      sleepHours: sleepHours ?? this.sleepHours,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'flow': flow,
      'mood': mood,
      'symptoms': symptoms,
      'discharge': discharge,
      'weightKg': weightKg,
      'temperature': temperature,
      'ovulationTest': ovulationTest,
      'pregnancyTest': pregnancyTest,
      'intimacy': intimacy,
      'waterMl': waterMl,
      'cervicalMucus': cervicalMucus,
      'sexualActivity': sexualActivity,
      'sleepHours': sleepHours,
      'exerciseMinutes': exerciseMinutes,
      'notes': notes,
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      flow: json['flow'] as String?,
      mood: json['mood'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
      discharge: json['discharge'] as String?,
      weightKg: json['weightKg'] as double?,
      temperature: json['temperature'] as double?,
      ovulationTest: json['ovulationTest'] as String?,
      pregnancyTest: json['pregnancyTest'] as String?,
      intimacy: json['intimacy'] as bool?,
      waterMl: json['waterMl'] as int? ?? 0,
      cervicalMucus: json['cervicalMucus'] as String?,
      sexualActivity: json['sexualActivity'] as bool?,
      sleepHours: json['sleepHours'] as double?,
      exerciseMinutes: json['exerciseMinutes'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}
