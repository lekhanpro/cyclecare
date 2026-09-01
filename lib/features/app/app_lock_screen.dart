import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/security_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App lock gate
//
// This widget sits between the router and everything the user came for, so it
// is held to two rules that outrank its looks:
//
//  • It never claims a capability it does not have. The old screen offered
//    "Use biometric" unconditionally — on a device with nothing enrolled, or
//    on a PIN-only lock, that button could not succeed, and a dead affordance
//    on a lock screen reads as a broken app rather than a wrong button. The
//    biometric action now appears only when the lock is actually a biometric
//    lock *and* the platform reports a usable sensor. Everywhere else the PIN
//    is presented plainly, as the only way in.
//  • It re-locks when the app leaves the foreground. Previously the lifecycle
//    hook was an empty comment, so the lock only ever ran once at startup:
//    unlock in the morning, and the app stayed open to anyone holding the
//    phone for the rest of the day. Backgrounding now returns the gate to its
//    locked state and re-reads the lock on resume.
//
// Everything visual is deliberately quiet. There is no imitation fingerprint
// artwork here: biometrics are the platform's prompt, shown by the platform,
// because a drawn sensor that is not the real one teaches the wrong gesture.
// ─────────────────────────────────────────────────────────────────────────────

final _securityServiceProvider =
    Provider<SecurityService>((_) => SecurityService());

