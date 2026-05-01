import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/services/firebase_sync_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/security_service.dart';
import '../../data/database/app_database.dart';
import '../../domain/engines/cycle_prediction_engine.dart';
import '../../features/tracking/application/cycle_tracker_controller.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

// Legacy providers kept for backward compatibility with presentation/screens/
final periodsProvider = StreamProvider<List<PeriodRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllPeriods();
});

final dailyLogsProvider = StreamProvider<List<DailyLogRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllDailyLogs();
});

final latestPeriodProvider = FutureProvider<PeriodRecord?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getLatestPeriod();
});

final cyclePredictionProvider = FutureProvider<CyclePrediction>((ref) async {
  final trackerState = await ref.watch(cycleTrackerControllerProvider.future);
  final startDates = trackerState.periods.map((p) => p.startDate).toList();
  return CyclePredictionEngine.predict(periodStartDates: startDates);
});

// SharedPreferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// Onboarding completed
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('onboarding_completed') ?? false;
});

// User mode provider with persistence
final userModeProvider = StateNotifierProvider<UserModeNotifier, String>((ref) {
  return UserModeNotifier(ref);
});

class UserModeNotifier extends StateNotifier<String> {
  UserModeNotifier(this.ref) : super('track_periods') {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getString('user_mode') ?? 'track_periods';
  }

  Future<void> setMode(String mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('user_mode', mode);
    state = mode;
  }
}

// Current cycle length with persistence
final cycleLengthProvider = StateNotifierProvider<CycleLengthNotifier, int>((ref) {
  return CycleLengthNotifier(ref);
});

class CycleLengthNotifier extends StateNotifier<int> {
  CycleLengthNotifier(this.ref) : super(28) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getInt('cycle_length') ?? 28;
  }

  Future<void> setLength(int length) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt('cycle_length', length);
    state = length;
  }
}

// Current period length with persistence
final periodLengthProvider = StateNotifierProvider<PeriodLengthNotifier, int>((ref) {
  return PeriodLengthNotifier(ref);
});

class PeriodLengthNotifier extends StateNotifier<int> {
  PeriodLengthNotifier(this.ref) : super(5) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getInt('period_length') ?? 5;
  }

  Future<void> setLength(int length) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt('period_length', length);
    state = length;
  }
}

// Selected date provider
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Theme color provider with persistence
final themeColorProvider = StateNotifierProvider<ThemeColorNotifier, int>((ref) {
  return ThemeColorNotifier(ref);
});

class ThemeColorNotifier extends StateNotifier<int> {
  ThemeColorNotifier(this.ref) : super(0xFFE91E63) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getInt('theme_color') ?? 0xFFE91E63;
  }

  Future<void> setColor(int color) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt('theme_color', color);
    state = color;
  }
}

// Dark mode provider with persistence
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier(ref);
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier(this.ref) : super(false) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool('dark_mode') ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('dark_mode', value);
    state = value;
  }
}

// Privacy mode provider with persistence
final privacyModeProvider = StateNotifierProvider<PrivacyModeNotifier, bool>((ref) {
  return PrivacyModeNotifier(ref);
});

class PrivacyModeNotifier extends StateNotifier<bool> {
  PrivacyModeNotifier(this.ref) : super(false) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool('privacy_mode') ?? false;
  }

  Future<void> setPrivacyMode(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('privacy_mode', value);
    state = value;
  }
}

// AI enabled provider
final aiEnabledProvider = StateNotifierProvider<AIEnabledNotifier, bool>((ref) {
  return AIEnabledNotifier(ref);
});

class AIEnabledNotifier extends StateNotifier<bool> {
  AIEnabledNotifier(this.ref) : super(false) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool('ai_enabled') ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('ai_enabled', value);
    state = value;
  }
}

// AI use personal data provider
final aiUsePersonalDataProvider = StateNotifierProvider<AIUsePersonalDataNotifier, bool>((ref) {
  return AIUsePersonalDataNotifier(ref);
});

class AIUsePersonalDataNotifier extends StateNotifier<bool> {
  AIUsePersonalDataNotifier(this.ref) : super(false) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool('ai_use_personal_data') ?? false;
  }

  Future<void> setUsePersonalData(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('ai_use_personal_data', value);
    state = value;
  }
}

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Reminders provider
final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.loadReminders();
});

// Security service provider
final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

// App lock enabled provider
final appLockEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(securityServiceProvider);
  return service.isLockEnabled;
});


// Firebase sync service provider
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  return FirebaseSyncService();
});

// Auth sync listener (local-first): push/pull when user signs in
final authSyncProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) async {
    final user = next.valueOrNull;
    if (user != null) {
      final sync = ref.read(firebaseSyncServiceProvider);
      await sync.sync(user);
    }
  });
  return;
});
