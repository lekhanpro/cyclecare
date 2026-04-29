import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local database using SharedPreferences + in-memory cache.
/// Replaces Drift to avoid code-gen dependency during build.
/// Production apps should migrate to Drift/sqflite with build_runner.

class PeriodRecord {
  final int id;
  final DateTime startDate;
  final DateTime? endDate;
  final String symptoms;
  final String notes;

  PeriodRecord({
    required this.id,
    required this.startDate,
    this.endDate,
    this.symptoms = '[]',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'symptoms': symptoms,
        'notes': notes,
      };

  factory PeriodRecord.fromJson(Map<String, dynamic> json) => PeriodRecord(
        id: json['id'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        symptoms: json['symptoms'] as String? ?? '[]',
        notes: json['notes'] as String? ?? '',
      );
}

class DailyLogRecord {
  final int id;
  final DateTime date;
  final String flow;
  final String mood;
  final String symptoms;
  final String cervicalMucus;
  final String cervicalPosition;
  final String cervicalFirmness;
  final String cervicalOpening;
  final double? temperature;
  final double waterIntakeMl;
  final double? sleepHours;
  final String exerciseType;
  final int exerciseMinutes;
  final String sexualActivity;
  final String notes;

  DailyLogRecord({
    required this.id,
    required this.date,
    this.flow = '',
    this.mood = '',
    this.symptoms = '[]',
    this.cervicalMucus = '',
    this.cervicalPosition = '',
    this.cervicalFirmness = '',
    this.cervicalOpening = '',
    this.temperature,
    this.waterIntakeMl = 0,
    this.sleepHours,
    this.exerciseType = '',
    this.exerciseMinutes = 0,
    this.sexualActivity = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'flow': flow,
        'mood': mood,
        'symptoms': symptoms,
        'cervicalMucus': cervicalMucus,
        'cervicalPosition': cervicalPosition,
        'cervicalFirmness': cervicalFirmness,
        'cervicalOpening': cervicalOpening,
        'temperature': temperature,
        'waterIntakeMl': waterIntakeMl,
        'sleepHours': sleepHours,
        'exerciseType': exerciseType,
        'exerciseMinutes': exerciseMinutes,
        'sexualActivity': sexualActivity,
        'notes': notes,
      };

  factory DailyLogRecord.fromJson(Map<String, dynamic> json) => DailyLogRecord(
        id: json['id'] as int,
        date: DateTime.parse(json['date'] as String),
        flow: json['flow'] as String? ?? '',
        mood: json['mood'] as String? ?? '',
        symptoms: json['symptoms'] as String? ?? '[]',
        cervicalMucus: json['cervicalMucus'] as String? ?? '',
        cervicalPosition: json['cervicalPosition'] as String? ?? '',
        cervicalFirmness: json['cervicalFirmness'] as String? ?? '',
        cervicalOpening: json['cervicalOpening'] as String? ?? '',
        temperature: (json['temperature'] as num?)?.toDouble(),
        waterIntakeMl: (json['waterIntakeMl'] as num?)?.toDouble() ?? 0,
        sleepHours: (json['sleepHours'] as num?)?.toDouble(),
        exerciseType: json['exerciseType'] as String? ?? '',
        exerciseMinutes: json['exerciseMinutes'] as int? ?? 0,
        sexualActivity: json['sexualActivity'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
}

class AppDatabase {
  AppDatabase._();

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  // In-memory caches
  final List<PeriodRecord> _periods = [];
  final List<DailyLogRecord> _dailyLogs = [];
  int _nextPeriodId = 1;
  int _nextLogId = 1;

  final _periodsController = StreamController<List<PeriodRecord>>.broadcast();
  final _dailyLogsController = StreamController<List<DailyLogRecord>>.broadcast();

  /// Load persisted data from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final periodsJson = prefs.getString('periods');
    if (periodsJson != null) {
      final list = jsonDecode(periodsJson) as List;
      _periods.addAll(list.map((e) => PeriodRecord.fromJson(e as Map<String, dynamic>)));
      if (_periods.isNotEmpty) {
        _nextPeriodId = _periods.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
      }
    }
    final logsJson = prefs.getString('daily_logs');
    if (logsJson != null) {
      final list = jsonDecode(logsJson) as List;
      _dailyLogs.addAll(list.map((e) => DailyLogRecord.fromJson(e as Map<String, dynamic>)));
      if (_dailyLogs.isNotEmpty) {
        _nextLogId = _dailyLogs.map((l) => l.id).reduce((a, b) => a > b ? a : b) + 1;
      }
    }
    _periodsController.add(List.unmodifiable(_periods));
    _dailyLogsController.add(List.unmodifiable(_dailyLogs));
  }

  Future<void> _savePeriods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('periods', jsonEncode(_periods.map((p) => p.toJson()).toList()));
    _periodsController.add(List.unmodifiable(_periods));
  }

  Future<void> _saveDailyLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_logs', jsonEncode(_dailyLogs.map((l) => l.toJson()).toList()));
    _dailyLogsController.add(List.unmodifiable(_dailyLogs));
  }

  // ── Periods ──
  Stream<List<PeriodRecord>> watchAllPeriods() async* {
    yield List.unmodifiable(_periods);
    yield* _periodsController.stream;
  }
  Future<List<PeriodRecord>> getAllPeriods() async => List.unmodifiable(_periods);

  Future<PeriodRecord?> getLatestPeriod() async {
    if (_periods.isEmpty) return null;
    final sorted = List<PeriodRecord>.from(_periods)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted.first;
  }

  Future<int> insertPeriod({
    required DateTime startDate,
    DateTime? endDate,
    String symptoms = '[]',
    String notes = '',
  }) async {
    final id = _nextPeriodId++;
    _periods.add(PeriodRecord(
      id: id,
      startDate: startDate,
      endDate: endDate,
      symptoms: symptoms,
      notes: notes,
    ));
    await _savePeriods();
    return id;
  }

  // ── Daily Logs ──
  Stream<List<DailyLogRecord>> watchAllDailyLogs() async* {
    yield List.unmodifiable(_dailyLogs);
    yield* _dailyLogsController.stream;
  }
  Future<List<DailyLogRecord>> getAllDailyLogs() async => List.unmodifiable(_dailyLogs);

  Future<DailyLogRecord?> getDailyLogForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    try {
      return _dailyLogs.firstWhere(
        (l) => l.date.isAfter(start.subtract(const Duration(seconds: 1))) && l.date.isBefore(end),
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> insertDailyLog(DailyLogRecord record) async {
    final id = _nextLogId++;
    _dailyLogs.add(DailyLogRecord(
      id: id,
      date: record.date,
      flow: record.flow,
      mood: record.mood,
      symptoms: record.symptoms,
      cervicalMucus: record.cervicalMucus,
      cervicalPosition: record.cervicalPosition,
      cervicalFirmness: record.cervicalFirmness,
      cervicalOpening: record.cervicalOpening,
      temperature: record.temperature,
      waterIntakeMl: record.waterIntakeMl,
      sleepHours: record.sleepHours,
      exerciseType: record.exerciseType,
      exerciseMinutes: record.exerciseMinutes,
      sexualActivity: record.sexualActivity,
      notes: record.notes,
    ));
    await _saveDailyLogs();
    return id;
  }

  // ── Data Export ──
  Future<Map<String, dynamic>> exportAllData() async => {
        'periods': _periods.map((p) => p.toJson()).toList(),
        'dailyLogs': _dailyLogs.map((l) => l.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

  // ── Delete All ──
  Future<void> deleteAllData() async {
    _periods.clear();
    _dailyLogs.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('periods');
    await prefs.remove('daily_logs');
    _periodsController.add([]);
    _dailyLogsController.add([]);
  }

  void dispose() {
    _periodsController.close();
    _dailyLogsController.close();
  }
}
