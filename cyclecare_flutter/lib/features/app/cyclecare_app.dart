import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../onboarding/onboarding_screen.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import 'main_shell.dart';

class CycleCareApp extends ConsumerWidget {
  const CycleCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(cycleTrackerControllerProvider);
    return MaterialApp(
      title: 'CycleCare',
      debugShowCheckedModeBanner: false,
      theme: CycleCareTheme.light,
      darkTheme: CycleCareTheme.dark,
      builder: (context, child) {
        return CupertinoTheme(
          data: const CupertinoThemeData(
            primaryColor: CycleCareColors.rose,
            scaffoldBackgroundColor: CycleCareColors.cream,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: tracker.when(
        loading: () => const _LoadingApp(),
        error: (error, _) => _FatalAppError(error: error),
        data: (data) => data.preferences.onboardingCompleted
            ? const MainShell()
            : const OnboardingScreen(),
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
