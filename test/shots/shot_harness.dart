// Shot harness for the redesign port.
//
// Renders real screens with the bundled fonts, real shadows and reduced
// motion at the redesign's 390pt review width, and writes PNGs to
// build/shots/ for comparison against the design reference pack in
// D:/tmp/design-ref (full-length renders and computed-style specs of every
// designed screen).
//
// Shot tests are skipped unless the run passes --dart-define=SHOTS=true, so
// they never slow down or flake the normal suite:
//
//   /d/tmp/cc-tools/flutterq.sh test --dart-define=SHOTS=true test/shots/home_shots_test.dart
//   py -3 -I /d/tmp/cc-tools/sbs.py D:/tmp/design-ref/home/home-light-full.png \
//       build/shots/home-light.png /d/tmp/cmp/home.png --top 0 --height 900
//
// A screenshot shows layout and styling. It is not evidence that a control
// stores data or that a flow works; behaviour needs ordinary widget tests.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyclecare/core/providers/app_settings_provider.dart';
import 'package:cyclecare/core/router/app_router.dart';
import 'package:cyclecare/core/theme/cyclecare_theme.dart';
import 'package:cyclecare/features/app/cyclecare_app.dart';
import 'package:cyclecare/features/pet/pet_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// True only when the run passed `--dart-define=SHOTS=true`.
const bool shotsEnabled = bool.fromEnvironment('SHOTS');

/// Where the design reference pack lives (outside the repository).
const String designRefRoot = 'D:/tmp/design-ref';

/// The design's review frame. A reference, not a fixed production layout.
const Size reviewSize = Size(390, 844);

/// The design's status bar is 45pt tall; content starts below it.
const double statusBarInset = 45;

const List<String> petArtAssets = [
  'assets/pets/luna-bunny.png',
  'assets/pets/miso-cat.png',
  'assets/pets/maple-bear.png',
  'assets/pets/pip-fox.png',
];

final GlobalKey _shotKey = GlobalKey(debugLabel: 'shot');
bool _fontsLoaded = false;

/// Declares a shot test. Loads the bundled fonts, turns real shadows on for
/// the duration of the body (the test binding replaces blurred shadows with
/// hard outlines by default) and tears the app down so no timer outlives it.
void testShot(String description, Future<void> Function(WidgetTester tester) body) {
  testWidgets(description, (tester) async {
    await tester.runAsync(loadShotFonts);
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
      debugDisableShadows = previousShadows;
    }
  }, skip: !shotsEnabled);
}

/// Loads every family in the app's FontManifest (DM Sans, Fraunces,
/// CycleCareIcons, MaterialIcons) so text is not drawn in the test font.
Future<void> loadShotFonts() async {
  if (_fontsLoaded) return;
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// Height in pt of the design's full-length render for [key], so a shot can
/// be laid out at the same height and compared row for row. Falls back to the
/// 844pt review frame when the reference is missing.
double designHeight(String key, {bool dark = false}) {
  final file = File('$designRefRoot/$key/$key-${dark ? 'dark' : 'light'}-full.png');
  if (!file.existsSync()) return reviewSize.height;
  final handle = file.openSync();
  try {
    final header = handle.readSync(24);
    final pixels = (header[20] << 24) | (header[21] << 16) | (header[22] << 8) | header[23];
    return pixels / 2;
  } finally {
    handle.closeSync();
  }
}

/// Seed data. Every value goes through the app's own models, so the stored
/// JSON cannot drift from what the repositories read back.
class ShotSeed {
  ShotSeed._();

  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Mirrors the design's fictional data: Ava, cycle day 23 of a 28-day
  /// cycle, six completed cycles, five-day periods, Luna the bunny at level 7.
  /// Dates move with the real clock; positions in the cycle do not.
  static Map<String, Object> typical({int cycleDay = 23}) {
    final t = today;
    final lastStart = t.subtract(Duration(days: cycleDay - 1));
    const lengths = [28, 27, 29, 28, 28, 28];
    final periods = <CycleEvent>[];
    var start = lastStart;
    for (var i = 0; i <= lengths.length; i++) {
      final inProgress = i == 0 && cycleDay <= 5;
      periods.add(CycleEvent(
        id: 'shot-period-$i',
        startDate: start,
        endDate: inProgress ? null : start.add(const Duration(days: 4)),
        flow: FlowIntensity.medium,
      ));
      if (i == lengths.length) break;
      start = start.subtract(Duration(days: lengths[i]));
    }

    const moods = ['Calm', 'Happy', 'Sensitive', 'Energetic', 'Calm', 'Focused'];
    const symptoms = [
      <String>['Cramps'],
      <String>[],
      <String>['Bloating'],
      <String>['Headache', 'Fatigue'],
      <String>[],
      <String>['Tender breasts'],
    ];
    final logs = <DailyLog>[
      DailyLog(date: t, flow: FlowIntensity.none, mood: 'Calm', symptoms: const ['Bloating']),
    ];
    for (var ago = 1; ago <= 60; ago++) {
      if (ago % 3 == 1 && ago > 6) continue;
      final date = t.subtract(Duration(days: ago));
      final day = date.difference(lastStart).inDays;
      final inPeriod = day >= 0 && day < 5;
      logs.add(DailyLog(
        date: date,
        flow: inPeriod ? (day < 2 ? FlowIntensity.heavy : FlowIntensity.light) : null,
        mood: moods[ago % moods.length],
        symptoms: symptoms[ago % symptoms.length],
        painLevel: inPeriod ? 4 : 0,
        temperatureCelsius: 36.3 + (ago % 7) * 0.05,
        sleepHours: 6.5 + (ago % 5) * 0.4,
        waterMl: 1200 + (ago % 4) * 300,
      ));
    }

    const preferences = CyclePreferences(
      averageCycleLength: 28,
      averagePeriodLength: 5,
      profileName: 'Ava',
      profileBirthYear: 1996,
      onboardingCompleted: true,
    );
    const pet = PetState(
      type: PetType.bunny,
      name: 'Luna',
      level: 7,
      xp: 320,
      happiness: 82,
      streak: 12,
      achievements: ['streak_7', 'level_5'],
    );
    return encode(periods: periods, logs: logs, preferences: preferences, pet: pet);
  }

  /// Onboarded, with no history at all: the empty and insufficient-history
  /// states.
  static Map<String, Object> empty() => encode(
        periods: const [],
        logs: const [],
        preferences: const CyclePreferences(profileName: 'Ava', onboardingCompleted: true),
      );

  /// Nothing stored and onboarding incomplete, so the router lands on the
  /// first-run screens instead of /home.
  static Map<String, Object> firstRun() => <String, Object>{};

  /// Period later than the estimate: last start 33 days ago on a steady
  /// 28-day history.
  static Map<String, Object> late() => typical(cycleDay: 34);

  static Map<String, Object> encode({
    required List<CycleEvent> periods,
    required List<DailyLog> logs,
    required CyclePreferences preferences,
    PetState? pet,
  }) =>
      <String, Object>{
        'cyclecare.periods.v1': jsonEncode([for (final p in periods) p.toJson()]),
        'cyclecare.daily_logs.v1': jsonEncode([for (final l in logs) l.toJson()]),
        'cyclecare.preferences.v1': jsonEncode(preferences.toJson()),
        if (pet != null) 'cc.pet.v1': jsonEncode(pet.toJson()),
        'cc.palette': 0,
      };
}

void _configureView(
  WidgetTester tester, {
  required bool dark,
  required double height,
  required double width,
  required double textScale,
  required bool reducedMotion,
}) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.padding = const FakeViewPadding(top: statusBarInset * 2);
  tester.view.viewPadding = const FakeViewPadding(top: statusBarInset * 2);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue =
      dark ? Brightness.dark : Brightness.light;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reducedMotion);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Map<String, Object> _withTheme(Map<String, Object> prefs, bool dark) =>
    <String, Object>{...prefs, 'cc.theme_mode': dark ? 2 : 1};

