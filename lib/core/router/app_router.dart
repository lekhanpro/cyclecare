import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/app/main_shell.dart';
import '../../features/auth/landing_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/tracking/presentation/home_screen.dart';
import '../../features/tracking/presentation/calendar_screen.dart';
import '../../features/tracking/presentation/log_screen.dart';
import '../../features/tracking/presentation/insights_screen.dart';
import '../../features/pet/pet_screen.dart';
import '../../features/ai/ai_chat_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/birth_control/birth_control_screen.dart';
import '../../features/pregnancy/pregnancy_screen.dart';
import '../../features/partner/partner_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/education/education_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tracking/application/cycle_tracker_controller.dart';
import 'app_transitions.dart';

// ─── Route names ─────────────────────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const landing = '/landing';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const calendar = '/calendar';
  static const log = '/log';
  static const insights = '/insights';
  static const pet = '/pet';
  static const aiChat = '/ai-chat';
  static const settings = '/settings';
  static const birthControl = '/birth-control';
  static const pregnancy = '/pregnancy';
  static const partner = '/partner';
  static const health = '/health';
  static const education = '/education';
  static const reminders = '/reminders';
}

// ─── Router notifier — drives GoRouter refresh ────────────────────────────────
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<CycleTrackerState>>(
      cycleTrackerControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  bool get _isLoading =>
      _ref.read(cycleTrackerControllerProvider).isLoading;

  bool get _onboarded =>
      _ref.read(cycleTrackerControllerProvider).valueOrNull
          ?.preferences.onboardingCompleted ??
      false;

  String? redirect(BuildContext context, GoRouterState state) {
    if (_isLoading) return AppRoutes.splash;

    final loc = state.matchedLocation;

    if (!_onboarded) {
      // Note: splash is deliberately NOT allowed here. Once loading finishes,
      // an un-onboarded user sitting on splash must be moved to landing —
      // returning null would leave them on the spinner indefinitely.
      if (loc == AppRoutes.landing ||
          loc == AppRoutes.signIn ||
          loc == AppRoutes.onboarding) {
        return null;
      }
      return AppRoutes.landing;
    }

    if (loc == AppRoutes.splash ||
        loc == AppRoutes.landing ||
        loc == AppRoutes.onboarding) {
      return AppRoutes.home;
    }

    return null;
  }
}

// ─── Router provider ─────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      // Root-level screens fade rather than slide: there is no spatial
      // "back" relationship between landing, sign-in and onboarding.
      GoRoute(
        path: AppRoutes.landing,
        pageBuilder: (_, __) => fadePage(child: const LandingScreen()),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        pageBuilder: (_, __) => pushPage(child: const SignInScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, __) => fadePage(child: const OnboardingScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.calendar,
                builder: (_, __) => const CalendarScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.log,
                builder: (_, __) => const LogScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.insights,
                builder: (_, __) => const InsightsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.pet,
                builder: (_, __) => const PetScreen()),
          ]),
        ],
      ),
      // Chat interrupts the current task, so it rises like a sheet.
      GoRoute(
        path: AppRoutes.aiChat,
        pageBuilder: (_, __) => modalPage(child: const AIChatScreen()),
      ),
      // Everything below is a drill-down from Home or Settings and uses the
      // iOS-style push so the back gesture matches the way it arrived.
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (_, __) => pushPage(child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.birthControl,
        pageBuilder: (_, __) => pushPage(child: const BirthControlScreen()),
      ),
      GoRoute(
        path: AppRoutes.pregnancy,
        pageBuilder: (_, __) => pushPage(child: const PregnancyScreen()),
      ),
      GoRoute(
        path: AppRoutes.partner,
        pageBuilder: (_, __) => pushPage(child: const PartnerScreen()),
      ),
      GoRoute(
        path: AppRoutes.health,
        pageBuilder: (_, __) => pushPage(child: const HealthScreen()),
      ),
      GoRoute(
        path: AppRoutes.education,
        pageBuilder: (_, __) => pushPage(child: const EducationScreen()),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        pageBuilder: (_, __) => pushPage(child: const RemindersScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
