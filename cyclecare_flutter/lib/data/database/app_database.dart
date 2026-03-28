import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/periods_table.dart';
import 'tables/daily_logs_table.dart';
import 'tables/reminders_table.dart';
import 'tables/settings_table.dart';
import 'tables/birth_control_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Periods,
  DailyLogs,
  Reminders,
  Settings,
  BirthControl,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Insert default settings
          await into(settings).insert(
            SettingsCompanion.insert(),
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle future migrations here
        },
      );

  // Periods queries
  Future<List<Period>> getAllPeriods() => select(periods).get();
  
  Future<Period?> getPeriodById(int id) =>
      (select(periods)..where((p) => p.id.equals(id))).getSingleOrNull();
  
  Stream<List<Period>> watchAllPeriods() => select(periods).watch();
  
  Future<int> insertPeriod(PeriodsCompanion period) =>
      into(periods).insert(period);
  
  Future<bool> updatePeriod(Period period) =>
      update(periods).replace(period);
  
  Future<int> deletePeriod(int id) =>
      (delete(periods)..where((p) => p.id.equals(id))).go();

  // Daily logs queries
  Future<List<DailyLog>> getAllDailyLogs() => select(dailyLogs).get();
  
  Future<DailyLog?> getDailyLogByDate(DateTime date) =>
      (select(dailyLogs)..where((d) => d.date.equals(date))).getSingleOrNull();
  
  Stream<List<DailyLog>> watchAllDailyLogs() => select(dailyLogs).watch();
  
  Future<int> insertDailyLog(DailyLogsCompanion log) =>
      into(dailyLogs).insert(log, mode: InsertMode.insertOrReplace);
  
  Future<bool> updateDailyLog(DailyLog log) =>
      update(dailyLogs).replace(log);
  
  Future<int> deleteDailyLog(int id) =>
      (delete(dailyLogs)..where((d) => d.id.equals(id))).go();

  // Reminders queries
  Future<List<Reminder>> getAllReminders() => select(reminders).get();
  
  Future<List<Reminder>> getEnabledReminders() =>
      (select(reminders)..where((r) => r.enabled.equals(true))).get();
  
  Stream<List<Reminder>> watchAllReminders() => select(reminders).watch();
  
  Future<int> insertReminder(RemindersCompanion reminder) =>
      into(reminders).insert(reminder);
  
  Future<bool> updateReminder(Reminder reminder) =>
      update(reminders).replace(reminder);
  
  Future<int> deleteReminder(int id) =>
      (delete(reminders)..where((r) => r.id.equals(id))).go();

  // Settings queries
  Future<Setting?> getSettings() =>
      (select(settings)..where((s) => s.id.equals(1))).getSingleOrNull();
  
  Stream<Setting?> watchSettings() =>
      (select(settings)..where((s) => s.id.equals(1))).watchSingleOrNull();
  
  Future<bool> updateSettings(Setting setting) =>
      update(settings).replace(setting);

  // Birth control queries
  Future<List<BirthControlData>> getAllBirthControl() =>
      select(birthControl).get();
  
  Future<BirthControlData?> getActiveBirthControl() =>
      (select(birthControl)..where((b) => b.endDate.isNull())).getSingleOrNull();
  
  Stream<List<BirthControlData>> watchAllBirthControl() =>
      select(birthControl).watch();
  
  Future<int> insertBirthControl(BirthControlCompanion bc) =>
      into(birthControl).insert(bc);
  
  Future<bool> updateBirthControl(BirthControlData bc) =>
      update(birthControl).replace(bc);
  
  Future<int> deleteBirthControl(int id) =>
      (delete(birthControl)..where((b) => b.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cyclecare.db'));
    return NativeDatabase(file);
  });
}
