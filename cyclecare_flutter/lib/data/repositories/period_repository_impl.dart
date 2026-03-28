import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../../domain/entities/period.dart' as domain;
import '../../domain/repositories/period_repository.dart';
import '../database/app_database.dart';

class PeriodRepositoryImpl implements PeriodRepository {
  final AppDatabase _database;

  PeriodRepositoryImpl(this._database);

  @override
  Future<List<domain.Period>> getAllPeriods() async {
    final periods = await _database.getAllPeriods();
    return periods.map(_toDomain).toList();
  }

  @override
  Future<domain.Period?> getPeriodById(int id) async {
    final period = await _database.getPeriodById(id);
    return period != null ? _toDomain(period) : null;
  }

  @override
  Stream<List<domain.Period>> watchAllPeriods() {
    return _database.watchAllPeriods().map(
          (periods) => periods.map(_toDomain).toList(),
        );
  }

  @override
  Future<int> insertPeriod(domain.Period period) {
    return _database.insertPeriod(
      PeriodsCompanion.insert(
        startDate: period.startDate,
        endDate: drift.Value(period.endDate),
        symptoms: drift.Value(jsonEncode(period.symptoms)),
        notes: drift.Value(period.notes ?? ''),
      ),
    );
  }

  @override
  Future<bool> updatePeriod(domain.Period period) {
    return _database.updatePeriod(
      Period(
        id: period.id,
        startDate: period.startDate,
        endDate: period.endDate,
        symptoms: jsonEncode(period.symptoms),
        notes: period.notes ?? '',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<int> deletePeriod(int id) {
    return _database.deletePeriod(id);
  }

  @override
  Future<List<domain.Period>> getPeriodsInRange(
      DateTime start, DateTime end) async {
    final allPeriods = await getAllPeriods();
    return allPeriods
        .where((p) =>
            p.startDate.isAfter(start.subtract(const Duration(days: 1))) &&
            p.startDate.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  @override
  Future<domain.Period?> getLastPeriod() async {
    final periods = await getAllPeriods();
    if (periods.isEmpty) return null;
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    return periods.first;
  }

  domain.Period _toDomain(Period period) {
    List<String> symptoms = [];
    try {
      symptoms = (jsonDecode(period.symptoms) as List).cast<String>();
    } catch (e) {
      symptoms = [];
    }

    return domain.Period(
      id: period.id,
      startDate: period.startDate,
      endDate: period.endDate,
      symptoms: symptoms,
      notes: period.notes.isEmpty ? null : period.notes,
    );
  }
}
