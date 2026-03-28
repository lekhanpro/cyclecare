import '../entities/period.dart';

abstract class PeriodRepository {
  Future<List<Period>> getAllPeriods();
  Future<Period?> getPeriodById(int id);
  Stream<List<Period>> watchAllPeriods();
  Future<int> insertPeriod(Period period);
  Future<bool> updatePeriod(Period period);
  Future<int> deletePeriod(int id);
  Future<List<Period>> getPeriodsInRange(DateTime start, DateTime end);
  Future<Period?> getLastPeriod();
}
