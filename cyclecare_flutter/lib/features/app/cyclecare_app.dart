import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../core/services/security_service.dart';
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
          return const _AppLockGate(child: MainShell());
        },
      ),
    );
  }
}

class _AppLockGate extends ConsumerStatefulWidget {
  const _AppLockGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<_AppLockGate> {
  bool _checking = true;
  bool _unlocked = false;
  String? _error;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkLock() async {
    final security = ref.read(securityServiceProvider);
    final enabled = await security.isLockEnabled;
    if (!mounted) return;
    if (!enabled) {
      setState(() {
        _checking = false;
        _unlocked = true;
      });
      return;
    }
    final type = await security.lockType;
    if (type == LockType.biometric) {
      final ok = await security.authenticateWithBiometric();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _unlocked = ok;
        _error = ok ? null : 'Authentication was cancelled.';
      });
      return;
    }
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }
    if (_unlocked) return widget.child;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.lock_shield_fill,
                    color: CycleCareColors.rose, size: 64),
                const SizedBox(height: 18),
                const Text(
                  'Unlock CycleCare',
                  style: TextStyle(
                    color: CycleCareColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your private health data is protected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CycleCareColors.muted),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    errorText: _error,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _verifyPin,
                    child: const Text('Unlock'),
                  ),
                ),
                TextButton(
                  onPressed: _checkLock,
                  child: const Text('Try biometric'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPin() async {
    final ok = await ref
        .read(securityServiceProvider)
        .verifyPin(_pinController.text.trim());
    if (!mounted) return;
    setState(() {
      _unlocked = ok;
      _error = ok ? null : 'Incorrect PIN';
    });
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
