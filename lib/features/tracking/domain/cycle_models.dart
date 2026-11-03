/// Identifies the JSON envelope written by CycleCare backups.
///
/// Exports without these fields predate the envelope and remain readable as
/// legacy backups. Once an envelope is present, readers must understand its
/// exact version before interpreting any health records inside it.
class CycleBackupFormat {
  CycleBackupFormat._();

  static const String identifier = 'cyclecare-backup';
  static const int currentVersion = 1;
}

/// Menstrual flow. Persisted by [name], so new values must only ever be
/// appended — never reordered or renamed — to keep [intensity] stable.
enum FlowIntensity {
  none,
  spotting,
  light,
  medium,
  heavy,

  /// Added in DailyLog schema 2.
  veryHeavy;

  String get label => switch (this) {
        FlowIntensity.none => 'None',
        FlowIntensity.spotting => 'Spotting',
        FlowIntensity.light => 'Light',
        FlowIntensity.medium => 'Medium',
        FlowIntensity.heavy => 'Heavy',
        FlowIntensity.veryHeavy => 'Very heavy',
      };

  /// 0–5 weight (none = 0 … very heavy = 5), for charting and averaging.
  int get intensity => index;
}

enum DayStatus {
  period,
  predictedPeriod,
  fertile,
  ovulation,
  pms,
  normal,
}

/// The four phases of a menstrual cycle.
///
/// Defined in the domain rather than the theme so the prediction engine can
/// return a type instead of a bare string, and so presentation code stops
/// comparing `phase == 'Luteal'` — a comparison that silently breaks the
/// moment a label is reworded or localised.
enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal;

  String get label => switch (this) {
        CyclePhase.menstrual => 'Menstrual',
        CyclePhase.follicular => 'Follicular',
        CyclePhase.ovulation => 'Ovulation',
        CyclePhase.luteal => 'Luteal',
      };

  /// Short, non-clinical summary shown beneath the phase name.
  String get summary => switch (this) {
        CyclePhase.menstrual => 'Your period is here. Rest counts as progress.',
        CyclePhase.follicular => 'Energy and mood usually climb from here.',
        CyclePhase.ovulation => 'Peak fertility, and often peak energy.',
        CyclePhase.luteal => 'Winding down — PMS can show up late in this phase.',
      };

  static CyclePhase fromLabel(String? value) => switch (value?.toLowerCase()) {
        'menstrual' => CyclePhase.menstrual,
        'follicular' => CyclePhase.follicular,
        'ovulation' => CyclePhase.ovulation,
        'luteal' => CyclePhase.luteal,
        _ => CyclePhase.follicular,
      };
}

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
    this.excludeFromPredictions = false,
    this.predictionExclusionReason,
  });

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final FlowIntensity flow;
  final List<String> symptoms;
  final String notes;
  /// Excludes the cycle beginning here, retaining this start as a boundary.
  final bool excludeFromPredictions;
  final String? predictionExclusionReason;

  CycleEvent copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    FlowIntensity? flow,
    List<String>? symptoms,
    String? notes,
    bool? excludeFromPredictions,
    Object? predictionExclusionReason = _keep,
  }) {
    return CycleEvent(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      flow: flow ?? this.flow,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      excludeFromPredictions:
          excludeFromPredictions ?? this.excludeFromPredictions,
      predictionExclusionReason:
          _pick<String>(predictionExclusionReason, this.predictionExclusionReason),
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
      'excludeFromPredictions': excludeFromPredictions,
      'predictionExclusionReason': predictionExclusionReason,
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
      excludeFromPredictions: json['excludeFromPredictions'] as bool? ?? false,
      predictionExclusionReason: json['predictionExclusionReason'] as String?,
    );
  }
}

/// Marks a [DailyLog.copyWith] argument that was not passed, so that passing
/// an explicit `null` can clear a nullable field.
const Object _keep = _Keep();

class _Keep {
  const _Keep();
}

T? _pick<T>(Object? value, T? current) =>
    identical(value, _keep) ? current : value as T?;

