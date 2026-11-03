import 'dart:convert';

import 'package:cyclecare/features/settings/application/backup_service.dart';
import 'package:cyclecare/features/tracking/data/cycle_repository.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/logging_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A schema-2 log with every field set.
DailyLog _fullLog(DateTime date) => DailyLog(
      date: date,
      flow: FlowIntensity.veryHeavy,
      mood: 'Tension',
      symptoms: const ['Cramps', 'Brain fog', 'Jaw tension'],
      painLevel: 0,
      painLocations: const ['Lower back', 'Other'],
      discharge: 'With blood',
      cervicalMucus: 'Egg-white',
      cervicalPosition: 'Low',
      cervicalFirmness: 'Firm',
      cervicalOpening: 'Partially open',
      temperatureCelsius: 36.72,
      weightKg: 70.4,
      heightCm: 172,
      sleepHours: 6.5,
      sleepQuality: 'Interrupted',
      energy: 'Low',
      waterMl: 0,
      exerciseTypes: const ['HIIT', 'Pilates'],
      exerciseMinutes: 0,
      appetite: 'Cravings',
      intimacy: 'Prefer not to say',
      protection: 'Not sure',
      libido: 'Not sure',
      pregnancyTest: 'Not taken',
      ovulationTest: 'Unclear',
      testNote: 'Faint line',
      medicineTaken: false,
      medicineName: 'Iron',
      medicineDose: 'One tablet',
      careActions: const ['Breathing', 'A little walk'],
      notes: 'Everything at once',
    );

final _legacyLog = <String, Object?>{
  'date': '2025-03-01T00:00:00.000',
  'flow': 'heavy',
  'mood': 'Tense',
  'symptoms': ['Cramps', 'Old custom tag'],
  'painLevel': 0,
  'discharge': null,
  'cervicalMucus': null,
  'cervicalPosition': null,
  'cervicalFirmness': null,
  'cervicalOpening': null,
  'temperatureCelsius': 36.4,
  'weightKg': null,
  'sleepHours': 7.0,
  'waterMl': 0,
  'medicineTaken': false,
  'medicineName': null,
  'notes': 'Old note',
};

String _backup({List<Object?>? logs}) => jsonEncode({
      'periods': [
        {
          'id': 'p1',
          'startDate': '2025-03-01T00:00:00.000',
          'endDate': null,
          'flow': 'medium',
          'symptoms': <String>[],
          'notes': '',
        },
      ],
      'dailyLogs': logs ?? [_legacyLog],
      'preferences': const CyclePreferences().toJson(),
      'exportedAt': '2025-03-10T09:00:00.000',
    });

