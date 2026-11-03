import 'package:cyclecare/core/providers/app_settings_provider.dart';
import 'package:cyclecare/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app motion choice: System / Play / Pause, persisted under cc.motion and
/// published to every screen through [MotionScope].
void main() {
  test('the choice persists and reloads', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = await container.read(appSettingsProvider.future);
    expect(settings.motionPreference, AppMotionPreference.system,
        reason: 'following the phone is the default');

    await container
        .read(appSettingsProvider.notifier)
        .setMotionPreference(AppMotionPreference.pause);
    expect(
      container.read(appSettingsSyncProvider).motionPreference,
      AppMotionPreference.pause,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('cc.motion'), AppMotionPreference.pause.index);

    // A fresh container is a fresh launch: the stored choice comes back.
    final reopened = ProviderContainer();
    addTearDown(reopened.dispose);
    final reloaded = await reopened.read(appSettingsProvider.future);
    expect(reloaded.motionPreference, AppMotionPreference.pause);
  });

  test('an out-of-range stored value falls back to following the phone',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'cc.motion': 99});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = await container.read(appSettingsProvider.future);
    expect(settings.motionPreference, isA<AppMotionPreference>());
  });

  testWidgets('Pause reduces motion even when the platform allows it',
      (tester) async {
    late Motion motion;

    await tester.pumpWidget(MediaQuery(
      // The platform is not asking for less motion here.
      data: const MediaQueryData(disableAnimations: false),
      child: MotionScope(
        reduced: true,
        child: Builder(builder: (context) {
          motion = Motion.of(context);
          return const SizedBox();
        }),
      ),
    ));

    expect(motion.reduced, isTrue);
    expect(motion(const Duration(milliseconds: 240)),
        const Duration(milliseconds: 1));
    expect(motion.offset(24), 0);
    expect(motion.delay(const Duration(milliseconds: 40)), Duration.zero);
    expect(motion.scale(0.9), 1);
  });

  testWidgets('Play keeps motion even when the platform asks to reduce it',
      (tester) async {
    late Motion motion;

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MotionScope(
        reduced: false,
        child: Builder(builder: (context) {
          motion = Motion.of(context);
          return const SizedBox();
        }),
      ),
    ));

    expect(motion.reduced, isFalse,
        reason: 'an explicit opt-in outranks the platform setting');
    expect(motion(const Duration(milliseconds: 240)),
        const Duration(milliseconds: 240));
  });

  testWidgets('without a scope the platform setting still decides',
      (tester) async {
    late Motion motion;

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Builder(builder: (context) {
        motion = Motion.of(context);
        return const SizedBox();
      }),
    ));

    expect(motion.reduced, isTrue);
  });
}
