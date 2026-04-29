enum FlowIntensity { spotting, light, medium, heavy }

enum DayStatus { period, predictedPeriod, fertile, ovulation, normal }

class CycleEvent {
  const CycleEvent({
    required this.id,
    required this.startDate,
    this.endDate,
    this.flow = FlowIntensity.medium,
    this.symptoms = const [],
    this.notes = '',
  });

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final FlowIntensity flow;
  final List<String> symptoms;
  final String notes;

  CycleEvent copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    FlowIntensity? flow,
    List<String>? symptoms,
    String? notes,
  }) {
    return CycleEvent(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      flow: flow ?? this.flow,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'flow': flow.name,
      'symptoms': symptoms,
      'notes': notes,
    };
  }

  factory CycleEvent.fromJson(Map<String, Object?> json) {
    return CycleEvent(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      flow: FlowIntensity.values.byName(json['flow'] as String? ?? 'medium'),
      symptoms: (json['symptoms'] as List<dynamic>? ?? const []).cast<String>(),
      notes: json['notes'] as String? ?? '',
    );
  }
}

class DailyLog {
  const DailyLog({
    required this.date,
    this.flow,
    this.mood,
    this.symptoms = const [],
    this.notes = '',
  });

  final DateTime date;
  final FlowIntensity? flow;
  final String? mood;
  final List<String> symptoms;
  final String notes;

  DailyLog copyWith({
    DateTime? date,
    FlowIntensity? flow,
    String? mood,
    List<String>? symptoms,
    String? notes,
  }) {
    return DailyLog(
      date: date ?? this.date,
      flow: flow ?? this.flow,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'date': date.toIso8601String(),
      'flow': flow?.name,
      'mood': mood,
      'symptoms': symptoms,
      'notes': notes,
    };
  }

  factory DailyLog.fromJson(Map<String, Object?> json) {
    final flowName = json['flow'] as String?;
    return DailyLog(
      date: DateTime.parse(json['date'] as String),
      flow: flowName == null ? null : FlowIntensity.values.byName(flowName),
      mood: json['mood'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>? ?? const []).cast<String>(),
      notes: json['notes'] as String? ?? '',
    );
  }
}

class CyclePreferences {
  const CyclePreferences({
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.lutealPhaseLength = 14,
    this.remindersEnabled = true,
    this.onboardingCompleted = false,
  });

  final int averageCycleLength;
  final int averagePeriodLength;
  final int lutealPhaseLength;
  final bool remindersEnabled;
  final bool onboardingCompleted;

  CyclePreferences copyWith({
    int? averageCycleLength,
    int? averagePeriodLength,
    int? lutealPhaseLength,
    bool? remindersEnabled,
    bool? onboardingCompleted,
  }) {
    return CyclePreferences(
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
      lutealPhaseLength: lutealPhaseLength ?? this.lutealPhaseLength,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'averageCycleLength': averageCycleLength,
      'averagePeriodLength': averagePeriodLength,
      'lutealPhaseLength': lutealPhaseLength,
      'remindersEnabled': remindersEnabled,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  factory CyclePreferences.fromJson(Map<String, Object?> json) {
    return CyclePreferences(
      averageCycleLength: json['averageCycleLength'] as int? ?? 28,
      averagePeriodLength: json['averagePeriodLength'] as int? ?? 5,
      lutealPhaseLength: json['lutealPhaseLength'] as int? ?? 14,
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }
}

class CyclePrediction {
  const CyclePrediction({
    required this.nextPeriodStart,
    required this.nextPeriodEnd,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.confidence,
    required this.isIrregular,
    required this.cycleDay,
    required this.daysUntilPeriod,
  });

  final DateTime nextPeriodStart;
  final DateTime nextPeriodEnd;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final int averageCycleLength;
  final int averagePeriodLength;
  final double confidence;
  final bool isIrregular;
  final int cycleDay;
  final int daysUntilPeriod;
}
