import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../presentation/providers/app_providers.dart';
import '../auth/landing_screen.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import 'main_shell.dart';

class CycleCareApp extends ConsumerStatefulWidget {
  const CycleCareApp({super.key});

  @override
  ConsumerState<CycleCareApp> createState() => _CycleCareAppState();
}

class _CycleCareAppState extends ConsumerState<CycleCareApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final privacy = ref.read(privacyModeProvider);
    if (privacy) {
      if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      } else if (state == AppLifecycleState.resumed) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracker = ref.watch(cycleTrackerControllerProvider);
    final isDark = ref.watch(darkModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    ref.listen(authSyncProvider, (_, __) {}); // keep sync listener alive

    final lightTheme = CycleCareTheme.light.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(themeColor),
        brightness: Brightness.light,
      ),
    );
    final darkTheme = CycleCareTheme.dark.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(themeColor),
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'CycleCare',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return CupertinoTheme(
          data: CupertinoThemeData(
            primaryColor: Color(themeColor),
            scaffoldBackgroundColor: isDark ? Colors.black : CycleCareColors.cream,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: tracker.when(
        loading: () => const _LoadingApp(),
        error: (error, _) => _FatalAppError(error: error),
        data: (data) {
          if (!data.preferences.onboardingCompleted) {
            return const LandingScreen();
          }
          return const MainShell();
        },
      ),
    );
  }
}

class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CupertinoActivityIndicator()),
    );
  }
}

class _FatalAppError extends StatelessWidget {
  const _FatalAppError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Unable to start CycleCare: $error')),
    );
  }
}
