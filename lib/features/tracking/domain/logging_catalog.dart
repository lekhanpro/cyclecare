/// The redesigned daily-logging catalogue as data, with a binding from every
/// field to [DailyLog].
///
/// Pure Dart (no Flutter imports). Groups, fields and options are generated
/// from `redesign/logging-catalog.json` by `tool/logging_catalog/generate.js`
/// into `logging_catalog_data.dart`; the bindings in this file are hand-written.
///
/// The catalogue describes what can be stored and validated. An option or
/// field with `implemented: false` was planned at the original design inspection.
/// These historical provenance flags do not gate the current catalogue-driven
/// production controls, model, persistence or validation. Icon names are the
/// catalogue's semantic icon strings, not Flutter icons.
library;

import 'cycle_models.dart';
import 'tracking_options.dart';

part 'logging_catalog_data.dart';

enum LogFieldKind { date, single, multi, scale, number, text, textarea, custom }

/// One choice of a single, multi or scale field.
class LogOption {
  const LogOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.implemented,
  });

  /// The value the field's binding writes: a [FlowIntensity] for `flow`, an
  /// `int` for `painLevel`, a `bool` for `medicineTaken`, otherwise the
  /// label itself.
  final Object value;

  final String label;

  /// Semantic icon name from the catalogue.
  final String icon;

  /// False when the option is planned in the design.
  final bool implemented;
}

class LogField {
  const LogField({
    required this.id,
    required this.label,
    required this.icon,
    required this.kind,
    required this.implemented,
    required this.jsonKey,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.hint,
    this.placeholder,
    this.note,
    this.preview,
    this.required = false,
    this.private = false,
    this.options = const [],
  });

  /// Catalogue field id.
  final String id;
  final String label;
  final String icon;
  final LogFieldKind kind;
  final bool implemented;

  /// The `DailyLog` JSON key holding this field. Equal to [id] except for the
  /// four symptom groups and custom tags, which share `symptoms`.
  final String jsonKey;

  /// Display unit, e.g. '°C', 'kg', 'cm', 'h', 'ml', 'min'.
  final String? unit;

  /// Inclusive accepted range for number and scale fields, matching
  /// `DailyLogValidator`.
  final num? min;
  final num? max;
  final num? step;

  final String? hint;
  final String? placeholder;
  final String? note;

  /// How many options the design shows before "show all".
  final int? preview;

  /// Only the date is required.
  final bool required;

  /// Never shared with a partner or sent to an AI service.
  final bool private;

  final List<LogOption> options;

  LogFieldBinding get binding => logFieldBindings[id]!;
}

class LogGroup {
  const LogGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.fields,
    this.tone,
    this.description,
    this.modelNotes,
  });

  final String id;
  final String title;
  final String icon;

  /// Design tone ('sage', 'peach', 'violet'), or null for the default.
  final String? tone;
  final String? description;
  final String? modelNotes;
  final List<LogField> fields;
}

abstract final class LoggingCatalog {
  /// Catalogue version the data was generated from.
  static const String version = _catalogVersion;

  /// The `counts` block of the source JSON (checked by the generator).
  static const sourceCounts = _sourceCounts;

  /// The log date. Not part of any group.
  static const LogField date = _dateField;

  static const List<LogGroup> groups = _groups;

  /// Every field: [date] first, then each group's fields in order.
  static List<LogField> get fields => [
    date,
    for (final group in groups) ...group.fields,
  ];

  static LogField? field(String id) {
    for (final field in fields) {
      if (field.id == id) return field;
    }
    return null;
  }

  static int get optionCount =>
      fields.fold(0, (sum, field) => sum + field.options.length);
}

/// Reads and writes one catalogue field on a [DailyLog].
class LogFieldBinding {
  const LogFieldBinding({
    required this.read,
    required this.write,
    required this.clear,
  });

  /// The recorded value, or null when the field is not logged. Multi-select
  /// fields return a non-empty `List<String>`. Explicit none, zero, false
  /// and unknown answers are values, not null.
  final Object? Function(DailyLog log) read;

  /// A copy of the log with `value` recorded; `null` clears the field.
  /// Throws [ArgumentError] when `value` has the wrong type or, for symptom
  /// groups, belongs to another group. Range and option checks are left to
  /// `DailyLogValidator`.
  final DailyLog Function(DailyLog log, Object? value) write;

