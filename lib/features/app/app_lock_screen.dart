import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/security_service.dart';
import '../../core/theme/cyclecare_theme.dart';

final _securityServiceProvider = Provider<SecurityService>((_) => SecurityService());

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _unlocked = false;
  String? _error;
  final _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when app goes to background (privacy mode)
    if (state == AppLifecycleState.paused) {
      // Could re-lock here if privacy mode is on
    }
  }

  Future<void> _checkLock() async {
    final security = ref.read(_securityServiceProvider);
    final enabled = await security.isLockEnabled;
    if (!mounted) return;
    if (!enabled) {
      setState(() { _checking = false; _unlocked = true; });
      return;
    }
    final type = await security.lockType;
    if (type == LockType.biometric) {
      final ok = await security.authenticateWithBiometric();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _unlocked = ok;
        _error = ok ? null : 'Biometric authentication failed.';
      });
      return;
    }
    setState(() => _checking = false);
  }

  Future<void> _verifyPin() async {
    final ok = await ref
        .read(_securityServiceProvider)
        .verifyPin(_pinCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _unlocked = ok;
      _error = ok ? null : 'Incorrect PIN. Try again.';
    });
    if (!ok) _pinCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_unlocked) return widget.child;

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: scheme.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Unlock CycleCare',
                  style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your health data is protected.',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    errorText: _error,
                    counterText: '',
                    prefixIcon: const Icon(Icons.pin_outlined),
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _verifyPin,
                    child: const Text('Unlock'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _checkLock,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Use biometric'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