/// One day's observations.
///
/// ## Observation states (schema 2)
///
/// Every observation is optional, and the model keeps four states apart:
///
/// * **not logged**: `null`, an empty list, or empty [notes]. Never a finding.
/// * **explicit none or zero**: e.g. `painLevel == 0` (no pain),
///   `waterMl == 0` (drank nothing), `flow == FlowIntensity.none`,
///   `medicineTaken == false` (not taken), the 'None' option of a choice.
/// * **unknown**: an uncertain answer stored as its option label, e.g.
///   'Not sure', 'Unclear', 'Not taken' (test), 'Prefer not to say'.
/// * **a selected value**.
///
/// Missing data is never converted to zero, a negative result or none.
///
/// ## JSON
///
/// Keys are the logging catalogue field ids. Two multi-select fields have
/// plural Dart names: `painLocation` -> [painLocations] and
/// `exerciseType` -> [exerciseTypes]. The catalogue's four symptom fields and
/// custom tags all share the `symptoms` key. Records carry `'schema': 2`; a
/// record without `schema` (or with `schema: 1`) is a legacy record and is
/// migrated on read, see [DailyLog.fromJson].
class DailyLog {
  const DailyLog({
    required this.date,
    this.flow,
    this.mood,
    this.symptoms = const [],
    this.painLevel,
    this.painLocations = const [],
    this.painInterference,
    this.discharge,
    this.cervicalMucus,
    this.cervicalPosition,
    this.cervicalFirmness,
    this.cervicalOpening,
    this.temperatureCelsius,
    this.temperatureContext = const [],
    this.weightKg,
    this.heightCm,
    this.sleepHours,
    this.sleepQuality,
    this.energy,
    this.waterMl,
    this.exerciseTypes = const [],
    this.exerciseMinutes,
    this.appetite,
    this.intimacy,
    this.protection,
    this.libido,
    this.pregnancyTest,
    this.ovulationTest,
    this.testNote,
    this.medicineTaken,
    this.medicineName,
    this.medicineDose,
    this.careActions = const [],
    this.notes = '',
  });

  /// Schema version written by [toJson].
  static const int schemaVersion = 2;

  /// The day this log describes (local date, time ignored).
  final DateTime date;

  /// Null = not logged; [FlowIntensity.none] = explicitly no flow.
  final FlowIntensity? flow;

  /// One mood label (single select; multi-mood is future work). Legacy and
  /// alias labels such as 'Tense' are kept as stored.
  final String? mood;

  /// Built-in and custom symptom labels, all four catalogue symptom groups.
  final List<String> symptoms;

  /// 0–10. 0 = explicitly no pain, null = not logged.
  final int? painLevel;

  /// JSON `painLocation`. Options: `painLocationOptions`.
  final List<String> painLocations;

  /// Optional effect on everyday activities; null is not assessed.
  final String? painInterference;

  final String? discharge;
  final String? cervicalMucus;
  final String? cervicalPosition;
  final String? cervicalFirmness;
  final String? cervicalOpening;

  /// Basal body temperature in degrees Celsius.
  final double? temperatureCelsius;

  /// Measurement context, preserved without changing the recorded temperature.
  final List<String> temperatureContext;

  /// Body weight in kilograms.
  final double? weightKg;

  /// Height in centimetres.
  final double? heightCm;

  /// Hours slept, 0–24.
  final double? sleepHours;

  /// Options: `sleepQualityOptions`.
  final String? sleepQuality;

  /// Options: `energyOptions`.
  final String? energy;

  /// Water drunk in millilitres. 0 = explicitly nothing, null = not logged.
  final int? waterMl;

  /// JSON `exerciseType`. Options: `exerciseTypeOptions`.
  final List<String> exerciseTypes;

  /// Minutes of movement, 0–1440.
  final int? exerciseMinutes;

  /// Options: `appetiteOptions`.
  final String? appetite;

  /// Private. Options: `intimacyOptions`. Never shared or sent to AI.
  final String? intimacy;

  /// Private. Options: `protectionOptions`. Never shared or sent to AI.
  final String? protection;

  /// Private. Options: `libidoOptions`. Never shared or sent to AI.
  final String? libido;

  /// Private. The result as shown on the test, never interpreted.
  /// Options: `testResultOptions`.
  final String? pregnancyTest;

  /// Private. Options: `testResultOptions`.
  final String? ovulationTest;

  /// Private free text about a test, up to 500 characters.
  final String? testNote;

  /// true = taken, false = explicitly not taken, null = not logged.
  final bool? medicineTaken;

  /// Up to 80 characters.
  final String? medicineName;

  /// Dose as prescribed, free text up to 80 characters.
  final String? medicineDose;

  /// Options: `careActionOptions`.
  final List<String> careActions;

