import 'cycle_models.dart';
import 'tracking_options.dart';

/// One problem with a [DailyLog]. [field] is the catalogue field id (the JSON
/// key), so a form can attach the message to the right control.
class DailyLogIssue {
  const DailyLogIssue(this.field, this.message);

  final String field;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is DailyLogIssue &&
      other.field == field &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, message);

  @override
  String toString() => '$field: $message';
}

/// Thrown when saving a [DailyLog] that fails [DailyLogValidator].
class InvalidDailyLogException implements Exception {
  const InvalidDailyLogException(this.issues);

  final List<DailyLogIssue> issues;

  @override
  String toString() => 'InvalidDailyLogException: ${issues.join('; ')}';
}

/// Pure range, length and option checks for a [DailyLog].
///
/// Null and empty values are never issues: every observation is optional.
/// Free-text values in fields that existed before schema 2 (mood, discharge,
/// cervical fields, symptoms) are not checked against option lists, so old
/// records and custom symptom tags stay readable. Fields added in schema 2
/// must hold a known option.
class DailyLogValidator {
  DailyLogValidator._();

  static const int medicineNameMaxLength = 80;
  static const int medicineDoseMaxLength = 80;
  static const int testNoteMaxLength = 500;
  static const int notesMaxLength = 4000;

  static List<DailyLogIssue> validate(DailyLog log) {
    final issues = <DailyLogIssue>[];

    void range(String field, num? value, num min, num max, String unit) {
      if (value == null) return;
      if (value is double && !value.isFinite) {
        issues.add(DailyLogIssue(field, 'must be a number'));
      } else if (value < min || value > max) {
        issues.add(DailyLogIssue(field, 'must be between $min and $max$unit'));
      }
    }

    void length(String field, String? value, int max) {
      if (value != null && value.length > max) {
        issues.add(DailyLogIssue(field, 'must be at most $max characters'));
      }
    }

    void option(String field, String? value, List<String> options) {
      if (value != null && !options.contains(value)) {
        issues.add(DailyLogIssue(field, 'unknown option "$value"'));
      }
    }

    void options(String field, List<String> values, List<String> known) {
      for (final value in values) {
        option(field, value, known);
      }
      if (values.toSet().length != values.length) {
        issues.add(DailyLogIssue(field, 'contains duplicates'));
      }
    }

    range('painLevel', log.painLevel, 0, 10, '');
    range('temperatureCelsius', log.temperatureCelsius, 34, 43, ' °C');
    range('weightKg', log.weightKg, 20, 350, ' kg');
    range('heightCm', log.heightCm, 50, 250, ' cm');
    range('sleepHours', log.sleepHours, 0, 24, ' h');
    range('waterMl', log.waterMl, 0, 10000, ' ml');
    range('exerciseMinutes', log.exerciseMinutes, 0, 1440, ' min');

    length('medicineName', log.medicineName, medicineNameMaxLength);
    length('medicineDose', log.medicineDose, medicineDoseMaxLength);
    length('testNote', log.testNote, testNoteMaxLength);
    length('notes', log.notes, notesMaxLength);

    option('sleepQuality', log.sleepQuality, sleepQualityOptions);
    option('painInterference', log.painInterference, painInterferenceOptions);
    options(
      'temperatureContext',
      log.temperatureContext,
      temperatureContextOptions,
    );
    option('energy', log.energy, energyOptions);
    option('appetite', log.appetite, appetiteOptions);
    option('intimacy', log.intimacy, intimacyOptions);
    option('protection', log.protection, protectionOptions);
    option('libido', log.libido, libidoOptions);
    option('pregnancyTest', log.pregnancyTest, testResultOptions);
    option('ovulationTest', log.ovulationTest, testResultOptions);

    options('painLocation', log.painLocations, painLocationOptions);
    options('exerciseType', log.exerciseTypes, exerciseTypeOptions);
    options('careActions', log.careActions, careActionOptions);

    return issues;
  }

  static bool isValid(DailyLog log) => validate(log).isEmpty;
}
