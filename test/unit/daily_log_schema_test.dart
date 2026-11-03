import 'dart:convert';

import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/daily_log_validator.dart';
import 'package:flutter_test/flutter_test.dart';

final _day = DateTime(2026, 10, 3);

/// A schema-2 log with every field set.
DailyLog fullLog() => DailyLog(
      date: _day,
      flow: FlowIntensity.veryHeavy,
      mood: 'Calm',
      symptoms: const ['Cramps', 'Jaw tension'],
      painLevel: 6,
      painLocations: const ['Lower belly', 'Head'],
      discharge: 'Egg-white',
      cervicalMucus: 'Watery',
      cervicalPosition: 'High',
      cervicalFirmness: 'Soft',
      cervicalOpening: 'Open',
      temperatureCelsius: 36.55,
      weightKg: 61.2,
      heightCm: 168.5,
      sleepHours: 7.5,
      sleepQuality: 'Restless',
      energy: 'Steady',
      waterMl: 1750,
      exerciseTypes: const ['Yoga', 'Walking'],
      exerciseMinutes: 45,
      appetite: 'More than usual',
      intimacy: 'Partnered',
      protection: 'Condom',
      libido: 'High',
      pregnancyTest: 'Negative',
      ovulationTest: 'Positive',
      testNote: 'Morning, brand A',
      medicineTaken: true,
      medicineName: 'Ibuprofen',
      medicineDose: '200 mg',
      careActions: const ['Heat pad', 'Rest'],
      notes: 'Long day',
    );

DailyLog roundTrip(DailyLog log) =>
    DailyLog.fromJson(jsonDecode(jsonEncode(log.toJson())) as Map<String, Object?>);

