// Screenshot entrypoint. Never shipped — `flutter build web -t lib/main_shots.dart`.
//
// Seeds a demo history through the app's own CycleRepository before runApp, so
// every screen renders from the same store the running app reads back. Writing
// the JSON by hand would drift from the models the moment a field is added.
//
// Usage (see tool/README.md):
//   flutter build web --release -t lib/main_shots.dart \
//     --dart-define=SHOT_THEME=light --output build/web-light

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/app/cyclecare_app.dart';
import 'features/tracking/data/cycle_repository.dart';
import 'features/tracking/domain/cycle_models.dart';

const _theme = String.fromEnvironment('SHOT_THEME', defaultValue: 'light');

/// Which part of the app to make reachable.
///
/// `app` seeds a demo history and marks onboarding complete, so the router
/// lands on /home and every main route can be deep-linked.
///
/// `firstrun` seeds nothing and leaves onboarding incomplete. Without it the
/// first-run screens cannot be captured at all: the router redirects an
/// onboarded user away from /landing, /sign-in and /onboarding, so those three
/// routes would silently screenshot as /home.
const _stage = String.fromEnvironment('SHOT_STAGE', defaultValue: 'app');

/// Anchored to a fixed cycle position rather than "today" so the hero reads the
/// same on every run: day 3 of 28 puts the app in the menstrual phase with the
/// ring arc visibly started and a period still in progress.
const _cycleDay = 3;
const _cycleLength = 28;
const _periodLength = 5;

/// Seven complete cycles of history. Enough for the insights charts to have a
/// trend line and for the predictor to report "High" confidence, with a ±1 day
/// jitter so the regularity read is "Steady" rather than suspiciously perfect.
const _recentCycleLengths = <int>[28, 27, 29, 27, 29, 28, 27];

const _moods = <String>['Happy', 'Calm', 'Tired', 'Low', 'Energetic'];
const _symptomPool = <List<String>>[
  ['Cramps', 'Fatigue'],
  ['Headache'],
  ['Bloating', 'Tender breasts'],
  ['Cramps'],
  [],
];

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  // Theme is persisted by the app itself, so the capture script's
  // `color_scheme` alone would not flip it. Written for both stages.
  await prefs.setInt('cc.theme_mode', _theme == 'dark' ? 2 : 1);
  await prefs.setInt('cc.palette', 0);

  if (_stage == 'firstrun') {
    // Nothing seeded and onboarding left incomplete, so the router sends the
    // app to /landing and the first-run routes stay reachable.
    runApp(const ProviderScope(child: CycleCareApp()));
    return;
  }

  final repository = CycleRepository(prefs);
  final today = _dateOnly(DateTime.now());

  // Current period started _cycleDay - 1 days ago, so today *is* cycle day
  // _cycleDay. Walking backwards through _recentCycleLengths then lays the
  // history out behind it at realistic, slightly uneven intervals.
  var start = today.subtract(const Duration(days: _cycleDay - 1));
  final periods = <CycleEvent>[];

  for (var index = 0; index <= _recentCycleLengths.length; index++) {
    // The in-progress period has no end date — that is what the app uses to
    // tell "bleeding now" from "a closed past period".
    periods.add(
      CycleEvent(
        id: 'shot-period-$index',
        startDate: start,
        endDate: index == 0
            ? null
            : start.add(const Duration(days: _periodLength - 1)),
        flow: FlowIntensity.medium,
        symptoms: index.isEven ? const ['Cramps'] : const [],
      ),
    );

    if (index == _recentCycleLengths.length) break;
    start = start.subtract(Duration(days: _recentCycleLengths[index]));
  }

  // Daily logs for the last 30 days, dense enough to drive the logging streak,
  // the 87%-of-30-days coverage figure and the symptom charts. Two gaps keep it
  // honest — a 100% streak is not what a real history looks like.
  final logs = <DailyLog>[];
  for (var ago = 0; ago < 30; ago++) {
    if (ago == 11 || ago == 19) continue;

    final date = today.subtract(Duration(days: ago));
    final inPeriod = ago < _cycleDay;

    logs.add(
      DailyLog(
        date: date,
        flow: inPeriod
            ? (ago == 0 ? FlowIntensity.medium : FlowIntensity.heavy)
            : null,
        mood: _moods[ago % _moods.length],
        symptoms: _symptomPool[ago % _symptomPool.length],
        // Null, not 0: these demo days have no pain rating recorded.
        painLevel: inPeriod ? 3 : (ago % 4 == 0 ? 1 : null),
        temperatureCelsius: 36.4 + ((ago % 7) * 0.06),
        sleepHours: 6.5 + ((ago % 5) * 0.4),
        waterMl: 1200 + ((ago % 4) * 400),
        notes: ago == 0 ? 'Resting today, cramps easing off.' : '',
      ),
    );
  }

  await repository.savePeriods(periods);
  await repository.saveLogs(logs);
  await repository.savePreferences(
    const CyclePreferences(
      averageCycleLength: _cycleLength,
      averagePeriodLength: _periodLength,
      profileName: 'Ava',
      profileBirthYear: 1998,
      goal: TrackingGoal.trackPeriods,
      // Skips landing/onboarding so the router lands directly on /home and the
      // capture script can deep-link every route.
      onboardingCompleted: true,
    ),
  );

  runApp(const ProviderScope(child: CycleCareApp()));
}
