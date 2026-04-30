import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/primary_button.dart';
import '../onboarding/onboarding_screen.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Icon(
                CupertinoIcons.heart_circle_fill,
                size: 96,
                color: CycleCareColors.rose.withOpacity(0.85),
              ),
              const SizedBox(height: 24),
              const Text(
                'CycleCare',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: CycleCareColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Privacy-first cycle tracking\nwith optional cloud sync',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: CycleCareColors.muted,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              authState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e', textAlign: TextAlign.center),
                data: (user) {
                  if (user != null) {
                    Future.microtask(() => _goToOnboarding(context, ref));
                    return const SizedBox.shrink();
                  }
                  return _buildButtons(context, ref);
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: 'Sign in with Google',
          icon: Icons.g_mobiledata,
          onPressed: () async {
            final authService = ref.read(authServiceProvider);
            await authService.signInWithGoogle();
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.phone_android),
          label: const Text('Continue without account'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: CycleCareColors.ink,
            side: const BorderSide(color: CycleCareColors.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _goToOnboarding(context, ref),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _showPrivacyInfo(context),
          child: const Text(
            'Privacy Info',
            style: TextStyle(color: CycleCareColors.muted, fontSize: 13),
          ),
        ),
      ],
    );
  }

  void _goToOnboarding(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy First'),
        content: const Text(
          'CycleCare stores all your data locally on your device by default.\n\n'
          'Signing in with Google enables optional cloud backup and partner sharing. '
          'Your health data is never shared with advertisers or analytics platforms.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