/// Where the gate is: still asking the platform, holding the user out, or done.
enum _Gate { checking, locked, open }

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  /// A touch target plus a ring of breathing room around it.
  static const double _badgeSize = AppLayout.minTouchTarget + AppSpacing.xxl;

  final TextEditingController _pinController = TextEditingController();

  _Gate _gate = _Gate.checking;
  bool _lockEnabled = false;
  LockType _lockType = LockType.none;
  bool _biometricUsable = false;

  /// True while the platform biometric sheet owns the window. Android reports
  /// that as a lifecycle change, and treating it as "the app was backgrounded"
  /// would re-lock the gate underneath its own prompt.
  bool _promptInFlight = false;

  bool _verifying = false;

  /// Set when the gate locked itself because the app went away, so resume can
  /// tell a fresh background return from a user who simply never unlocked.
  bool _relockPending = false;

  /// Inline error for the PIN field only.
  String? _pinError;

  /// Everything else worth saying — a refused fingerprint, a sensor that
  /// stopped working. Kept apart from [_pinError] so a biometric failure is
  /// never printed under the PIN box as if the PIN were wrong.
  String? _notice;

  bool get _biometricPath =>
      _lockType == LockType.biometric && _biometricUsable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    super.dispose();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The biometric sheet is a foreground event wearing a background costume.
    if (_promptInFlight) return;

    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _lockForBackground();
      case AppLifecycleState.resumed:
        _handleResume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // `inactive` also fires for a pulled-down notification shade and for
        // permission dialogs. Locking there would punish the user for events
        // that never left the app.
        break;
    }
  }

  /// Returns the gate to its locked state as the app leaves the foreground.
  ///
  /// The cached [_lockEnabled] is the fast path, and it matters: it is read
  /// synchronously, so a lock that is already on is applied in the same frame
  /// the app is told it is going away. The await below only runs when the flag
  /// says the lock was off, which happens when it was switched on from
  /// Settings after the last gate check.
  Future<void> _lockForBackground() async {
    if (_gate != _Gate.open) return;

    if (!_lockEnabled) {
      final enabled = await ref.read(_securityServiceProvider).isLockEnabled;
      if (!mounted) return;
      _lockEnabled = enabled;
      if (!enabled) return;
    }

    if (_gate != _Gate.open) return;

    _relockPending = true;
    _pinController.clear();
    setState(() {
      _gate = _Gate.locked;
      _pinError = null;
      _notice = null;
    });
  }

  void _handleResume() {
    if (!_relockPending) return;
    _relockPending = false;
    // Re-read rather than trust the cache: the lock type or the sensor's
    // availability can both have changed while the app was away.
    _checkLock();
  }

  // ── Gate ──────────────────────────────────────────────────────────────────

  Future<void> _checkLock() async {
    final security = ref.read(_securityServiceProvider);

    final enabled = await security.isLockEnabled;
    final type = enabled ? await security.lockType : LockType.none;

    // Only asked when it could matter, and never allowed to throw: a device
    // with no sensor reports the absence as an exception on some platforms,
    // and that must not become an unopenable app.
    var usable = false;
    if (type == LockType.biometric) {
      try {
        usable = await security.canUseBiometric;
      } catch (_) {
        usable = false;
      }
    }

    if (!mounted) return;

    _lockEnabled = enabled;
    _lockType = type;
    _biometricUsable = usable;

    if (!enabled) {
      setState(() => _gate = _Gate.open);
      return;
    }

    setState(() {
      _gate = _Gate.locked;
      _notice = type == LockType.biometric && !usable
          ? 'Biometric unlock is not available on this device right now. '
              'Enter your PIN instead.'
          : null;
    });

    if (type == LockType.biometric && usable) {
      await _authenticate(announceFailure: false);
    }
  }

  /// Hands off to the platform prompt. There is no in-app imitation of it.
  Future<void> _authenticate({bool announceFailure = true}) async {
    if (_promptInFlight || !_biometricPath) return;

    setState(() {
      _promptInFlight = true;
      _pinError = null;
      _notice = null;
    });

    var authenticated = false;
    try {
      authenticated =
          await ref.read(_securityServiceProvider).authenticateWithBiometric();
    } catch (_) {
      authenticated = false;
    }

    if (!mounted) return;

    if (authenticated) {
      _pinController.clear();
      setState(() {
        _promptInFlight = false;
        _gate = _Gate.open;
        _pinError = null;
        _notice = null;
      });
      return;
    }

    setState(() {
      _promptInFlight = false;
      // A cancelled prompt is not a failure worth shouting about on first
      // launch — the PIN field is right there either way.
      _notice = announceFailure
          ? 'That was not recognised. Try again, or enter your PIN.'
          : null;
    });
  }

  Future<void> _verifyPin() async {
    if (_verifying) return;

    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _pinError = 'Enter your PIN to continue');
      return;
    }

    setState(() {
      _verifying = true;
      _pinError = null;
      _notice = null;
    });

    var unlocked = false;
    try {
      unlocked = await ref.read(_securityServiceProvider).verifyPin(pin);
    } catch (_) {
      // Fail closed. An unreadable keystore is not a reason to open the app.
      unlocked = false;
    }

    if (!mounted) return;

    _pinController.clear();
    setState(() {
      _verifying = false;
      if (unlocked) {
        _gate = _Gate.open;
        _pinError = null;
      } else {
        _pinError = 'That PIN is not right. Try again.';
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (_gate) {
      _Gate.open => widget.child,
      _Gate.checking => const _CheckingSurface(),
      _Gate.locked => _lockSurface(context),
    };
  }

  Widget _lockSurface(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.canvasColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = AppLayout.pageGutterFor(constraints.maxWidth);
            // Fills the viewport so the panel sits centred, without forcing a
            // scroll that has nothing below it.
            final room = constraints.maxHeight - AppSpacing.xxl * 2;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: gutter,
                vertical: AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: room.isFinite && room > 0 ? room : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.maxContentWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Reveal(
                          offsetY: AppSpacing.md,
                          child: Column(
                            children: [
                              Container(
                                width: _badgeSize,
                                height: _badgeSize,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.accentColor.withOpacity(
                                    context.isDark ? 0.22 : 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_rounded,
                                  size: AppSpacing.xxxl,
                                  color: context.accentColor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Semantics(
                                header: true,
                                child: Text(
                                  'Unlock CycleCare',
                                  textAlign: TextAlign.center,
                                  style: text.headlineSmall?.copyWith(
                                    color: context.inkColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _biometricPath
                                    ? 'Confirm it is you to open your logs.'
                                    : 'Enter your PIN to open your logs.',
                                textAlign: TextAlign.center,
                                style: text.bodyMedium?.copyWith(
                                  color: context.mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_notice != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Reveal(
                            index: 1,
                            offsetY: AppSpacing.md,
                            child: Semantics(
                              container: true,
                              liveRegion: true,
                              child: InfoBanner(
                                icon: Icons.info_rounded,
                                tone: AppColors.warning,
                                message: _notice!,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        Reveal(
                          index: 2,
                          offsetY: AppSpacing.md,
                          child: TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLength: 6,
                            autofocus: !_biometricPath,
                            // Read-only rather than disabled while the PIN is
                            // being checked: disabling drops focus and the
                            // keyboard slides away and back for a keystore
                            // read that takes milliseconds.
                            readOnly: _verifying,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'PIN',
                              hintText: '4–6 digits',
                              helperText: 'The PIN you set in CycleCare',
                              errorText: _pinError,
                              counterText: '',
                              prefixIcon: const Icon(Icons.pin_rounded),
                            ),
                            onSubmitted: (_) => _verifyPin(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Reveal(
                          index: 3,
                          offsetY: AppSpacing.md,
                          child: PrimaryButton(
                            label: 'Unlock',
                            icon: Icons.lock_open_rounded,
                            loading: _verifying,
                            onPressed: _verifyPin,
                          ),
                        ),
                        // Shown only when the lock really is a biometric lock
                        // and the platform reports a usable sensor. Otherwise
                        // there is nothing here to tempt a tap that cannot
                        // work.
                        if (_biometricPath) ...[
                          const SizedBox(height: AppSpacing.md),
                          Reveal(
                            index: 4,
                            offsetY: AppSpacing.md,
                            child: PrimaryButton(
                              label: 'Use biometric unlock',
                              icon: Icons.fingerprint_rounded,
                              outlined: true,
                              loading: _promptInFlight,
                              onPressed: _verifying ? null : _authenticate,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Forgotten your PIN? It is hashed on this device and '
                          'cannot be recovered or reset from here.',
                          textAlign: TextAlign.center,
                          style: text.bodySmall?.copyWith(
                            color: context.subtleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The moment before the gate knows whether it is needed.
///
/// Named rather than a bare spinner: this surface can be the first thing shown
/// on a cold start, and an unlabelled indicator on an empty screen is
/// indistinguishable from a hang.
class _CheckingSurface extends StatelessWidget {
  const _CheckingSurface();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.canvasColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: AppSpacing.xxl,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    semanticsLabel: 'Checking your app lock',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Checking your app lock',
                  textAlign: TextAlign.center,
                  style: text.labelLarge?.copyWith(color: context.mutedColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
