import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Landing
//
// The first screen a new user ever sees, and the only place the app gets to
// answer "why should I trust you with this?" before asking for anything.
//
// So the hierarchy is deliberately inverted from a normal marketing page: the
// privacy promise sits above the feature list, because for a period tracker
// that is the feature. Three benefit rows, not five — a list long enough to
// scan is more persuasive than a list long enough to read.
//
// Everything sits on a single glass panel over a phase gradient. Glass needs
// something colourful behind it to read at all, which is what `PhaseBackdrop`
// is for, and it is the only elevated surface here so the eye lands on the
// promise before it reaches the buttons.
//
// Copy accuracy note: this screen used to say signing in "adds sync across
// devices". It does not. `FirebaseSyncService` is still a stub, so nothing a
// user logs leaves the device whether they sign in or not. The account is
// described as optional, and the local-first promise is stated without
// qualification because it is currently unconditional.
// ─────────────────────────────────────────────────────────────────────────────

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final phases = PhaseColors.of(context);

    return Scaffold(
      body: PhaseBackdrop(
        colors: AppColors.menstrualGradient,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = AppLayout.pageGutterFor(constraints.maxWidth);
              const verticalPadding = AppSpacing.xl + AppSpacing.xxl;

              // Centres on a tall phone, scrolls on a short one, rather than
              // squashing the panel or clipping the buttons.
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.xl,
                  gutter,
                  AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Clamped: a viewport shorter than the padding would
                    // otherwise produce a negative minimum and assert.
                    minHeight: (constraints.maxHeight - verticalPadding).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppLayout.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Reveal(child: Center(child: _BrandMark())),
                          const SizedBox(height: AppSpacing.xl),
                          Reveal(
                            index: 1,
                            child: Semantics(
                              header: true,
                              child: Text(
                                'CycleCare',
                                textAlign: TextAlign.center,
                                style: text.headlineMedium?.copyWith(
                                  letterSpacing: -0.5,
                                  color: context.inkColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Reveal(
                            index: 2,
                            child: Text(
                              'Understand your cycle without handing it over '
                              'to anyone.',
                              textAlign: TextAlign.center,
                              style: text.bodyLarge?.copyWith(
                                color: context.mutedColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Reveal(
                            index: 3,
                            child: GlassCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              borderRadius: BorderRadius.circular(
                                AppRadii.card,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Benefit(
                                    icon: Icons.lock_rounded,
                                    tone: phases.fertile.text,
                                    title: 'Private by default',
                                    body: 'Everything you log is saved on this '
                                        'device. No account, no upload, no '
                                        'sharing.',
                                  ),
                                  _BenefitDivider(color: context.lineColor),
                                  _Benefit(
                                    icon: Icons.insights_rounded,
                                    tone: phases.ovulation.text,
                                    title: 'Estimates that learn you',
                                    body: 'Forecasts adjust to your own '
                                        'pattern instead of a textbook '
                                        '28 days.',
                                  ),
                                  _BenefitDivider(color: context.lineColor),
                                  _Benefit(
                                    icon: Icons.spa_rounded,
                                    tone: phases.period.text,
                                    title: 'Gentle, useful insights',
                                    body: 'Plain-language notes on what your '
                                        'body is doing. Never clinical, never '
                                        'pushy.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Reveal(
                            index: 4,
                            child: PrimaryButton(
                              label: 'Get started',
                              icon: Icons.arrow_forward_rounded,
                              // `go` rather than `push`: setup replaces the
                              // landing page, it doesn't stack on top of it.
                              onPressed: () => context.go(AppRoutes.onboarding),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Reveal(
                            index: 5,
                            child: PrimaryButton(
                              label: 'Sign in',
                              outlined: true,
                              onPressed: () => context.push(AppRoutes.signIn),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const Reveal(index: 6, child: _AccountFootnote()),
                        ],
                      ),
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
}

/// The app mark. Decorative: the wordmark below it already names the app, so
/// announcing this as well would read the brand twice.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    // The phase swatch rather than the raw gradient constant, so the mark is
    // tuned per brightness instead of only for cream.
    final swatch = PhaseColors.of(context).period;

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: swatch.gradient,
          ),
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          boxShadow: [
            BoxShadow(
              color: swatch.fill.withOpacity(context.isDark ? 0.36 : 0.28),
              blurRadius: AppSpacing.xxl,
              offset: const Offset(0, AppSpacing.sm),
            ),
          ],
        ),
        child: Icon(
          Icons.favorite_rounded,
          size: AppSpacing.xxxl,
          color: swatch.onFill,
        ),
      ),
    );
  }
}

/// One benefit row: icon tile, heading, one sentence of support.
///
/// The tile is sized by padding rather than a fixed square so it keeps its
/// proportions against the text beside it, and the icon carries no semantic
/// label because the heading immediately to its right says the same thing.
class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: tone.withOpacity(context.isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(AppRadii.compact),
          ),
          child: Icon(icon, size: AppSpacing.xl, color: tone),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.labelLarge?.copyWith(color: context.inkColor),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                body,
                style: text.bodySmall?.copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hairline between benefit rows.
class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppSpacing.xxl,
      thickness: AppStrokes.hairline,
      color: color.withOpacity(0.55),
    );
  }
}

/// The honest version of the old "signing in adds sync across devices" line.
///
/// Sync is not implemented, so this says what is actually true today: the app
/// needs no account, and choosing to sign in does not move anything off the
/// device.
class _AccountFootnote extends StatelessWidget {
  const _AccountFootnote();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_rounded,
          size: AppSpacing.lg,
          color: context.subtleColor,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'No account needed. Signing in is optional and keeps your entries '
            'on this device either way.',
            textAlign: TextAlign.start,
            style: text.labelSmall?.copyWith(
              height: 1.45,
              color: context.subtleColor,
            ),
          ),
        ),
      ],
    );
  }
}
