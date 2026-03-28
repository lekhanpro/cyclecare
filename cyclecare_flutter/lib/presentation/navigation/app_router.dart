import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/pregnancy/pregnancy_dashboard_screen.dart';
import '../screens/pregnancy/kick_counter_screen.dart';
import '../screens/pregnancy/contraction_timer_screen.dart';
import '../screens/pregnancy/appointments_screen.dart';
import '../screens/health/health_conditions_screen.dart';
import '../screens/health/pain_mapping_screen.dart';
import '../screens/partner/partner_sharing_screen.dart';
import '../screens/birth_control/birth_control_screen.dart';
import '../screens/education/education_screen.dart';
import '../screens/settings/backup_screen.dart';
import '../screens/settings/account_screen.dart';
import '../screens/settings/theme_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String pregnancyDashboard = '/pregnancy';
  static const String kickCounter = '/pregnancy/kick-counter';
  static const String contractionTimer = '/pregnancy/contraction-timer';
  static const String appointments = '/pregnancy/appointments';
  static const String healthConditions = '/health/conditions';
  static const String painMapping = '/health/pain-mapping';
  static const String partnerSharing = '/partner';
  static const String birthControl = '/birth-control';
  static const String education = '/education';
  static const String backup = '/settings/backup';
  static const String account = '/settings/account';
  static const String themeSettings = '/settings/theme';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case pregnancyDashboard:
        return MaterialPageRoute(builder: (_) => const PregnancyDashboardScreen());
      case kickCounter:
        return MaterialPageRoute(builder: (_) => const KickCounterScreen());
      case contractionTimer:
        return MaterialPageRoute(builder: (_) => const ContractionTimerScreen());
      case appointments:
        return MaterialPageRoute(builder: (_) => const AppointmentsScreen());
      case healthConditions:
        return MaterialPageRoute(builder: (_) => const HealthConditionsScreen());
      case painMapping:
        return MaterialPageRoute(builder: (_) => const PainMappingScreen());
      case partnerSharing:
        return MaterialPageRoute(builder: (_) => const PartnerSharingScreen());
      case birthControl:
        return MaterialPageRoute(builder: (_) => const BirthControlScreen());
      case education:
        return MaterialPageRoute(builder: (_) => const EducationScreen());
      case backup:
        return MaterialPageRoute(builder: (_) => const BackupScreen());
      case account:
        return MaterialPageRoute(builder: (_) => const AccountScreen());
      case themeSettings:
        return MaterialPageRoute(builder: (_) => const ThemeSettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