  /// A copy of the log with the field not logged. Throws [UnsupportedError]
  /// for the date, which is required.
  final DailyLog Function(DailyLog log) clear;

  bool isLogged(DailyLog log) => read(log) != null;
}

/// Binding for every catalogue field id.
final Map<String, LogFieldBinding>
logFieldBindings = Map.unmodifiable(<String, LogFieldBinding>{
  'date': LogFieldBinding(
    read: (log) => log.date,
    write: (log, value) => log.copyWith(date: _as<DateTime>(value)),
    clear: (_) => throw UnsupportedError('The log date is required.'),
  ),
  'flow': _value<FlowIntensity>((l) => l.flow, (l, v) => l.copyWith(flow: v)),
  'mood': _text((l) => l.mood, (l, v) => l.copyWith(mood: v)),
  'symptomsBody': _symptomGroup(bodySymptomOptions),
  'symptomsDigestion': _symptomGroup(digestionSymptomOptions),
  'symptomsSkin': _symptomGroup(skinSymptomOptions),
  'symptomsRest': _symptomGroup(restSymptomOptions),
  'painLevel': _int((l) => l.painLevel, (l, v) => l.copyWith(painLevel: v)),
  'painInterference': _text(
    (l) => l.painInterference,
    (l, v) => l.copyWith(painInterference: v),
  ),
  'temperatureContext': _list(
    (l) => l.temperatureContext,
    (l, v) => l.copyWith(temperatureContext: v),
  ),
  'painLocation': _list(
    (l) => l.painLocations,
    (l, v) => l.copyWith(painLocations: v),
  ),
  'discharge': _text((l) => l.discharge, (l, v) => l.copyWith(discharge: v)),
  'cervicalMucus': _text(
    (l) => l.cervicalMucus,
    (l, v) => l.copyWith(cervicalMucus: v),
  ),
  'cervicalPosition': _text(
    (l) => l.cervicalPosition,
    (l, v) => l.copyWith(cervicalPosition: v),
  ),
  'cervicalFirmness': _text(
    (l) => l.cervicalFirmness,
    (l, v) => l.copyWith(cervicalFirmness: v),
  ),
  'cervicalOpening': _text(
    (l) => l.cervicalOpening,
    (l, v) => l.copyWith(cervicalOpening: v),
  ),
  'temperatureCelsius': _double(
    (l) => l.temperatureCelsius,
    (l, v) => l.copyWith(temperatureCelsius: v),
  ),
  'weightKg': _double((l) => l.weightKg, (l, v) => l.copyWith(weightKg: v)),
  'heightCm': _double((l) => l.heightCm, (l, v) => l.copyWith(heightCm: v)),
  'sleepHours': _double(
    (l) => l.sleepHours,
    (l, v) => l.copyWith(sleepHours: v),
  ),
  'waterMl': _int((l) => l.waterMl, (l, v) => l.copyWith(waterMl: v)),
  'sleepQuality': _text(
    (l) => l.sleepQuality,
    (l, v) => l.copyWith(sleepQuality: v),
  ),
  'energy': _text((l) => l.energy, (l, v) => l.copyWith(energy: v)),
  'exerciseType': _list(
    (l) => l.exerciseTypes,
    (l, v) => l.copyWith(exerciseTypes: v),
  ),
  'exerciseMinutes': _int(
    (l) => l.exerciseMinutes,
    (l, v) => l.copyWith(exerciseMinutes: v),
  ),
  'appetite': _text((l) => l.appetite, (l, v) => l.copyWith(appetite: v)),
  'intimacy': _text((l) => l.intimacy, (l, v) => l.copyWith(intimacy: v)),
  'protection': _text((l) => l.protection, (l, v) => l.copyWith(protection: v)),
  'libido': _text((l) => l.libido, (l, v) => l.copyWith(libido: v)),
  'pregnancyTest': _text(
    (l) => l.pregnancyTest,
    (l, v) => l.copyWith(pregnancyTest: v),
  ),
  'ovulationTest': _text(
    (l) => l.ovulationTest,
    (l, v) => l.copyWith(ovulationTest: v),
  ),
  'testNote': _text((l) => l.testNote, (l, v) => l.copyWith(testNote: v)),
  'medicineTaken': _value<bool>(
    (l) => l.medicineTaken,
    (l, v) => l.copyWith(medicineTaken: v),
  ),
  'medicineName': _text(
    (l) => l.medicineName,
    (l, v) => l.copyWith(medicineName: v),
  ),
  'medicineDose': _text(
    (l) => l.medicineDose,
    (l, v) => l.copyWith(medicineDose: v),
  ),
  'careActions': _list(
    (l) => l.careActions,
    (l, v) => l.copyWith(careActions: v),
  ),
  'notes': _text((l) => l.notes, (l, v) => l.copyWith(notes: v ?? '')),
  'customTags': _customTags(),
});

