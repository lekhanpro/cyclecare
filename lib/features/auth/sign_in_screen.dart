import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sign in
//
// Signing in is optional in this app, and the screen has to say so without
// looking like it is apologising for existing. Two decisions follow:
//
//  • The skip path is a real, visible button at the bottom — not a greyed-out
//    "maybe later" link. Anyone who lands here by accident should be one tap
//    from setup.
//  • Errors are split by who caused them. A field the user left empty or
//    mistyped is answered inline, under that field, because the fix is right
//    there and the message has to survive being re-read. A request that failed
//    on the far end — Firebase absent, network gone, credentials rejected — is
//    a toast, because it belongs to the submit, not to a field, and an error
//    box appearing between the inputs would push the button out from under the
//    finger about to retry it.
//
// Firebase is not guaranteed to be reachable (or even initialised) at runtime,
// so every action resolves its loading state in a `finally`. A button stuck
// spinning is worse than a failure the user can see.
//
// Copy accuracy note: this screen previously offered to "sync your entries
// between your own devices" and to "pick up your entries on another device".
// Neither is true — `FirebaseSyncService` is an empty stub, so signing in moves
// no data anywhere. The copy now frames an account as optional, and as
// groundwork for a backup feature that does not exist yet.
// ─────────────────────────────────────────────────────────────────────────────

/// Which request is in flight. A single nullable field rather than a bool per
/// button, so it is impossible to represent "both are loading".
enum _Busy { email, google }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  _Busy? _busy;
  bool _isRegister = false;
  bool _obscure = true;

  /// Deliberately permissive: enough to catch a missing `@` or a trailing
  /// comma, not enough to reject a legitimate address the server would accept.
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(value)) {
      return 'That does not look like an email address.';
    }
    return null;
  }

  String? _validatePassword(String? raw) {
    if ((raw ?? '').isEmpty) return 'Enter your password.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // If a session appears from anywhere (including a cached credential
    // resolving late), leave for home.
    ref.listen(authStateProvider, (_, next) {
      if (next.valueOrNull != null && mounted) {
        context.go(AppRoutes.home);
      }
    });

    final text = Theme.of(context).textTheme;
    final locked = _busy != null;

    // The app bar floats over the backdrop, so the content clears it manually.
    // Read from the theme rather than assuming Material's default height.
    final toolbarHeight =
        Theme.of(context).appBarTheme.toolbarHeight ?? kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(_isRegister ? 'Create account' : 'Sign in'),
      ),
      body: PhaseBackdrop(
        colors: AppColors.ovulationGradient,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  toolbarHeight + AppSpacing.md,
                  gutter,
                  AppSpacing.xxxl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Reveal(child: _Intro(isRegister: _isRegister)),
                        const SizedBox(height: AppSpacing.xl),
                        Reveal(index: 1, child: _credentialsCard(locked)),
                        const SizedBox(height: AppSpacing.xl),
                        Reveal(
                          index: 2,
                          child: _skipCard(text: text, locked: locked),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The form itself: two fields, one filled action, one alternative, and the
  /// mode switch. The only elevated surface on the screen.
  Widget _credentialsCard(bool locked) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Form(
        key: _formKey,
        // Errors appear once a field has been touched, then track every
        // keystroke, so the message clears the moment it stops being true.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailCtrl,
              enabled: !locked,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passCtrl,
              enabled: !locked,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: [
                _isRegister
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              validator: _validatePassword,
              onFieldSubmitted: locked ? null : (_) => _submitEmail(),
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: _isRegister ? 'At least 6 characters.' : null,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                // Icon-only control, so the label lives in the tooltip, which
                // is what assistive technology reads. The theme already gives
                // IconButton a 48dp minimum target.
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: AppSpacing.xl,
                    color: context.mutedColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _isRegister ? 'Create account' : 'Sign in',
              loading: _busy == _Busy.email,
              onPressed: locked ? null : _submitEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Continue with Google',
              outlined: true,
              loading: _busy == _Busy.google,
              onPressed: locked ? null : _signInWithGoogle,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: locked
                  ? null
                  : () {
                      Haptics.selection();
                      setState(() => _isRegister = !_isRegister);
                    },
              child: Text(
                _isRegister
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The skip path. Flat and hairline-bordered so it reads as an alternative
  /// rather than a competing offer.
  Widget _skipCard({required TextTheme text, required bool locked}) {
    final phases = PhaseColors.of(context);

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_rounded,
                size: AppSpacing.lg,
                color: phases.fertile.text,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'You do not need an account',
                  style: text.labelLarge?.copyWith(color: context.inkColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'CycleCare works completely offline. Everything you log stays on '
            'this device, and there is no cloud sync yet — so an account '
            'changes nothing about where your entries live.',
            style: text.bodySmall?.copyWith(color: context.mutedColor),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Continue without an account',
            icon: Icons.arrow_forward_rounded,
            outlined: true,
            onPressed: locked ? null : () => context.go(AppRoutes.onboarding),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEmail() async {
    // Field-level problems are answered inline and never reach the service.
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      Haptics.warn();
      return;
    }

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    setState(() => _busy = _Busy.email);
    try {
      final service = ref.read(authServiceProvider);
      if (_isRegister) {
        await service.registerWithEmail(email, pass);
      } else {
        await service.signInWithEmail(email, pass);
      }
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on AuthServiceException catch (e) {
      _fail(e.message);
    } catch (_) {
      // Anything not already translated by AuthService — most likely Firebase
      // being absent or unreachable on this build.
      _fail(
        _isRegister
            ? 'Could not create the account right now. You can continue '
                'without one.'
            : 'Sign-in is unavailable right now. You can continue without '
                'an account.',
      );
    } finally {
      // Always released, on every path. A button that never stops spinning
      // leaves the user with no move at all.
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = _Busy.google);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      // A null user is a cancelled picker, not a failure — say nothing.
      if (user != null) context.go(AppRoutes.home);
    } on AuthServiceException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Google sign-in is unavailable right now. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    showAppToast(context, message: message, kind: ToastKind.error);
  }
}

/// One dominant message, then the hedge underneath.
class _Intro extends StatelessWidget {
  const _Intro({required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            isRegister ? 'Create your account' : 'Welcome back',
            style: text.headlineSmall?.copyWith(
              letterSpacing: -0.4,
              color: context.inkColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isRegister
              ? 'An account is optional. It sets up a sign-in you can use for '
                  'backup later — for now, everything you log stays on this '
                  'device.'
              : 'Signing in is optional. Your entries stay on this device '
                  'either way, and nothing is shared with anyone else.',
          style: text.bodyMedium?.copyWith(color: context.mutedColor),
        ),
      ],
    );
  }
}
