import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'tables/periods_table.dart';
import 'tables/daily_logs_table.dart';
import 'tables/reminders_table.dart';
import 'tables/settings_table.dart';
import 'tables/birth_control_table.dart';
import 'tables/pregnancy_table.dart';
import 'tables/health_conditions_table.dart';
import 'tables/cervical_observations_table.dart';
import 'tables/user_profiles_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Periods,
  DailyLogs,
  Reminders,
  Settings,
  BirthControl,
  PregnancyData,
  PregnancyAppointments,
  KickCounts,
  Contractions,
  HealthConditions,
  HealthConditionLogs,
  HealthData,
  CervicalObservations,
  UserProfiles,
  PartnerSharing,
  EducationalBookmarks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(pregnancyData);
            await m.createTable(pregnancyAppointments);
            await m.createTable(kickCounts);
            await m.createTable(contractions);
            await m.createTable(healthConditions);
            await m.createTable(healthConditionLogs);
            await m.createTable(healthData);
            await m.createTable(cervicalObservations);
          }
          if (from < 3) {
            await m.createTable(userProfiles);
            await m.createTable(partnerSharing);
            await m.createTable(educationalBookmarks);
          }
        },
      );

  // ── Period Queries ──
  Future<List<Period>> getAllPeriods() => select(periods).get();
  Stream<List<Period>> watchAllPeriods() => select(periods).watch();
  Future<int> insertPeriod(PeriodsCompanion entry) => into(periods).insert(entry);
  Future<bool> updatePeriod(Period entry) => update(periods).replace(entry);
  Future<int> deletePeriod(Period entry) => delete(periods).delete(entry);

  Future<Period?> getLatestPeriod() async {
    final query = select(periods)
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)])
      ..limit(1);
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  Future<List<Period>> getPeriodsBetween(DateTime start, DateTime end) {
    final query = select(periods)
      ..where((t) => t.startDate.isBetweenValues(start, end));
    return query.get();
  }

  // ── Daily Log Queries ──
  Future<List<DailyLog>> getAllDailyLogs() => select(dailyLogs).get();
  Stream<List<DailyLog>> watchAllDailyLogs() => select(dailyLogs).watch();
  Future<int> insertDailyLog(DailyLogsCompanion entry) => into(dailyLogs).insert(entry);
  Future<bool> updateDailyLog(DailyLog entry) => update(dailyLogs).replace(entry);

  Future<DailyLog?> getDailyLogForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = select(dailyLogs)
      ..where((t) => t.date.isBetweenValues(start, end));
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  Stream<DailyLog?> watchDailyLogForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = select(dailyLogs)
      ..where((t) => t.date.isBetweenValues(start, end));
    return query.watchSingleOrNull();
  }

  // ── Reminders Queries ──
  Future<List<Reminder>> getAllReminders() => select(reminders).get();
  Stream<List<Reminder>> watchAllReminders() => select(reminders).watch();
  Future<int> insertReminder(RemindersCompanion entry) => into(reminders).insert(entry);
  Future<bool> updateReminder(Reminder entry) => update(reminders).replace(entry);
  Future<int> deleteReminder(Reminder entry) => delete(reminders).delete(entry);

  // ── Settings Queries ──
  Future<List<Setting>> getSettings() => select(settings).get();
  Future<int> insertSetting(SettingsCompanion entry) => into(settings).insert(entry);
  Future<bool> updateSetting(Setting entry) => update(settings).replace(entry);

  Future<Setting?> getSettingByKey(String key) async {
    final query = select(settings)..where((t) => t.key.equals(key));
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  // ── Birth Control Queries ──
  Future<List<BirthControlData>> getAllBirthControl() => select(birthControl).get();
  Stream<List<BirthControlData>> watchAllBirthControl() => select(birthControl).watch();
  Future<int> insertBirthControl(BirthControlCompanion entry) =>
      into(birthControl).insert(entry);
  Future<bool> updateBirthControlData(BirthControlData entry) =>
      update(birthControl).replace(entry);

  Future<BirthControlData?> getActiveBirthControl() async {
    final query = select(birthControl)..where((t) => t.endDate.isNull());
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  // ── Pregnancy Queries ──
  Future<PregnancyDataData?> getActivePregnancy() async {
    final query = select(pregnancyData)
      ..where((t) => t.isActive.equals(true))
      ..limit(1);
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  Stream<PregnancyDataData?> watchActivePregnancy() {
    final query = select(pregnancyData)
      ..where((t) => t.isActive.equals(true))
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<int> insertPregnancy(PregnancyDataCompanion entry) =>
      into(pregnancyData).insert(entry);
  Future<bool> updatePregnancyData(PregnancyDataData entry) =>
      update(pregnancyData).replace(entry);

  Future<List<PregnancyAppointment>> getPregnancyAppointments(int pregnancyId) {
    final query = select(pregnancyAppointments)
      ..where((t) => t.pregnancyId.equals(pregnancyId))
      ..orderBy([(t) => OrderingTerm.asc(t.appointmentDate)]);
    return query.get();
  }

  Future<int> insertAppointment(PregnancyAppointmentsCompanion entry) =>
      into(pregnancyAppointments).insert(entry);

  Future<int> insertKickCount(KickCountsCompanion entry) =>
      into(kickCounts).insert(entry);
  Future<bool> updateKickCount(KickCount entry) =>
      update(kickCounts).replace(entry);
  Future<List<KickCount>> getKickCountsForPregnancy(int pregnancyId) {
    final query = select(kickCounts)
      ..where((t) => t.pregnancyId.equals(pregnancyId))
      ..orderBy([(t) => OrderingTerm.desc(t.sessionStart)]);
    return query.get();
  }

  Future<int> insertContraction(ContractionsCompanion entry) =>
      into(contractions).insert(entry);
  Future<List<Contraction>> getContractionsForPregnancy(int pregnancyId) {
    final query = select(contractions)
      ..where((t) => t.pregnancyId.equals(pregnancyId))
      ..orderBy([(t) => OrderingTerm.desc(t.startTime)]);
    return query.get();
  }

  // ── Health Conditions Queries ──
  Future<List<HealthCondition>> getActiveHealthConditions() {
    final query = select(healthConditions)..where((t) => t.isActive.equals(true));
    return query.get();
  }

  Future<int> insertHealthCondition(HealthConditionsCompanion entry) =>
      into(healthConditions).insert(entry);
  Future<int> insertHealthConditionLog(HealthConditionLogsCompanion entry) =>
      into(healthConditionLogs).insert(entry);
  Future<List<HealthConditionLog>> getConditionLogs(int conditionId) {
    final query = select(healthConditionLogs)
      ..where((t) => t.conditionId.equals(conditionId))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.get();
  }

  // ── Health Data Queries ──
  Future<int> insertHealthDataEntry(HealthDataCompanion entry) =>
      into(healthData).insert(entry);
  Future<List<HealthDataData>> getHealthDataBetween(DateTime start, DateTime end) {
    final query = select(healthData)
      ..where((t) => t.date.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);
    return query.get();
  }

  Future<HealthDataData?> getHealthDataForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = select(healthData)..where((t) => t.date.isBetweenValues(start, end));
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  // ── Cervical Observations ──
  Future<int> insertCervicalObservation(CervicalObservationsCompanion entry) =>
      into(cervicalObservations).insert(entry);
  Future<CervicalObservation?> getCervicalForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = select(cervicalObservations)
      ..where((t) => t.date.isBetweenValues(start, end));
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  // ── User Profiles ──
  Future<List<UserProfile>> getAllProfiles() => select(userProfiles).get();
  Future<int> insertProfile(UserProfilesCompanion entry) =>
      into(userProfiles).insert(entry);
  Future<bool> updateProfile(UserProfile entry) =>
      update(userProfiles).replace(entry);

  // ── Partner Sharing ──
  Future<int> insertPartnerSharing(PartnerSharingCompanion entry) =>
      into(partnerSharing).insert(entry);
  Future<List<PartnerSharingData>> getPartnerSharings(int profileId) {
    final query = select(partnerSharing)
      ..where((t) => t.profileId.equals(profileId));
    return query.get();
  }

  // ── Educational Bookmarks ──
  Future<List<EducationalBookmark>> getBookmarks() =>
      select(educationalBookmarks).get();
  Future<int> insertBookmark(EducationalBookmarksCompanion entry) =>
      into(educationalBookmarks).insert(entry);
  Future<int> deleteBookmark(EducationalBookmark entry) =>
      delete(educationalBookmarks).delete(entry);

  // ── Data Export ──
  Future<Map<String, dynamic>> exportAllData() async {
    return {
      'periods': (await getAllPeriods()).map((p) => {
            'id': p.id,
            'startDate': p.startDate.toIso8601String(),
            'endDate': p.endDate?.toIso8601String(),
            'symptoms': p.symptoms,
            'notes': p.notes,
          }).toList(),
      'dailyLogs': (await getAllDailyLogs()).map((l) => {
            'id': l.id,
            'date': l.date.toIso8601String(),
            'flow': l.flow,
            'mood': l.mood,
            'symptoms': l.symptoms,
            'notes': l.notes,
          }).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // ── Delete All Data ──
  Future<void> deleteAllData() async {
    await delete(periods).go();
    await delete(dailyLogs).go();
    await delete(reminders).go();
    await delete(birthControl).go();
    await delete(pregnancyData).go();
    await delete(pregnancyAppointments).go();
    await delete(kickCounts).go();
    await delete(contractions).go();
    await delete(healthConditions).go();
    await delete(healthConditionLogs).go();
    await delete(healthData).go();
    await delete(cervicalObservations).go();
    await delete(partnerSharing).go();
    await delete(educationalBookmarks).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cyclecare.db'));
    return NativeDatabase.createInBackground(file);
  });
}