typedef _Get<T> = T? Function(DailyLog log);
typedef _Set<T> = DailyLog Function(DailyLog log, T? value);

T _as<T>(Object? value) {
  if (value is T) return value;
  throw ArgumentError.value(value, 'value', 'expected $T');
}

LogFieldBinding _binding<T extends Object>(
  _Get<T> get,
  _Set<T> set,
  T? Function(Object value) coerce,
) {
  return LogFieldBinding(
    read: get,
    write: (log, value) => set(log, value == null ? null : coerce(value)),
    clear: (log) => set(log, null),
  );
}

LogFieldBinding _value<T extends Object>(_Get<T> get, _Set<T> set) =>
    _binding<T>(get, set, _as<T>);

/// Text and single-select labels. Blank text is not an observation.
LogFieldBinding _text(_Get<String> get, _Set<String> set) {
  return LogFieldBinding(
    read: (log) {
      final value = get(log);
      return value == null || value.trim().isEmpty ? null : value;
    },
    write: (log, value) {
      final text = value == null ? null : _as<String>(value);
      return set(log, text == null || text.trim().isEmpty ? null : text);
    },
    clear: (log) => set(log, null),
  );
}

LogFieldBinding _int(_Get<int> get, _Set<int> set) {
  return _binding<int>(get, set, (value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncate()) {
      return value.toInt();
    }
    throw ArgumentError.value(value, 'value', 'expected a whole number');
  });
}

LogFieldBinding _double(_Get<double> get, _Set<double> set) =>
    _binding<double>(get, set, (value) => _as<num>(value).toDouble());

List<String> _strings(Object value) {
  if (value is List && value.every((item) => item is String)) {
    // Order kept, duplicates dropped.
    return List<String>.unmodifiable(value.cast<String>().toSet());
  }
  throw ArgumentError.value(value, 'value', 'expected a list of text');
}

LogFieldBinding _list(
  List<String> Function(DailyLog log) get,
  DailyLog Function(DailyLog log, List<String> value) set,
) {
  return LogFieldBinding(
    read: (log) {
      final value = get(log);
      return value.isEmpty ? null : value;
    },
    write: (log, value) => set(log, value == null ? const [] : _strings(value)),
    clear: (log) => set(log, const []),
  );
}

bool _isBuiltInSymptom(String symptom) =>
    catalogueSymptomOptions.contains(canonicalOption('symptoms', symptom));

/// The four symptom groups and custom tags share `DailyLog.symptoms`. Each
/// binding reads and replaces only its own entries. A legacy alias (e.g.
/// 'Backache') belongs to the group of the option it stands for and is kept
/// as stored.
LogFieldBinding _symptomPartition({
  required bool Function(String symptom) owns,
  required String description,
}) {
  DailyLog replace(DailyLog log, List<String> selected) => log.copyWith(
    symptoms: [
      for (final symptom in log.symptoms)
        if (!owns(symptom)) symptom,
      ...selected,
    ],
  );

  return LogFieldBinding(
    read: (log) {
      final mine = [
        for (final symptom in log.symptoms)
          if (owns(symptom)) symptom,
      ];
      return mine.isEmpty ? null : mine;
    },
    write: (log, value) {
      if (value == null) return replace(log, const []);
      final selected = _strings(value);
      for (final symptom in selected) {
        if (!owns(symptom)) {
          throw ArgumentError.value(symptom, 'value', 'not $description');
        }
      }
      return replace(log, selected);
    },
    clear: (log) => replace(log, const []),
  );
}

LogFieldBinding _symptomGroup(List<String> group) => _symptomPartition(
  owns: (symptom) => group.contains(canonicalOption('symptoms', symptom)),
  description: 'in this symptom group',
);

LogFieldBinding _customTags() => _symptomPartition(
  owns: (symptom) => !_isBuiltInSymptom(symptom),
  description: 'a custom tag (it is a built-in symptom)',
);
