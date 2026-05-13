import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cycle_models.dart';

class CycleRepository {
  CycleRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _periodsKey = 'cyclecare.periods.v1';
  static const _logsKey = 'cyclecare.daily_logs.v1';
  static const _preferencesKey = 'cyclecare.preferences.v1';

  List<CycleEvent> loadPeriods() {
    final raw = _preferences.getString(_periodsKey);
    if (raw == null) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => CycleEvent.fromJson(item as Map<String, Object?>))
        .toList();
  }

  Future<void> savePeriods(List<CycleEvent> periods) {
    return _preferences.setString(
      _periodsKey,
      jsonEncode(periods.map((period) => period.toJson()).toList()),
    );
  }

  List<DailyLog> loadLogs() {
    final raw = _preferences.getString(_logsKey);
    if (raw == null) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => DailyLog.fromJson(item as Map<String, Object?>))
        .toList();
  }

  Future<void> saveLogs(List<DailyLog> logs) {
    return _preferences.setString(
      _logsKey,
      jsonEncode(logs.map((log) => log.toJson()).toList()),
    );
  }

  CyclePreferences loadPreferences() {
    final raw = _preferences.getString(_preferencesKey);
    if (raw == null) {
      return const CyclePreferences();
    }
    return CyclePreferences.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> savePreferences(CyclePreferences preferences) {
    return _preferences.setString(
        _preferencesKey, jsonEncode(preferences.toJson()));
  }

  Future<String> exportJson() async {
    return const JsonEncoder.withIndent('  ').convert({
      'periods': loadPeriods().map((period) => period.toJson()).toList(),
      'dailyLogs': loadLogs().map((log) => log.toJson()).toList(),
      'preferences': loadPreferences().toJson(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteAll() async {
    await _preferences.remove(_periodsKey);
    await _preferences.remove(_logsKey);
    await _preferences.remove(_preferencesKey);
  }
}
