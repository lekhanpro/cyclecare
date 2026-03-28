import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import '../../domain/engines/cycle_prediction_engine.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

// SharedPreferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// Onboarding completed
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('onboarding_completed') ?? false;
});

// User mode provider
final userModeProvider = StateProvider<String>((ref) => 'track_periods');

// Current cycle length
final cycleLengthProvider = StateProvider<int>((ref) => 28);

// Current period length
final periodLengthProvider = StateProvider<int>((ref) => 5);

// Selected date provider
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Theme color provider
final themeColorProvider = StateProvider<int>((ref) => 0xFFE91E63);

// Dark mode provider
final darkModeProvider = StateProvider<bool>((ref) => false);

// Privacy mode provider (hide content in app switcher)
final privacyModeProvider = StateProvider<bool>((ref) => false);

// Periods stream
final periodsProvider = StreamProvider<List<PeriodRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllPeriods();
});

// Daily logs stream
final dailyLogsProvider = StreamProvider<List<DailyLogRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllDailyLogs();
});

// Latest period
final latestPeriodProvider = FutureProvider<PeriodRecord?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getLatestPeriod();
});

// Cycle prediction provider
final cyclePredictionProvider = FutureProvider<CyclePrediction>((ref) async {
  final periods = await ref.watch(periodsProvider.future);
  final startDates = periods.map((p) => p.startDate).toList();
  return CyclePredictionEngine.predict(periodStartDates: startDates);
});