void main() {
  group('FlowIntensity', () {
    test('veryHeavy is appended so stored names and earlier indexes hold', () {
      expect(FlowIntensity.values.map((f) => f.name), [
        'none',
        'spotting',
        'light',
        'medium',
        'heavy',
        'veryHeavy',
      ]);
      expect(FlowIntensity.heavy.intensity, 4);
      expect(FlowIntensity.veryHeavy.intensity, 5);
      expect(FlowIntensity.veryHeavy.label, 'Very heavy');
    });
  });

  group('toJson / fromJson', () {
    test('writes schema 2 and the catalogue field ids', () {
      final json = fullLog().toJson();
      expect(json['schema'], 2);
      expect(json['painLocation'], ['Lower belly', 'Head']);
      expect(json['exerciseType'], ['Yoga', 'Walking']);
      expect(json['flow'], 'veryHeavy');
      for (final key in [
        'date', 'flow', 'mood', 'symptoms', 'painLevel', 'painLocation',
        'discharge', 'cervicalMucus', 'cervicalPosition', 'cervicalFirmness',
        'cervicalOpening', 'temperatureCelsius', 'weightKg', 'heightCm',
        'sleepHours', 'sleepQuality', 'energy', 'waterMl', 'exerciseType',
        'exerciseMinutes', 'appetite', 'intimacy', 'protection', 'libido',
        'pregnancyTest', 'ovulationTest', 'testNote', 'medicineTaken',
        'medicineName', 'medicineDose', 'careActions', 'notes',
      ]) {
        expect(json.containsKey(key), isTrue, reason: key);
      }
    });

    test('every field round-trips through JSON', () {
      final original = fullLog();
      final restored = roundTrip(original);
      expect(restored.toJson(), original.toJson());
    });

    test('an empty schema-2 log round-trips as not logged', () {
      final restored = roundTrip(DailyLog(date: _day));
      expect(restored.painLevel, isNull);
      expect(restored.waterMl, isNull);
      expect(restored.medicineTaken, isNull);
      expect(restored.flow, isNull);
      expect(restored.painLocations, isEmpty);
      expect(restored.hasObservations, isFalse);
    });

    test('schema 2 keeps explicit zero, none, false and unknown answers', () {
      final log = DailyLog(
        date: _day,
        flow: FlowIntensity.none,
        painLevel: 0,
        waterMl: 0,
        medicineTaken: false,
        protection: 'Not sure',
        pregnancyTest: 'Not taken',
        intimacy: 'Prefer not to say',
      );
      final restored = roundTrip(log);
      expect(restored.flow, FlowIntensity.none);
      expect(restored.painLevel, 0);
      expect(restored.waterMl, 0);
      expect(restored.medicineTaken, isFalse);
      expect(restored.protection, 'Not sure');
      expect(restored.pregnancyTest, 'Not taken');
      expect(restored.intimacy, 'Prefer not to say');
      expect(restored.observationCount, 7);
    });

    test('legacy record: old UI defaults become not logged', () {
      final legacy = <String, Object?>{
        'date': '2025-04-02T00:00:00.000',
        'flow': 'light',
        'mood': 'Tense',
        'symptoms': ['Cramps', 'My own tag'],
        'painLevel': 0,
        'discharge': 'Something odd',
        'temperatureCelsius': 36,
        'waterMl': 0,
        'medicineTaken': false,
        'medicineName': null,
        'notes': '',
      };
      final log = DailyLog.fromJson(legacy);
      expect(log.painLevel, isNull);
      expect(log.waterMl, isNull);
      expect(log.medicineTaken, isNull);
      // Everything else is kept exactly.
      expect(log.flow, FlowIntensity.light);
      expect(log.mood, 'Tense');
      expect(log.symptoms, ['Cramps', 'My own tag']);
      expect(log.discharge, 'Something odd');
      expect(log.temperatureCelsius, 36.0);
      // New fields are not invented.
      expect(log.painLocations, isEmpty);
      expect(log.sleepQuality, isNull);
      expect(log.intimacy, isNull);
      expect(log.observationCount, 6);
    });

    test('legacy record: real observations survive migration', () {
      final log = DailyLog.fromJson(const {
        'date': '2025-04-02T00:00:00.000',
        'painLevel': 4,
        'waterMl': 1500,
        'medicineTaken': true,
      });
      expect(log.painLevel, 4);
      expect(log.waterMl, 1500);
      expect(log.medicineTaken, isTrue);
    });

    test('schema 1 is treated as legacy too', () {
      final log = DailyLog.fromJson(const {
        'schema': 1,
        'date': '2025-04-02T00:00:00.000',
        'painLevel': 0,
        'waterMl': 0,
        'medicineTaken': false,
      });
      expect(log.painLevel, isNull);
      expect(log.waterMl, isNull);
      expect(log.medicineTaken, isNull);
    });

    test('a legacy record with only defaults has no observations', () {
      final log = DailyLog.fromJson(const {
        'date': '2025-04-02T00:00:00.000',
        'symptoms': <String>[],
        'painLevel': 0,
        'waterMl': 0,
        'medicineTaken': false,
        'notes': '',
      });
      expect(log.hasObservations, isFalse);
    });

    test('a migrated legacy record is written back as schema 2', () {
      final log = DailyLog.fromJson(const {
        'date': '2025-04-02T00:00:00.000',
        'painLevel': 0,
      });
      final json = log.toJson();
      expect(json['schema'], 2);
      expect(json['painLevel'], isNull);
      expect(DailyLog.fromJson(json).painLevel, isNull);
    });

    test('unknown keys are ignored', () {
      final log = DailyLog.fromJson(const {
        'schema': 2,
        'date': '2025-04-02T00:00:00.000',
        'somethingFromTheFuture': {'a': 1},
        'painLevel': 3,
      });
      expect(log.painLevel, 3);
    });

    test('whole-number doubles are accepted for integer fields', () {
      final log = DailyLog.fromJson(const {
        'schema': 2,
        'date': '2025-04-02T00:00:00.000',
        'waterMl': 500.0,
        'exerciseMinutes': 30.0,
      });
      expect(log.waterMl, 500);
      expect(log.exerciseMinutes, 30);
    });

    test('wrong types are rejected rather than silently coerced', () {
      Map<String, Object?> base(String key, Object? value) =>
          {'schema': 2, 'date': '2025-04-02T00:00:00.000', key: value};
      expect(() => DailyLog.fromJson(base('painLevel', 'high')),
          throwsFormatException);
      expect(() => DailyLog.fromJson(base('waterMl', 2.5)),
          throwsFormatException);
      expect(() => DailyLog.fromJson(base('medicineTaken', 'yes')),
          throwsFormatException);
      expect(() => DailyLog.fromJson(base('painLocation', 'Head')),
          throwsFormatException);
      expect(() => DailyLog.fromJson(base('exerciseType', [1, 2])),
          throwsFormatException);
      expect(() => DailyLog.fromJson(base('schema', 'two')),
          throwsFormatException);
      expect(() => DailyLog.fromJson(const {'schema': 2}),
          throwsFormatException);
      expect(() => DailyLog.fromJson(base('flow', 'gushing')),
          throwsArgumentError);
    });
  });

  group('copyWith', () {
    test('omitted arguments keep values', () {
      final log = fullLog();
      expect(log.copyWith().toJson(), log.toJson());
    });

    test('explicit null clears nullable fields', () {
      final cleared = fullLog().copyWith(
        flow: null,
        mood: null,
        painLevel: null,
        waterMl: null,
        medicineTaken: null,
        heightCm: null,
        intimacy: null,
        testNote: null,
        exerciseMinutes: null,
      );
      expect(cleared.flow, isNull);
      expect(cleared.mood, isNull);
      expect(cleared.painLevel, isNull);
      expect(cleared.waterMl, isNull);
      expect(cleared.medicineTaken, isNull);
      expect(cleared.heightCm, isNull);
      expect(cleared.intimacy, isNull);
      expect(cleared.testNote, isNull);
      expect(cleared.exerciseMinutes, isNull);
      // Untouched fields are kept.
      expect(cleared.protection, 'Condom');
      expect(cleared.symptoms, ['Cramps', 'Jaw tension']);
    });

    test('sets values and clears lists with an empty list', () {
      final log = DailyLog(date: _day)
          .copyWith(painLevel: 0, careActions: ['Rest'])
          .copyWith(careActions: const []);
      expect(log.painLevel, 0);
      expect(log.careActions, isEmpty);
    });

    test('a value of the wrong type throws', () {
      expect(() => DailyLog(date: _day).copyWith(painLevel: 'high'),
          throwsA(isA<TypeError>()));
    });
  });

  group('observations', () {
    test('counts every field of a full log', () {
      // 27 single/number/text fields + notes, plus multi items:
      // symptoms 2, painLocations 2, exerciseTypes 2, careActions 2.
      expect(fullLog().observationCount, 27 + 8);
      expect(fullLog().hasObservations, isTrue);
    });

    test('blank text does not count', () {
      final log = DailyLog(date: _day, notes: '   ', testNote: '');
      expect(log.observationCount, 0);
    });

    test('each multi-select item counts once', () {
      final log = DailyLog(
        date: _day,
        symptoms: const ['Cramps', 'Acne', 'Nausea'],
      );
      expect(log.observationCount, 3);
    });
  });

  group('DailyLogValidator', () {
    List<String> fields(DailyLog log) =>
        DailyLogValidator.validate(log).map((i) => i.field).toList();

    test('a full valid log and an empty log have no issues', () {
      expect(DailyLogValidator.validate(fullLog()), isEmpty);
      expect(DailyLogValidator.validate(DailyLog(date: _day)), isEmpty);
    });

    test('accepts range boundaries', () {
      final log = DailyLog(
        date: _day,
        painLevel: 10,
        temperatureCelsius: 34,
        weightKg: 350,
        heightCm: 50,
        sleepHours: 0,
        waterMl: 10000,
        exerciseMinutes: 1440,
      );
      expect(DailyLogValidator.validate(log), isEmpty);
      expect(
        DailyLogValidator.isValid(DailyLog(
          date: _day,
          painLevel: 0,
          temperatureCelsius: 43,
          weightKg: 20,
          heightCm: 250,
          sleepHours: 24,
          waterMl: 0,
          exerciseMinutes: 0,
        )),
        isTrue,
      );
    });

    test('rejects out-of-range numbers', () {
      final low = DailyLog(
        date: _day,
        painLevel: -1,
        temperatureCelsius: 33.9,
        weightKg: 19.9,
        heightCm: 49,
        sleepHours: -0.5,
        waterMl: -1,
        exerciseMinutes: -5,
      );
      final high = DailyLog(
        date: _day,
        painLevel: 11,
        temperatureCelsius: 43.1,
        weightKg: 351,
        heightCm: 251,
        sleepHours: 24.5,
        waterMl: 10001,
        exerciseMinutes: 1441,
      );
      const expected = [
        'painLevel', 'temperatureCelsius', 'weightKg', 'heightCm',
        'sleepHours', 'waterMl', 'exerciseMinutes',
      ];
      expect(fields(low), expected);
      expect(fields(high), expected);
      expect(fields(DailyLog(date: _day, sleepHours: double.nan)),
          ['sleepHours']);
    });

    test('enforces text caps', () {
      final ok = DailyLog(
        date: _day,
        medicineName: 'a' * 80,
        medicineDose: 'b' * 80,
        testNote: 'c' * 500,
        notes: 'd' * 4000,
      );
      expect(DailyLogValidator.validate(ok), isEmpty);
      final tooLong = DailyLog(
        date: _day,
        medicineName: 'a' * 81,
        medicineDose: 'b' * 81,
        testNote: 'c' * 501,
        notes: 'd' * 4001,
      );
      expect(fields(tooLong),
          ['medicineName', 'medicineDose', 'testNote', 'notes']);
    });

    test('planned single and multi selects must be known options', () {
      final log = DailyLog(
        date: _day,
        sleepQuality: 'Great',
        energy: 'Medium',
        appetite: 'Huge',
        intimacy: 'Yes',
        protection: 'Pill',
        libido: 'Very high',
        pregnancyTest: 'Pregnant',
        ovulationTest: 'Peak',
        painLocations: const ['Knee'],
        exerciseTypes: const ['Rowing'],
        careActions: const ['Massage'],
      );
      expect(fields(log), [
        'sleepQuality', 'energy', 'appetite', 'intimacy', 'protection',
        'libido', 'pregnancyTest', 'ovulationTest', 'painLocation',
        'exerciseType', 'careActions',
      ]);
    });

    test('rejects duplicate multi-select items', () {
      final log = DailyLog(date: _day, careActions: const ['Rest', 'Rest']);
      expect(fields(log), ['careActions']);
    });

    test('legacy free text in existing fields stays valid', () {
      final log = DailyLog(
        date: _day,
        mood: 'Tense',
        discharge: 'Something odd',
        cervicalMucus: 'Egg white',
        symptoms: const ['My own tag', 'Backache'],
      );
      expect(DailyLogValidator.validate(log), isEmpty);
    });
  });
}