  /// Free text up to 4000 characters. Empty = not logged.
  final String notes;

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields are cleared by passing `null` explicitly, e.g.
  /// `log.copyWith(painLevel: null)`; omitting an argument keeps the value.
  /// List fields are cleared with an empty list. Passing a value of the wrong
  /// type throws a [TypeError].
  DailyLog copyWith({
    DateTime? date,
    Object? flow = _keep,
    Object? mood = _keep,
    List<String>? symptoms,
    Object? painLevel = _keep,
    List<String>? painLocations,
    Object? painInterference = _keep,
    Object? discharge = _keep,
    Object? cervicalMucus = _keep,
    Object? cervicalPosition = _keep,
    Object? cervicalFirmness = _keep,
    Object? cervicalOpening = _keep,
    Object? temperatureCelsius = _keep,
    List<String>? temperatureContext,
    Object? weightKg = _keep,
    Object? heightCm = _keep,
    Object? sleepHours = _keep,
    Object? sleepQuality = _keep,
    Object? energy = _keep,
    Object? waterMl = _keep,
    List<String>? exerciseTypes,
    Object? exerciseMinutes = _keep,
    Object? appetite = _keep,
    Object? intimacy = _keep,
    Object? protection = _keep,
    Object? libido = _keep,
    Object? pregnancyTest = _keep,
    Object? ovulationTest = _keep,
    Object? testNote = _keep,
    Object? medicineTaken = _keep,
    Object? medicineName = _keep,
    Object? medicineDose = _keep,
    List<String>? careActions,
    String? notes,
  }) {
    return DailyLog(
      date: date ?? this.date,
      flow: _pick<FlowIntensity>(flow, this.flow),
      mood: _pick<String>(mood, this.mood),
      symptoms: symptoms ?? this.symptoms,
      painLevel: _pick<int>(painLevel, this.painLevel),
      painLocations: painLocations ?? this.painLocations,
      painInterference: _pick<String>(painInterference, this.painInterference),
      discharge: _pick<String>(discharge, this.discharge),
      cervicalMucus: _pick<String>(cervicalMucus, this.cervicalMucus),
      cervicalPosition: _pick<String>(cervicalPosition, this.cervicalPosition),
      cervicalFirmness: _pick<String>(cervicalFirmness, this.cervicalFirmness),
      cervicalOpening: _pick<String>(cervicalOpening, this.cervicalOpening),
      temperatureCelsius:
          _pick<double>(temperatureCelsius, this.temperatureCelsius),
      temperatureContext: temperatureContext ?? this.temperatureContext,
      weightKg: _pick<double>(weightKg, this.weightKg),
      heightCm: _pick<double>(heightCm, this.heightCm),
      sleepHours: _pick<double>(sleepHours, this.sleepHours),
      sleepQuality: _pick<String>(sleepQuality, this.sleepQuality),
      energy: _pick<String>(energy, this.energy),
      waterMl: _pick<int>(waterMl, this.waterMl),
      exerciseTypes: exerciseTypes ?? this.exerciseTypes,
      exerciseMinutes: _pick<int>(exerciseMinutes, this.exerciseMinutes),
      appetite: _pick<String>(appetite, this.appetite),
      intimacy: _pick<String>(intimacy, this.intimacy),
      protection: _pick<String>(protection, this.protection),
      libido: _pick<String>(libido, this.libido),
      pregnancyTest: _pick<String>(pregnancyTest, this.pregnancyTest),
      ovulationTest: _pick<String>(ovulationTest, this.ovulationTest),
      testNote: _pick<String>(testNote, this.testNote),
      medicineTaken: _pick<bool>(medicineTaken, this.medicineTaken),
      medicineName: _pick<String>(medicineName, this.medicineName),
      medicineDose: _pick<String>(medicineDose, this.medicineDose),
      careActions: careActions ?? this.careActions,
      notes: notes ?? this.notes,
    );
  }

  /// True when at least one observation is recorded.
  bool get hasObservations => observationCount > 0;

  /// Number of recorded observations: each non-null single, number or
  /// non-blank text field counts 1, each selected item of a multi-select
  /// counts 1, and non-blank [notes] counts 1. Explicit none, zero and
  /// unknown answers count, because they were recorded.
  int get observationCount {
    var count = temperatureContext.length + symptoms.length +
        painLocations.length +
        exerciseTypes.length +
        careActions.length;
    for (final value in <Object?>[
      flow,
      mood,
      painLevel,
      painInterference,
      discharge,
      cervicalMucus,
      cervicalPosition,
      cervicalFirmness,
      cervicalOpening,
      temperatureCelsius,
      weightKg,
      heightCm,
      sleepHours,
      sleepQuality,
      energy,
      waterMl,
      exerciseMinutes,
      appetite,
      intimacy,
      protection,
      libido,
      pregnancyTest,
      ovulationTest,
      testNote,
      medicineTaken,
      medicineName,
      medicineDose,
      notes,
    ]) {
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      count++;
    }
    return count;
  }

