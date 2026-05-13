import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/cyclecare_theme.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _isRegister = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If already signed in, go home
    ref.listen(authStateProvider, (_, next) {
      if (next.valueOrNull != null && mounted) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? 'Create account' : 'Sign in'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              _isRegister ? 'Create your account' : 'Welcome back',
              style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to sync your data across devices.',
              style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 32),

            // Email
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Email sign in/register button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submitEmail,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isRegister ? 'Create account' : 'Sign in'),
              ),
            ),
            const SizedBox(height: 12),

            // Google sign in
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                label: const Text('Continue with Google'),
              ),
            ),
            const SizedBox(height: 20),

            // Toggle register/login
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _isRegister = !_isRegister;
                  _error = null;
                }),
                child: Text(
                  _isRegister
                      ? 'Already have an account? Sign in'
                      : "Don't have an account? Create one",
                ),
              ),
            ),

            const Divider(height: 32),

            // Skip
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.onboarding),
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('Continue without account'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No account needed. Your data stays on your device.\nSign in only to sync across devices.',
                textAlign: TextAlign.center,
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final service = ref.read(authServiceProvider);
      if (_isRegister) {
        await service.registerWithEmail(email, pass);
      } else {
        await service.signInWithEmail(email, pass);
      }
      if (mounted) context.go(AppRoutes.home);
    } on AuthServiceException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Something went wrong. Please try again.'; _loading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) context.go(AppRoutes.home);
    } on AuthServiceException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Google sign-in failed. Please try again.'; _loading = false; });
    }
  }
}