Map<String, Object?> _schema2(Map<String, Object?> overrides) => {
      ..._fullLog(DateTime(2026, 9, 1)).toJson(),
      ...overrides,
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CycleRepository', () {
    test('saveLogs / loadLogs round-trips every field', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = CycleRepository(prefs);
      final logs = [
        _fullLog(DateTime(2026, 9, 2)),
        DailyLog(date: DateTime(2026, 9, 1)),
      ];

      await repository.saveLogs(logs);
      final loaded = CycleRepository(prefs).loadLogs();

      expect(loaded.map((l) => l.toJson()), logs.map((l) => l.toJson()));
      for (final field in LoggingCatalog.fields) {
        expect(field.binding.read(loaded.first),
            field.binding.read(logs.first),
            reason: field.id);
        if (field.id != 'date') {
          expect(field.binding.read(loaded.last), isNull, reason: field.id);
        }
      }
    });

    test('logs stored by the old app migrate on load', () async {
      SharedPreferences.setMockInitialValues({
        'cyclecare.daily_logs.v1': jsonEncode([_legacyLog]),
      });
      final repository =
          CycleRepository(await SharedPreferences.getInstance());

      final log = repository.loadLogs().single;
      expect(log.painLevel, isNull);
      expect(log.waterMl, isNull);
      expect(log.medicineTaken, isNull);
      expect(log.flow, FlowIntensity.heavy);
      expect(log.mood, 'Tense');
      expect(log.symptoms, ['Cramps', 'Old custom tag']);
      expect(log.notes, 'Old note');

      // Saving writes schema 2, so the migration is not applied twice and an
      // explicit zero recorded later survives.
      await repository.saveLogs([log.copyWith(painLevel: 0)]);
      final again = repository.loadLogs().single;
      expect(again.painLevel, 0);
      expect(again.toJson()['schema'], 2);
    });

    test('export includes every field with its catalogue key', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = CycleRepository(prefs);
      await repository.saveLogs([_fullLog(DateTime(2026, 9, 2))]);

      final export = jsonDecode(await repository.exportJson())
          as Map<String, Object?>;
      final exported =
          (export['dailyLogs'] as List).single as Map<String, Object?>;

      expect(exported['schema'], 2);
      for (final field in LoggingCatalog.fields) {
        expect(exported.containsKey(field.jsonKey), isTrue, reason: field.id);
      }
      expect(exported['painLevel'], 0);
      expect(exported['waterMl'], 0);
      expect(exported['medicineTaken'], false);
      expect(exported['flow'], 'veryHeavy');
      expect(exported['intimacy'], 'Prefer not to say');
      expect(exported['exerciseType'], ['HIIT', 'Pilates']);
    });
  });

  group('BackupService', () {
    const service = BackupService();

    test('an export restores with every field intact', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = CycleRepository(prefs);
      final original = _fullLog(DateTime(2026, 9, 2));
      await repository.saveLogs([original]);
      await repository.savePeriods([
        CycleEvent(id: 'p', startDate: DateTime(2026, 8, 30)),
      ]);

      final check = service.inspect(await repository.exportJson());
      expect(check, isA<BackupReady>());
      final preview = (check as BackupReady).preview;
      expect(preview.logs.single.toJson(), original.toJson());

      await repository.deleteAll();
      await service.restore(preview);
      expect(repository.loadLogs().single.toJson(), original.toJson());
    });

    test('an old schema-less backup migrates on restore', () async {
      final check = service.inspect(_backup());
      expect(check, isA<BackupReady>());
      final log = (check as BackupReady).preview.logs.single;
      expect(log.painLevel, isNull);
      expect(log.waterMl, isNull);
      expect(log.medicineTaken, isNull);
      expect(log.mood, 'Tense');
      expect(log.symptoms, ['Cramps', 'Old custom tag']);
      expect(log.temperatureCelsius, 36.4);

      await service.restore(check.preview);
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString(BackupKeys.dailyLogs)!)
          as List<dynamic>;
      final record = stored.single as Map<String, Object?>;
      expect(record['schema'], 2);
      expect(record['painLevel'], isNull);
      expect(record['waterMl'], isNull);
      expect(record['medicineTaken'], isNull);
    });

    test('an old backup with real observations keeps them', () {
      final check = service.inspect(_backup(logs: [
        {..._legacyLog, 'painLevel': 7, 'waterMl': 1250, 'medicineTaken': true},
      ]));
      final log = (check as BackupReady).preview.logs.single;
      expect(log.painLevel, 7);
      expect(log.waterMl, 1250);
      expect(log.medicineTaken, isTrue);
    });

    void expectRejected(Map<String, Object?> record, String reason) {
      final check = service.inspect(_backup(logs: [record]));
      expect(check, isA<BackupRejected>(), reason: reason);
    }

    test('rejects out-of-range values', () {
      expectRejected(_schema2({'painLevel': 11}), 'pain above 10');
      expectRejected(_schema2({'painLevel': -1}), 'negative pain');
      expectRejected(_schema2({'temperatureCelsius': 50}), 'temperature');
      expectRejected(_schema2({'weightKg': 5}), 'weight');
      expectRejected(_schema2({'heightCm': 300}), 'height');
      expectRejected(_schema2({'sleepHours': 25}), 'sleep');
      expectRejected(_schema2({'waterMl': -250}), 'water');
      expectRejected(_schema2({'exerciseMinutes': 2000}), 'minutes');
      expectRejected({..._legacyLog, 'painLevel': 42}, 'legacy pain');
    });

    test('rejects over-long text and unknown planned options', () {
      expectRejected(_schema2({'notes': 'x' * 4001}), 'notes');
      expectRejected(_schema2({'testNote': 'x' * 501}), 'test note');
      expectRejected(_schema2({'medicineName': 'x' * 81}), 'medicine name');
      expectRejected(_schema2({'pregnancyTest': 'Pregnant'}), 'test option');
      expectRejected(_schema2({'painLocation': ['Elbow']}), 'location');
    });

    test('rejects records with the wrong types', () {
      expectRejected(_schema2({'painLevel': 'bad'}), 'pain type');
      expectRejected(_schema2({'medicineTaken': 'yes'}), 'bool type');
      expectRejected(_schema2({'exerciseType': 'Yoga'}), 'list type');
      expectRejected(_schema2({'flow': 'torrential'}), 'unknown flow');
      expectRejected(_schema2({'schema': 'two'}), 'schema type');
    });

    test('a rejected backup writes nothing', () async {
      final prefs = await SharedPreferences.getInstance();
      await CycleRepository(prefs).saveLogs([DailyLog(date: DateTime(2026))]);
      final before = prefs.getString(BackupKeys.dailyLogs);

      final check = service.inspect(_backup(logs: [
        _legacyLog,
        _schema2({'painLevel': 99}),
      ]));
      expect(check, isA<BackupRejected>());
      expect((check as BackupRejected).reason, contains('2026-09-01'));
      expect(prefs.getString(BackupKeys.dailyLogs), before);
    });

    test('legacy free text and custom tags are still accepted', () {
      final check = service.inspect(_backup(logs: [
        {..._legacyLog, 'discharge': 'Something odd', 'mood': 'Meh'},
      ]));
      expect(check, isA<BackupReady>());
    });
  });
}
