import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/period_repository_impl.dart';
import '../../data/repositories/daily_log_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/period_repository.dart';
import '../../domain/repositories/daily_log_repository.dart';
import '../../domain/repositories/settings_repository.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Repository providers
final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return PeriodRepositoryImpl(database);
});

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return DailyLogRepositoryImpl(database);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return SettingsRepositoryImpl(database);
});
