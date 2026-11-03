import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/daily_log_validator.dart';
import 'package:cyclecare/features/tracking/domain/logging_catalog.dart';
import 'package:cyclecare/features/tracking/domain/tracking_options.dart';
import 'package:flutter_test/flutter_test.dart';

final _day = DateTime(2026, 10, 3);
final _empty = DailyLog(date: _day);

List<String> _labels(String fieldId) => [
  for (final option in LoggingCatalog.field(fieldId)!.options) option.label,
];

void main() {
  group('counts match redesign/logging-catalog.json', () {
    test('12 groups, 38 fields including the date, 214 options', () {
      expect(LoggingCatalog.groups, hasLength(12));
      expect(LoggingCatalog.fields, hasLength(38));
      expect(LoggingCatalog.optionCount, 214);
      final implemented = LoggingCatalog.fields
          .expand((f) => f.options)
          .where((o) => o.implemented)
          .length;
      expect(implemented, 74);
      expect(LoggingCatalog.sourceCounts.groups, 12);
      expect(LoggingCatalog.sourceCounts.fields, 38);
      expect(LoggingCatalog.sourceCounts.options, 214);
    });

    test('field ids are unique and the date comes first', () {
      final ids = LoggingCatalog.fields.map((f) => f.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.first, 'date');
      expect(LoggingCatalog.date.required, isTrue);
    });

    test('group order and titles', () {
      expect(LoggingCatalog.groups.map((g) => g.id), [
        'flow',
        'mood',
        'symptoms',
        'pain',
        'fertility',
        'body',
        'rest',
        'movement',
        'intimacy',
        'tests',
        'medication',
        'personal',
      ]);
      expect(LoggingCatalog.groups[1].title, 'How are you feeling?');
      expect(LoggingCatalog.groups[1].tone, 'sage');
    });
  });

  group('options mirror tracking_options.dart', () {
    test('labels and order', () {
      expect(_labels('mood'), catalogueMoodOptions);
      expect(_labels('symptomsBody'), bodySymptomOptions);
      expect(_labels('symptomsDigestion'), digestionSymptomOptions);
      expect(_labels('symptomsSkin'), skinSymptomOptions);
      expect(_labels('symptomsRest'), restSymptomOptions);
      expect(_labels('discharge'), catalogueDischargeOptions);
      expect(_labels('cervicalMucus'), cervicalMucusOptions);
      expect(_labels('cervicalPosition'), cervicalPositionOptions);
      expect(_labels('cervicalFirmness'), cervicalFirmnessOptions);
      expect(_labels('cervicalOpening'), cervicalOpeningOptions);
      expect(_labels('painLocation'), painLocationOptions);
      expect(_labels('sleepQuality'), sleepQualityOptions);
      expect(_labels('energy'), energyOptions);
      expect(_labels('exerciseType'), exerciseTypeOptions);
      expect(_labels('appetite'), appetiteOptions);
      expect(_labels('intimacy'), intimacyOptions);
      expect(_labels('protection'), protectionOptions);
      expect(_labels('libido'), libidoOptions);
      expect(_labels('pregnancyTest'), testResultOptions);
      expect(_labels('ovulationTest'), testResultOptions);
      expect(_labels('careActions'), careActionOptions);
      expect(_labels('medicineTaken'), medicineTakenOptions);
      expect(_labels('flow'), FlowIntensity.values.map((f) => f.label));
    });

    test('only the options the current app offers are implemented', () {
      bool isImplemented(String field, String label) => LoggingCatalog.field(
        field,
      )!.options.firstWhere((o) => o.label == label).implemented;
      expect(isImplemented('flow', 'Very heavy'), isFalse);
      expect(isImplemented('flow', 'Heavy'), isTrue);
      expect(isImplemented('mood', 'Tension'), isFalse);
      for (final mood in moodOptions) {
        expect(isImplemented('mood', mood), isTrue, reason: mood);
      }
    });
  });

  group('bindings', () {
    test('every catalogue field has a binding, and nothing else does', () {
      expect(
        logFieldBindings.keys.toSet(),
        LoggingCatalog.fields.map((f) => f.id).toSet(),
      );
      for (final field in LoggingCatalog.fields) {
        expect(field.binding, isNotNull, reason: field.id);
      }
    });

    test('an empty log reads as not logged everywhere but the date', () {
      for (final field in LoggingCatalog.fields.skip(1)) {
        expect(field.binding.read(_empty), isNull, reason: field.id);
        expect(field.binding.isLogged(_empty), isFalse, reason: field.id);
      }
      expect(LoggingCatalog.date.binding.read(_empty), _day);
    });

    test('every option round-trips through write and read', () {
      var checked = 0;
      for (final field in LoggingCatalog.fields) {
        for (final option in field.options) {
          final binding = field.binding;
          if (field.kind == LogFieldKind.multi) {
            final log = binding.write(_empty, [option.value]);
            expect(binding.read(log), [
              option.value,
            ], reason: '${field.id}/${option.label}');
          } else {
            final log = binding.write(_empty, option.value);
            expect(
              binding.read(log),
              option.value,
              reason: '${field.id}/${option.label}',
            );
          }
          checked++;
        }
      }
      expect(checked, 214);
    });

    test('options survive JSON persistence', () {
      for (final field in LoggingCatalog.fields) {
        for (final option in field.options) {
          final binding = field.binding;
          final value = field.kind == LogFieldKind.multi
              ? [option.value]
              : option.value;
          final stored = DailyLog.fromJson(
            binding.write(_empty, value).toJson(),
          );
          expect(
            binding.read(stored),
            value,
            reason: '${field.id}/${option.label}',
          );
          expect(
            DailyLogValidator.validate(stored),
            isEmpty,
            reason: '${field.id}/${option.label}',
          );
        }
      }
    });

    test('clear makes every field not logged again', () {
      var log = _empty;
      for (final field in LoggingCatalog.fields.skip(1)) {
        final value = switch (field.kind) {
          LogFieldKind.multi => [field.options.first.value],
          LogFieldKind.number => field.min ?? 1,
          LogFieldKind.text || LogFieldKind.textarea => 'Something',
          LogFieldKind.custom => ['Jaw tension'],
          _ => field.options.first.value,
        };
        log = field.binding.write(log, value);
        expect(field.binding.isLogged(log), isTrue, reason: field.id);
      }
      for (final field in LoggingCatalog.fields.skip(1)) {
        log = field.binding.clear(log);
        expect(field.binding.read(log), isNull, reason: field.id);
      }
      expect(log.hasObservations, isFalse);
      expect(
        () => LoggingCatalog.date.binding.clear(log),
        throwsUnsupportedError,
      );
    });

    test('explicit zero, none and false are values, not cleared', () {
      final pain = LoggingCatalog.field('painLevel')!.binding;
      final water = LoggingCatalog.field('waterMl')!.binding;
      final medicine = LoggingCatalog.field('medicineTaken')!.binding;
      final flow = LoggingCatalog.field('flow')!.binding;
      expect(pain.read(pain.write(_empty, 0)), 0);
      expect(water.read(water.write(_empty, 0)), 0);
      expect(medicine.read(medicine.write(_empty, false)), isFalse);
      expect(
        flow.read(flow.write(_empty, FlowIntensity.none)),
        FlowIntensity.none,
      );
      expect(pain.read(pain.write(pain.write(_empty, 3), null)), isNull);
    });

    test('number fields write numbers and reject other types', () {
      final temperature = LoggingCatalog.field('temperatureCelsius')!.binding;
      final minutes = LoggingCatalog.field('exerciseMinutes')!.binding;
      expect(temperature.read(temperature.write(_empty, 36)), 36.0);
      expect(minutes.read(minutes.write(_empty, 30.0)), 30);
      expect(() => minutes.write(_empty, 30.5), throwsArgumentError);
      expect(() => temperature.write(_empty, '36.5'), throwsArgumentError);
      expect(
        () => LoggingCatalog.field('mood')!.binding.write(_empty, 3),
        throwsArgumentError,
      );
    });

    test('blank text is not an observation', () {
      final note = LoggingCatalog.field('testNote')!.binding;
      expect(note.read(note.write(_empty, '   ')), isNull);
      final notes = LoggingCatalog.field('notes')!.binding;
      expect(notes.write(_empty, null).notes, '');
    });

    test(
      'symptom groups and custom tags share symptoms without clobbering',
      () {
        final body = LoggingCatalog.field('symptomsBody')!.binding;
        final skin = LoggingCatalog.field('symptomsSkin')!.binding;
        final custom = LoggingCatalog.field('customTags')!.binding;

        var log = DailyLog(
          date: _day,
          symptoms: const ['Cramps', 'Acne', 'Jaw tension', 'Backache'],
        );
        expect(body.read(log), ['Cramps', 'Backache']);
        expect(skin.read(log), ['Acne']);
        expect(custom.read(log), ['Jaw tension']);

        log = body.write(log, ['Migraine']);
        expect(log.symptoms.toSet(), {'Acne', 'Jaw tension', 'Migraine'});

        log = custom.clear(log);
        expect(log.symptoms.toSet(), {'Acne', 'Migraine'});

        expect(() => skin.write(log, ['Cramps']), throwsArgumentError);
        expect(() => custom.write(log, ['Cramps']), throwsArgumentError);
      },
    );

    test('multi-select writes drop duplicates and keep order', () {
      final care = LoggingCatalog.field('careActions')!.binding;
      expect(care.read(care.write(_empty, ['Rest', 'Heat pad', 'Rest'])), [
        'Rest',
        'Heat pad',
      ]);
      expect(care.read(care.write(_empty, const <String>[])), isNull);
    });
  });

  group('field metadata', () {
    test('json keys point at DailyLog keys', () {
      final keys = _empty.toJson().keys.toSet();
      for (final field in LoggingCatalog.fields) {
        expect(keys, contains(field.jsonKey), reason: field.id);
      }
      expect(LoggingCatalog.field('symptomsSkin')!.jsonKey, 'symptoms');
      expect(LoggingCatalog.field('customTags')!.jsonKey, 'symptoms');
      expect(LoggingCatalog.field('exerciseType')!.jsonKey, 'exerciseType');
    });

    test('number ranges match the validator boundaries', () {
      for (final field in LoggingCatalog.fields) {
        if (field.kind != LogFieldKind.number &&
            field.kind != LogFieldKind.scale) {
          continue;
        }
        expect(field.min, isNotNull, reason: field.id);
        expect(field.max, isNotNull, reason: field.id);
        final binding = field.binding;
        expect(
          DailyLogValidator.validate(binding.write(_empty, field.min)),
          isEmpty,
          reason: '${field.id} min',
        );
        expect(
          DailyLogValidator.validate(binding.write(_empty, field.max)),
          isEmpty,
          reason: '${field.id} max',
        );
        expect(
          DailyLogValidator.validate(binding.write(_empty, field.max! + 1)),
          isNotEmpty,
          reason: '${field.id} above max',
        );
      }
    });

    test('units are explicit', () {
      expect(LoggingCatalog.field('temperatureCelsius')!.unit, '°C');
      expect(LoggingCatalog.field('weightKg')!.unit, 'kg');
      expect(LoggingCatalog.field('heightCm')!.unit, 'cm');
      expect(LoggingCatalog.field('sleepHours')!.unit, 'h');
      expect(LoggingCatalog.field('waterMl')!.unit, 'ml');
      expect(LoggingCatalog.field('exerciseMinutes')!.unit, 'min');
    });

    test('private fields are flagged', () {
      expect(LoggingCatalog.fields.where((f) => f.private).map((f) => f.id), [
        'intimacy',
        'protection',
        'libido',
        'pregnancyTest',
        'ovulationTest',
        'testNote',
      ]);
    });
  });
}
