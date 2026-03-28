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
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Insert default settings
        await into(settings).insert(
          SettingsCompanion.insert(
            id: const Value(1),
            theme: 'system',
            primaryColor: '#E91E63',
            averageCycleLength: 28,
            averagePeriodLength: 5,
            lutealPhaseLength: 14,
            temperatureUnit: 'celsius',
            dateFormat: 'MMM dd, yyyy',
            language: 'en',
            isPinEnabled: false,
            pinHash: '',
            isBiometricEnabled: false,
            isPrivacyModeEnabled: false,
            hideNotificationContent: true,
            notificationsEnabled: true,
            quietHoursEnabled: false,
            quietHoursStart: '22:00',
            quietHoursEnd: '07:00',
            onboardingCompleted: false,
            pregnancyMode: false,
            breastfeedingMode: false,
            menopauseMode: false,
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cyclecare.db'));
    return NativeDatabase(file);
  });
}
