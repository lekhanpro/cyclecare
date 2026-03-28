import '../entities/daily_log.dart';

abstract class DailyLogRepository {
  Future<List<DailyLog>> getAllDailyLogs();
  Future<DailyLog?> getDailyLogByDate(DateTime date);
  Stream<List<DailyLog>> watchAllDailyLogs();
  Future<int> insertDailyLog(DailyLog log);
  Future<bool> updateDailyLog(DailyLog log);
  Future<int> deleteDailyLog(int id);
  Future<List<DailyLog>> getLogsInRange(DateTime start, DateTime end);
}
