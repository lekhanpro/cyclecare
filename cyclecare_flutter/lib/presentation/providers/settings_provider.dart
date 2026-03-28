import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';

// Settings state
class SettingsState {
  final Settings? settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  SettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  SettingsState copyWith({
    Settings? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsNotifier(this._settingsRepository) : super(SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _settingsRepository.getSettings();
      state = state.copyWith(
        settings: settings ?? const Settings(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateSettings(Settings settings) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _settingsRepository.updateSettings(settings);
      state = state.copyWith(settings: settings, isSaving: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSaving: false);
    }
  }

  Future<void> updateCycleSettings(int cycleLength, int periodLength) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _settingsRepository.updateCycleSettings(cycleLength, periodLength);
      await loadSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSaving: false);
    }
  }

  Future<void> updatePrivacySettings({
    required bool pinEnabled,
    required bool biometricEnabled,
    required bool privacyMode,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _settingsRepository.updatePrivacySettings(
        pinEnabled,
        biometricEnabled,
        privacyMode,
      );
      await loadSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSaving: false);
    }
  }

  Future<void> updateNotificationSettings({
    required bool enabled,
    required bool quietHours,
    required String start,
    required String end,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _settingsRepository.updateNotificationSettings(
        enabled,
        quietHours,
        start,
        end,
      );
      await loadSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSaving: false);
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await _settingsRepository.completeOnboarding();
      await loadSettings();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(settingsRepository);
});

// Stream provider for watching settings
final settingsStreamProvider = StreamProvider<Settings?>((ref) {
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return settingsRepository.watchSettings();
});
