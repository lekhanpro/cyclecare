import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../core/providers/app_settings_provider.dart';
import 'app_lock_screen.dart';

class CycleCareApp extends ConsumerWidget {
  const CycleCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsSyncProvider);

    return MaterialApp.router(
      title: 'CycleCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.palette.seed),
      darkTheme: AppTheme.dark(settings.palette.seed),
      themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        // Wrap with app lock
        return AppLockScreen(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
