import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
import '../../features/splash/splash_screen.dart';
import '../providers/auth_providers.dart';
import '../../features/tracking/application/cycle_tracker_controller.dart';

part 'app_router.g.dart';

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
}

// ─── Shell nav index mapping ──────────────────────────────────────────────────
const _shellRoutes = [
  AppRoutes.home,
  AppRoutes.calendar,
  AppRoutes.log,
  AppRoutes.insights,
  AppRoutes.pet,
];

@riverpod
GoRouter appRouter(Ref ref) {
  final trackerAsync = ref.watch(cycleTrackerControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoading = trackerAsync.isLoading;
      if (isLoading) return AppRoutes.splash;

      final onboarded =
          trackerAsync.valueOrNull?.preferences.onboardingCompleted ?? false;
      final loc = state.matchedLocation;

      // Not onboarded → send to landing/onboarding
      if (!onboarded) {
        if (loc == AppRoutes.splash ||
            loc == AppRoutes.landing ||
            loc == AppRoutes.signIn ||
            loc == AppRoutes.onboarding) {
          return null; // allow
        }
        return AppRoutes.landing;
      }

      // Onboarded → skip auth/onboarding screens
      if (loc == AppRoutes.splash ||
          loc == AppRoutes.landing ||
          loc == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (_, __) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      // ── Main shell with bottom nav ────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.calendar,
                builder: (_, __) => const CalendarScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.log, builder: (_, __) => const LogScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.insights,
                builder: (_, __) => const InsightsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.pet, builder: (_, __) => const PetScreen()),
          ]),
        ],
      ),
      // ── Full-screen routes ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.aiChat,
        builder: (_, __) => const AIChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.birthControl,
        builder: (_, __) => const BirthControlScreen(),
      ),
      GoRoute(
        path: AppRoutes.pregnancy,
        builder: (_, __) => const PregnancyScreen(),
      ),
      GoRoute(
        path: AppRoutes.partner,
        builder: (_, __) => const PartnerScreen(),
      ),
      GoRoute(
        path: AppRoutes.health,
        builder: (_, __) => const HealthScreen(),
      ),
      GoRoute(
        path: AppRoutes.education,
        builder: (_, __) => const EducationScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