/// Pumps the whole app (router, shell, lock gate) and navigates to [route].
/// Use this for anything reachable by a route, so the bottom navigation and
/// the real providers are part of the shot.
Future<void> pumpShotApp(
  WidgetTester tester, {
  required String route,
  bool dark = false,
  Map<String, Object>? prefs,
  List<Override> overrides = const [],
  double? height,
  double width = 390,
  double textScale = 1,
  bool reducedMotion = true,
}) async {
  SharedPreferences.setMockInitialValues(_withTheme(prefs ?? ShotSeed.typical(), dark));
  _configureView(
    tester,
    dark: dark,
    height: height ?? reviewSize.height,
    width: width,
    textScale: textScale,
    reducedMotion: reducedMotion,
  );
  await tester.pumpWidget(RepaintBoundary(
    key: _shotKey,
    child: ProviderScope(overrides: overrides, child: const CycleCareApp()),
  ));
  await settleShot(tester);
  final container = ProviderScope.containerOf(tester.element(find.byType(CycleCareApp)));
  container.read(appRouterProvider).go(route);
  await settleShot(tester);
}

/// Pumps a single screen widget inside the real theme, for pushed sub-pages
/// that have no route of their own.
Future<void> pumpShotScreen(
  WidgetTester tester,
  Widget screen, {
  bool dark = false,
  Map<String, Object>? prefs,
  List<Override> overrides = const [],
  double? height,
  double width = 390,
  double textScale = 1,
  bool reducedMotion = true,
}) async {
  SharedPreferences.setMockInitialValues(_withTheme(prefs ?? ShotSeed.typical(), dark));
  _configureView(
    tester,
    dark: dark,
    height: height ?? reviewSize.height,
    width: width,
    textScale: textScale,
    reducedMotion: reducedMotion,
  );
  await tester.pumpWidget(RepaintBoundary(
    key: _shotKey,
    child: ProviderScope(
      overrides: overrides,
      child: Consumer(builder: (context, ref, _) {
        final settings = ref.watch(appSettingsSyncProvider);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(settings.palette.seed),
          darkTheme: AppTheme.dark(settings.palette.seed),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: screen,
        );
      }),
    ),
  ));
  await settleShot(tester);
}

/// Advances frames and lets real async work (asset loading, image decoding)
/// finish. Deliberately not pumpAndSettle: a breathing companion or a looping
/// indicator would never settle.
Future<void> settleShot(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.runAsync(() async {
    final apps = find.byType(MaterialApp).evaluate();
    final context = apps.isEmpty ? tester.binding.rootElement! : apps.first;
    for (final asset in petArtAssets) {
      await precacheImage(AssetImage(asset), context);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Writes the current frame to build/shots/[name].png at 2x and returns the
/// absolute path.
Future<String> captureShot(WidgetTester tester, String name) async {
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
  final out = File('build/shots/$name.png');
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  // ignore: avoid_print
  print('shot: ${out.absolute.path}');
  return out.absolute.path;
}