  Map<String, Object?> toJson() {
    return {
      'schema': schemaVersion,
      'date': date.toIso8601String(),
      'flow': flow?.name,
      'mood': mood,
      'symptoms': symptoms,
      'painLevel': painLevel,
      'painLocation': painLocations,
      'painInterference': painInterference,
      'discharge': discharge,
      'cervicalMucus': cervicalMucus,
      'cervicalPosition': cervicalPosition,
      'cervicalFirmness': cervicalFirmness,
      'cervicalOpening': cervicalOpening,
      'temperatureCelsius': temperatureCelsius,
      'temperatureContext': temperatureContext,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'energy': energy,
      'waterMl': waterMl,
      'exerciseType': exerciseTypes,
      'exerciseMinutes': exerciseMinutes,
      'appetite': appetite,
      'intimacy': intimacy,
      'protection': protection,
      'libido': libido,
      'pregnancyTest': pregnancyTest,
      'ovulationTest': ovulationTest,
      'testNote': testNote,
      'medicineTaken': medicineTaken,
      'medicineName': medicineName,
      'medicineDose': medicineDose,
      'careActions': careActions,
      'notes': notes,
    };
  }

  /// Reads a stored or exported log.
  ///
  /// A record without `schema`, or with `schema: 1`, was written by the old
  /// log screen, which saved `painLevel: 0`, `waterMl: 0` and
  /// `medicineTaken: false` whether or not the person recorded them. Those
  /// defaults are not observations, so they are read as not logged (`null`).
  /// Every other legacy value is kept. Schema-2 records are read as stored.
  /// Unknown keys are ignored. Throws [FormatException] (or [ArgumentError]
  /// for an unknown flow) when a known key holds the wrong type.
  factory DailyLog.fromJson(Map<String, Object?> json) {
    final rawSchema = json['schema'];
    final int schema;
    if (rawSchema == null) {
      schema = 1;
    } else if (rawSchema is int &&
        rawSchema >= 1 &&
        rawSchema <= schemaVersion) {
      schema = rawSchema;
    } else if (rawSchema is int && rawSchema > schemaVersion) {
      throw FormatException(
        'DailyLog.schema is newer than this app supports',
        rawSchema,
      );
    } else {
      throw FormatException(
        'DailyLog.schema must be a supported positive integer',
        rawSchema,
      );
    }
    final legacy = schema < schemaVersion;

    var painLevel = _readInt(json, 'painLevel');
    var waterMl = _readInt(json, 'waterMl');
    var medicineTaken = _readBool(json, 'medicineTaken');
    if (legacy) {
      if (painLevel == 0) painLevel = null;
      if (waterMl == 0) waterMl = null;
      if (medicineTaken == false) medicineTaken = null;
    }

    final rawDate = json['date'];
    if (rawDate is! String) {
      throw FormatException('DailyLog.date must be an ISO date', rawDate);
    }
    final flowName = _readString(json, 'flow');

    return DailyLog(
      date: DateTime.parse(rawDate),
      flow: flowName == null ? null : FlowIntensity.values.byName(flowName),
      mood: _readString(json, 'mood'),
      symptoms: _readStrings(json, 'symptoms'),
      painLevel: painLevel,
      painLocations: _readStrings(json, 'painLocation'),
      painInterference: _readString(json, 'painInterference'),
      discharge: _readString(json, 'discharge'),
      cervicalMucus: _readString(json, 'cervicalMucus'),
      cervicalPosition: _readString(json, 'cervicalPosition'),
      cervicalFirmness: _readString(json, 'cervicalFirmness'),
      cervicalOpening: _readString(json, 'cervicalOpening'),
      temperatureCelsius: _readDouble(json, 'temperatureCelsius'),
      temperatureContext: _readStrings(json, 'temperatureContext'),
      weightKg: _readDouble(json, 'weightKg'),
      heightCm: _readDouble(json, 'heightCm'),
      sleepHours: _readDouble(json, 'sleepHours'),
      sleepQuality: _readString(json, 'sleepQuality'),
      energy: _readString(json, 'energy'),
      waterMl: waterMl,
      exerciseTypes: _readStrings(json, 'exerciseType'),
      exerciseMinutes: _readInt(json, 'exerciseMinutes'),
      appetite: _readString(json, 'appetite'),
      intimacy: _readString(json, 'intimacy'),
      protection: _readString(json, 'protection'),
      libido: _readString(json, 'libido'),
      pregnancyTest: _readString(json, 'pregnancyTest'),
      ovulationTest: _readString(json, 'ovulationTest'),
      testNote: _readString(json, 'testNote'),
      medicineTaken: medicineTaken,
      medicineName: _readString(json, 'medicineName'),
      medicineDose: _readString(json, 'medicineDose'),
      careActions: _readStrings(json, 'careActions'),
      notes: _readString(json, 'notes') ?? '',
    );
  }

