import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/haptics.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App-wide presentation settings: palette, theme mode, privacy, haptics,
// week start, and which cycle overlays the calendar draws.
// ─────────────────────────────────────────────────────────────────────────────

/// Which day a calendar week begins on. Stored as [DateTime]'s weekday
/// numbering so it can be used in date math without translation.
enum WeekStart {
  monday(DateTime.monday, 'Monday'),
  saturday(DateTime.saturday, 'Saturday'),
  sunday(DateTime.sunday, 'Sunday');

  const WeekStart(this.weekday, this.label);

  final int weekday;
  final String label;
}

class AppSettings {
  const AppSettings({
    this.palette = AppPalette.pinkRose,
    this.themeMode = ThemeMode.system,
    this.privacyMode = false,
    this.hapticsEnabled = true,
    this.weekStart = WeekStart.monday,
    this.showFertileWindow = true,
    this.showOvulation = true,
  });

  final AppPalette palette;
  final ThemeMode themeMode;
  final bool privacyMode;
  final bool hapticsEnabled;
  final WeekStart weekStart;
  final bool showFertileWindow;
  final bool showOvulation;

  /// Retained so existing callers keep compiling. Prefer [themeMode] — it
  /// distinguishes "follow the system" from an explicit light choice, which
  /// a plain boolean cannot.
  bool get isDark => themeMode == ThemeMode.dark;

  AppSettings copyWith({
    AppPalette? palette,
    ThemeMode? themeMode,
    bool? privacyMode,
    bool? hapticsEnabled,
    WeekStart? weekStart,
    bool? showFertileWindow,
    bool? showOvulation,
  }) =>
      AppSettings(
        palette: palette ?? this.palette,
        themeMode: themeMode ?? this.themeMode,
        privacyMode: privacyMode ?? this.privacyMode,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        weekStart: weekStart ?? this.weekStart,
        showFertileWindow: showFertileWindow ?? this.showFertileWindow,
        showOvulation: showOvulation ?? this.showOvulation,
      );
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _paletteKey = 'cc.palette';
  static const _darkKey = 'cc.dark';
  static const _themeModeKey = 'cc.theme_mode';
  static const _privacyKey = 'cc.privacy';
  static const _hapticsKey = 'cc.haptics';
  static const _weekStartKey = 'cc.week_start';
  static const _showFertileKey = 'cc.show_fertile';
  static const _showOvulationKey = 'cc.show_ovulation';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(
      palette: AppPalette.values[
          (prefs.getInt(_paletteKey) ?? 0).clamp(0, AppPalette.values.length - 1)],
      themeMode: _readThemeMode(prefs),
      privacyMode: prefs.getBool(_privacyKey) ?? false,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
      weekStart: WeekStart.values[
          (prefs.getInt(_weekStartKey) ?? 0).clamp(0, WeekStart.values.length - 1)],
      showFertileWindow: prefs.getBool(_showFertileKey) ?? true,
      showOvulation: prefs.getBool(_showOvulationKey) ?? true,
    );
    Haptics.enabled = settings.hapticsEnabled;
    return settings;
  }

  /// Reads the tri-state theme mode, falling back to the legacy boolean so
  /// users who set dark mode in an earlier build keep it after upgrading.
  ThemeMode _readThemeMode(SharedPreferences prefs) {
    final stored = prefs.getInt(_themeModeKey);
    if (stored != null) {
      return ThemeMode.values[stored.clamp(0, ThemeMode.values.length - 1)];
    }
    final legacyDark = prefs.getBool(_darkKey);
    if (legacyDark == true) return ThemeMode.dark;
    if (legacyDark == false) return ThemeMode.light;
    return ThemeMode.system;
  }

  AppSettings get _current => state.valueOrNull ?? const AppSettings();

  Future<void> _persist(
    AppSettings next,
    Future<void> Function(SharedPreferences prefs) write,
  ) async {
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await write(prefs);
  }

  Future<void> setPalette(AppPalette palette) => _persist(
        _current.copyWith(palette: palette),
        (prefs) => prefs.setInt(_paletteKey, palette.index),
      );

  Future<void> setThemeMode(ThemeMode mode) => _persist(
        _current.copyWith(themeMode: mode),
        (prefs) => prefs.setInt(_themeModeKey, mode.index),
      );

  /// Kept for existing call sites that only expose a light/dark switch.
  Future<void> setDark(bool value) =>
      setThemeMode(value ? ThemeMode.dark : ThemeMode.light);

  Future<void> setPrivacy(bool value) => _persist(
        _current.copyWith(privacyMode: value),
        (prefs) => prefs.setBool(_privacyKey, value),
      );

  Future<void> setHaptics(bool value) {
    Haptics.enabled = value;
    return _persist(
      _current.copyWith(hapticsEnabled: value),
      (prefs) => prefs.setBool(_hapticsKey, value),
    );
  }

  Future<void> setWeekStart(WeekStart value) => _persist(
        _current.copyWith(weekStart: value),
        (prefs) => prefs.setInt(_weekStartKey, value.index),
      );

  Future<void> setShowFertileWindow(bool value) => _persist(
        _current.copyWith(showFertileWindow: value),
        (prefs) => prefs.setBool(_showFertileKey, value),
      );

  Future<void> setShowOvulation(bool value) => _persist(
        _current.copyWith(showOvulation: value),
        (prefs) => prefs.setBool(_showOvulationKey, value),
      );
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

// Convenience sync accessor — returns default while loading
extension AppSettingsX on AsyncValue<AppSettings> {
  AppSettings get settings => valueOrNull ?? const AppSettings();
}

// Sync provider that always returns a value (uses default while loading)
final appSettingsSyncProvider = Provider<AppSettings>((ref) {
  return ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
});
