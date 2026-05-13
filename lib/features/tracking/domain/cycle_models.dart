enum FlowIntensity { none, spotting, light, medium, heavy }

enum DayStatus { period, predictedPeriod, fertile, ovulation, normal }

enum TrackingGoal {
  trackPeriods,
  tryingToConceive,
  pregnancy,
  perimenopause,
  symptomWellness;

  String get label {
    return switch (this) {
      TrackingGoal.trackPeriods => 'Track periods',
      TrackingGoal.tryingToConceive => 'Trying to conceive',
      TrackingGoal.pregnancy => 'Pregnancy',
      TrackingGoal.perimenopause => 'Perimenopause',
      TrackingGoal.symptomWellness => 'Symptom wellness',
    };
  }
}

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
    this.painLevel = 0,
    this.discharge,
    this.cervicalMucus,
    this.cervicalPosition,
    this.cervicalFirmness,
    this.cervicalOpening,
    this.temperatureCelsius,
    this.weightKg,
    this.sleepHours,
    this.waterMl = 0,
    this.medicineTaken = false,
    this.medicineName,
    this.notes = '',
  });

  final DateTime date;
  final FlowIntensity? flow;
  final String? mood;
  final List<String> symptoms;
  final int painLevel;
  final String? discharge;
  final String? cervicalMucus;
  final String? cervicalPosition;
  final String? cervicalFirmness;
  final String? cervicalOpening;
  final double? temperatureCelsius;
  final double? weightKg;
  final double? sleepHours;
  final int waterMl;
  final bool medicineTaken;
  final String? medicineName;
  final String notes;

  DailyLog copyWith({
    DateTime? date,
    FlowIntensity? flow,
    String? mood,
    List<String>? symptoms,
    int? painLevel,
    String? discharge,
    String? cervicalMucus,
    String? cervicalPosition,
    String? cervicalFirmness,
    String? cervicalOpening,
    double? temperatureCelsius,
    double? weightKg,
    double? sleepHours,
    int? waterMl,
    bool? medicineTaken,
    String? medicineName,
    String? notes,
  }) {
    return DailyLog(
      date: date ?? this.date,
      flow: flow ?? this.flow,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      painLevel: painLevel ?? this.painLevel,
      discharge: discharge ?? this.discharge,
      cervicalMucus: cervicalMucus ?? this.cervicalMucus,
      cervicalPosition: cervicalPosition ?? this.cervicalPosition,
      cervicalFirmness: cervicalFirmness ?? this.cervicalFirmness,
      cervicalOpening: cervicalOpening ?? this.cervicalOpening,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      weightKg: weightKg ?? this.weightKg,
      sleepHours: sleepHours ?? this.sleepHours,
      waterMl: waterMl ?? this.waterMl,
      medicineTaken: medicineTaken ?? this.medicineTaken,
      medicineName: medicineName ?? this.medicineName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'date': date.toIso8601String(),
      'flow': flow?.name,
      'mood': mood,
      'symptoms': symptoms,
      'painLevel': painLevel,
      'discharge': discharge,
      'cervicalMucus': cervicalMucus,
      'cervicalPosition': cervicalPosition,
      'cervicalFirmness': cervicalFirmness,
      'cervicalOpening': cervicalOpening,
      'temperatureCelsius': temperatureCelsius,
      'weightKg': weightKg,
      'sleepHours': sleepHours,
      'waterMl': waterMl,
      'medicineTaken': medicineTaken,
      'medicineName': medicineName,
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
      painLevel: json['painLevel'] as int? ?? 0,
      discharge: json['discharge'] as String?,
      cervicalMucus: json['cervicalMucus'] as String?,
      cervicalPosition: json['cervicalPosition'] as String?,
      cervicalFirmness: json['cervicalFirmness'] as String?,
      cervicalOpening: json['cervicalOpening'] as String?,
      temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      waterMl: json['waterMl'] as int? ?? 0,
      medicineTaken: json['medicineTaken'] as bool? ?? false,
      medicineName: json['medicineName'] as String?,
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
    this.periodReminderEnabled = true,
    this.ovulationReminderEnabled = false,
    this.dailyLogReminderEnabled = false,
    this.pillReminderEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.profileName = '',
    this.profileBirthYear,
    this.goal = TrackingGoal.trackPeriods,
    this.onboardingCompleted = false,
  });

  final int averageCycleLength;
  final int averagePeriodLength;
  final int lutealPhaseLength;
  final bool remindersEnabled;
  final bool periodReminderEnabled;
  final bool ovulationReminderEnabled;
  final bool dailyLogReminderEnabled;
  final bool pillReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final String profileName;
  final int? profileBirthYear;
  final TrackingGoal goal;
  final bool onboardingCompleted;

  CyclePreferences copyWith({
    int? averageCycleLength,
    int? averagePeriodLength,
    int? lutealPhaseLength,
    bool? remindersEnabled,
    bool? periodReminderEnabled,
    bool? ovulationReminderEnabled,
    bool? dailyLogReminderEnabled,
    bool? pillReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? profileName,
    int? profileBirthYear,
    TrackingGoal? goal,
    bool? onboardingCompleted,
  }) {
    return CyclePreferences(
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
      lutealPhaseLength: lutealPhaseLength ?? this.lutealPhaseLength,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      periodReminderEnabled:
          periodReminderEnabled ?? this.periodReminderEnabled,
      ovulationReminderEnabled:
          ovulationReminderEnabled ?? this.ovulationReminderEnabled,
      dailyLogReminderEnabled:
          dailyLogReminderEnabled ?? this.dailyLogReminderEnabled,
      pillReminderEnabled: pillReminderEnabled ?? this.pillReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      profileName: profileName ?? this.profileName,
      profileBirthYear: profileBirthYear ?? this.profileBirthYear,
      goal: goal ?? this.goal,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'averageCycleLength': averageCycleLength,
      'averagePeriodLength': averagePeriodLength,
      'lutealPhaseLength': lutealPhaseLength,
      'remindersEnabled': remindersEnabled,
      'periodReminderEnabled': periodReminderEnabled,
      'ovulationReminderEnabled': ovulationReminderEnabled,
      'dailyLogReminderEnabled': dailyLogReminderEnabled,
      'pillReminderEnabled': pillReminderEnabled,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'profileName': profileName,
      'profileBirthYear': profileBirthYear,
      'goal': goal.name,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  factory CyclePreferences.fromJson(Map<String, Object?> json) {
    return CyclePreferences(
      averageCycleLength: json['averageCycleLength'] as int? ?? 28,
      averagePeriodLength: json['averagePeriodLength'] as int? ?? 5,
      lutealPhaseLength: json['lutealPhaseLength'] as int? ?? 14,
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      periodReminderEnabled: json['periodReminderEnabled'] as bool? ?? true,
      ovulationReminderEnabled:
          json['ovulationReminderEnabled'] as bool? ?? false,
      dailyLogReminderEnabled:
          json['dailyLogReminderEnabled'] as bool? ?? false,
      pillReminderEnabled: json['pillReminderEnabled'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int? ?? 9,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      profileName: json['profileName'] as String? ?? '',
      profileBirthYear: json['profileBirthYear'] as int?,
      goal: TrackingGoal.values.firstWhere(
        (goal) => goal.name == json['goal'],
        orElse: () => TrackingGoal.trackPeriods,
      ),
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
    required this.phase,
    required this.isLate,
    required this.daysLate,
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
  final String phase;
  final bool isLate;
  final int daysLate;
}