  static String? _readString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('DailyLog.$key must be text', value);
  }

  static int? _readInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double && value.isFinite && value == value.truncate()) {
      return value.toInt();
    }
    throw FormatException('DailyLog.$key must be a whole number', value);
  }

  static double? _readDouble(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw FormatException('DailyLog.$key must be a number', value);
  }

  static bool? _readBool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null || value is bool) return value as bool?;
    throw FormatException('DailyLog.$key must be true or false', value);
  }

  static List<String> _readStrings(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is List && value.every((item) => item is String)) {
      return List<String>.unmodifiable(value.cast<String>());
    }
    throw FormatException('DailyLog.$key must be a list of text', value);
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

/// One projected future cycle. Used for the multi-month calendar overlay and
/// the "plan ahead" view, where a single next-period estimate isn't enough.
class CycleForecast {
  const CycleForecast({
    required this.cycleNumber,
    required this.periodStart,
    required this.periodEnd,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.pmsWindowStart,
    required this.pmsWindowEnd,
  });

  /// 1 = the next period, 2 = the one after, and so on.
  final int cycleNumber;

  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime ovulationDate;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final DateTime pmsWindowStart;
  final DateTime pmsWindowEnd;
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
    this.pmsWindowStart,
    this.pmsWindowEnd,
    this.cycleLengthVariation = 0,
    this.cyclesTracked = 0,
    this.excludedCycles = 0,
    this.shortestCycle,
    this.longestCycle,
    this.upcomingCycles = const [],
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

  /// Start of the expected premenstrual window. Null when there is no forecast
  /// to hang it off.
  final DateTime? pmsWindowStart;

  /// Last day before the expected period.
  final DateTime? pmsWindowEnd;

  /// Standard deviation of observed cycle lengths, in days. The number behind
  /// [isIrregular] — surfaced so the UI can explain *how* variable a cycle is
  /// rather than just flagging it.
  final double cycleLengthVariation;

  /// How many complete cycles the prediction is based on.
  final int cyclesTracked;
  final int excludedCycles;

  String get estimateBasis => cyclesTracked == 0
      ? 'Based on your cycle-length setting; no completed cycles used.'
      : 'Based on $cyclesTracked completed '
          '${cyclesTracked == 1 ? 'cycle' : 'cycles'} from your recorded history.';

  String get variationSummary => cyclesTracked < 2
      ? 'Variation needs at least two included completed cycles.'
      : 'Observed variation: ${cycleLengthVariation.toStringAsFixed(1)} days '
          '(standard deviation); recorded range $shortestCycle–$longestCycle days.';

  String get estimateExplanation => '$estimateBasis $variationSummary '
      '${excludedCycles == 0 ? '' : '$excludedCycles excluded cycles were not used. '}'
      'Dates are estimates. The internal confidence score is a history heuristic, '
      'not a clinically validated probability. A late estimate stays anchored '
      'to your last recorded period until another period is logged.';

  final int? shortestCycle;
  final int? longestCycle;

  /// Projected future cycles, nearest first.
  final List<CycleForecast> upcomingCycles;

  /// Typed accessor for [phase].
  CyclePhase get currentPhase => CyclePhase.fromLabel(phase);

  /// True while today falls inside the premenstrual window.
  bool isPmsOn(DateTime day) {
    final start = pmsWindowStart;
    final end = pmsWindowEnd;
    if (start == null || end == null) return false;
    final target = DateTime(day.year, day.month, day.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  /// Days until the premenstrual window opens; negative once inside it.
  int? daysUntilPms(DateTime from) {
    final start = pmsWindowStart;
    if (start == null) return null;
    return start.difference(DateTime(from.year, from.month, from.day)).inDays;
  }

  /// Plain-language confidence bucket, so the UI never shows a bare percentage
  /// that implies more precision than the model has.
  String get confidenceLabel {
    if (cyclesTracked < 2) return 'Learning';
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Moderate';
    return 'Low';
  }
}
