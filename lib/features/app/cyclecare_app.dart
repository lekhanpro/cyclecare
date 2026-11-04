import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_settings_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import 'app_lock_screen.dart';
import '../reminders/application/reminders_controller.dart';
import '../tour/feature_tour.dart';
import '../partner/application/partner_live_controller.dart';

class CycleCareApp extends ConsumerWidget {
  const CycleCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(remindersControllerProvider);
    final router = ref.watch(appRouterProvider);
    final settingsState = ref.watch(appSettingsProvider);
    final settings = settingsState.settings;
    final trackerState = ref.watch(cycleTrackerControllerProvider);
    final startupReady =
        settingsState.valueOrNull != null && trackerState.valueOrNull != null;

    return MaterialApp.router(
      title: 'CycleCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.palette.seed),
      darkTheme: AppTheme.dark(settings.palette.seed),
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.maybeOf(context);
        final platformReduced = media?.disableAnimations ?? true;
        final reduced =
            !startupReady ||
            switch (settings.motionPreference) {
              AppMotionPreference.system => platformReduced,
              AppMotionPreference.play => false,
              AppMotionPreference.pause => true,
            };

        Widget app = MotionScope(
          reduced: reduced,
          child: AppLockScreen(child: PartnerSyncBoundary(child: FeatureTourHost(
            router: router, child: child ?? const SizedBox.shrink()))),
        );
        if (media != null && media.disableAnimations != reduced) {
          app = MediaQuery(
            data: media.copyWith(disableAnimations: reduced),
            child: app,
          );
        }
        // One horizontal viewport contract for every route, including pushed
        // settings/readers and dialogs. SafeArea removes the consumed insets
        // from descendants, so page gutters cannot count a cutout twice.
        return SafeArea(
          top: false,
          bottom: false,
          child: SizedBox.expand(
            key: const ValueKey('app-safe-viewport'),
            child: app,
          ),
        );
      },
    );
  }
}
