import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App-wide settings: palette, dark mode, privacy mode
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings {
  const AppSettings({
    this.palette = AppPalette.pinkRose,
    this.isDark = false,
    this.privacyMode = false,
  });

  final AppPalette palette;
  final bool isDark;
  final bool privacyMode;

  AppSettings copyWith({
    AppPalette? palette,
    bool? isDark,
    bool? privacyMode,
  }) =>
      AppSettings(
        palette: palette ?? this.palette,
        isDark: isDark ?? this.isDark,
        privacyMode: privacyMode ?? this.privacyMode,
      );
}

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _paletteKey = 'cc.palette';
  static const _darkKey = 'cc.dark';
  static const _privacyKey = 'cc.privacy';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteIndex = prefs.getInt(_paletteKey) ?? 0;
    final isDark = prefs.getBool(_darkKey) ?? false;
    final privacy = prefs.getBool(_privacyKey) ?? false;
    return AppSettings(
      palette: AppPalette
          .values[paletteIndex.clamp(0, AppPalette.values.length - 1)],
      isDark: isDark,
      privacyMode: privacy,
    );
  }

  Future<void> setPalette(AppPalette palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, palette.index);
    state = AsyncData(
        (state.valueOrNull ?? const AppSettings()).copyWith(palette: palette));
  }

  Future<void> setDark(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, value);
    state = AsyncData(
        (state.valueOrNull ?? const AppSettings()).copyWith(isDark: value));
  }

  Future<void> setPrivacy(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, value);
    state = AsyncData((state.valueOrNull ?? const AppSettings())
        .copyWith(privacyMode: value));
  }
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
