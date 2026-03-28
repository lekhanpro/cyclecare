import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../../domain/entities/daily_log.dart' as domain;
import '../../domain/repositories/daily_log_repository.dart';
import '../database/app_database.dart';

class DailyLogRepositoryImpl implements DailyLogRepository {
  final AppDatabase _database;

  DailyLogRepositoryImpl(this._database);

  @override
  Future<List<domain.DailyLog>> getAllDailyLogs() async {
    final logs = await _database.getAllDailyLogs();
    return logs.map(_toDomain).toList();
  }

  @override
  Future<domain.DailyLog?> getDailyLogByDate(DateTime date) async {
    final log = await _database.getDailyLogByDate(date);
    return log != null ? _toDomain(log) : null;
  }

  @override
  Stream<List<domain.DailyLog>> watchAllDailyLogs() {
    return _database.watchAllDailyLogs().map(
          (logs) => logs.map(_toDomain).toList(),
        );
  }

  @override
  Future<int> insertDailyLog(domain.DailyLog log) {
    return _database.insertDailyLog(
      DailyLogsCompanion.insert(
        date: log.date,
        flow: drift.Value(log.flow),
        mood: drift.Value(log.mood),
        symptoms: drift.Value(jsonEncode(log.symptoms)),
        discharge: drift.Value(log.discharge),
        weightKg: drift.Value(log.weightKg),
        temperature: drift.Value(log.temperature),
        ovulationTest: drift.Value(log.ovulationTest ?? ''),
        pregnancyTest: drift.Value(log.pregnancyTest ?? ''),
        intimacy: drift.Value(log.intimacy ?? false),
        waterMl: drift.Value(log.waterMl),
        cervicalMucus: drift.Value(log.cervicalMucus),
        sexualActivity: drift.Value(log.sexualActivity ?? false),
        sleepHours: drift.Value(log.sleepHours),
        exerciseMinutes: drift.Value(log.exerciseMinutes),
        notes: drift.Value(log.notes),
      ),
    );
  }

  @override
  Future<bool> updateDailyLog(domain.DailyLog log) {
    return _database.updateDailyLog(
      DailyLog(
        id: log.id,
        date: log.date,
        flow: log.flow,
        mood: log.mood,
        symptoms: jsonEncode(log.symptoms),
        discharge: log.discharge,
        weightKg: log.weightKg,
        temperature: log.temperature,
        ovulationTest: log.ovulationTest ?? '',
        pregnancyTest: log.pregnancyTest ?? '',
        intimacy: log.intimacy ?? false,
        waterMl: log.waterMl,
        cervicalMucus: log.cervicalMucus,
        sexualActivity: log.sexualActivity ?? false,
        sleepHours: log.sleepHours,
        exerciseMinutes: log.exerciseMinutes,
        notes: log.notes,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<int> deleteDailyLog(int id) {
    return _database.deleteDailyLog(id);
  }

  @override
  Future<List<domain.DailyLog>> getLogsInRange(
      DateTime start, DateTime end) async {
    final allLogs = await getAllDailyLogs();
    return allLogs
        .where((log) =>
            log.date.isAfter(start.subtract(const Duration(days: 1))) &&
            log.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  domain.DailyLog _toDomain(DailyLog log) {
    List<String> symptoms = [];
    try {
      symptoms = (jsonDecode(log.symptoms) as List).cast<String>();
    } catch (e) {
      symptoms = [];
    }

    return domain.DailyLog(
      id: log.id,
      date: log.date,
      flow: log.flow,
      mood: log.mood,
      symptoms: symptoms,
      discharge: log.discharge,
      weightKg: log.weightKg,
      temperature: log.temperature,
      ovulationTest: log.ovulationTest.isEmpty ? null : log.ovulationTest,
      pregnancyTest: log.pregnancyTest.isEmpty ? null : log.pregnancyTest,
      intimacy: log.intimacy,
      waterMl: log.waterMl,
      cervicalMucus: log.cervicalMucus,
      sexualActivity: log.sexualActivity,
      sleepHours: log.sleepHours,
      exerciseMinutes: log.exerciseMinutes,
      notes: log.notes,
    );
  }
}
