import 'package:flutter/material.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Splash
//
// Passive loading screen. Navigation away from here is owned entirely by the
// router's redirect (see `app_router.dart`), which re-runs when the cycle
// tracker finishes loading via `refreshListenable`.
//
// The design constraint that shapes everything below: this screen may be
// visible for a single frame or for a second, and it must never *cause* the
// wait. So there is no timer, no gate, and no "minimum display time" — only a
// single-pass entrance that looks intentional if it completes and looks like a
// clean fade if it doesn't. Anything that loops would still be spinning when
// the router pops it, which is what makes a splash feel like a stall.
//
// One message, centred, on a soft phase wash. The mark and the wordmark are the
// same statement said twice, so assistive technology hears it once: the mark is
// decorative and the wordmark is the header.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: PhaseBackdrop(
        colors: AppColors.menstrualGradient,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

              // Scrolls rather than clips: at 200% text scale on a short
              // viewport this column is taller than the screen, and a splash
              // that hides its own name is worse than one that scrolls.
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: gutter,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Clamped: a viewport shorter than the padding would
                    // otherwise ask for a negative minimum and assert.
                    minHeight: (constraints.maxHeight - AppSpacing.xxl * 2)
                        .clamp(0.0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppLayout.maxContentWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Reveal(child: _BrandMark()),
                          const SizedBox(height: AppSpacing.xxl),
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
                              'Your cycle, your way',
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(
                                color: context.mutedColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.huge),
                          const Reveal(index: 3, child: _QuietProgress()),
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

/// The app mark. Purely decorative — the wordmark underneath already names the
/// app, so this is hidden from assistive technology rather than announced as a
/// second, unlabelled "heart".
///
/// Sized from padding plus the icon rather than a fixed square, so the shape
/// stays derived from the spacing scale instead of a one-off number.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    // The phase swatch rather than the raw gradient constant: it lifts the
    // rose on dark surfaces and pairs it with a legible foreground, so the mark
    // is tuned for both brightnesses instead of only for cream.
    final swatch = PhaseColors.of(context).period;

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: swatch.gradient,
          ),
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          boxShadow: [
            BoxShadow(
              color: swatch.fill.withOpacity(context.isDark ? 0.34 : 0.26),
              blurRadius: AppSpacing.xxl,
              offset: const Offset(0, AppSpacing.sm),
            ),
          ],
        ),
        child: Icon(
          Icons.favorite_rounded,
          size: AppSpacing.huge,
          color: swatch.onFill,
        ),
      ),
    );
  }
}

/// A hairline bar rather than a spinner.
///
/// A 32px spinner is the loudest thing on an otherwise calm screen, and it
/// implies the app is working hard when it is usually reading a few kilobytes
/// off disk. The bar sits low in the hierarchy and says "a moment" instead.
class _QuietProgress extends StatelessWidget {
  const _QuietProgress();

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.of(context).reduced;
    final accent = context.accentColor;
    final track = accent.withOpacity(context.isDark ? 0.22 : 0.14);
    const label = 'Loading CycleCare';

    return SizedBox(
      width: AppLayout.minTouchTarget * 2,
      height: AppSpacing.xs,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: reduced
            // The indeterminate sweep is a looping spatial animation, which is
            // exactly what reduced motion asks us to drop. A determinate bar
            // at a fixed value still reads as "loading" and never moves.
            ? LinearProgressIndicator(
                value: 0.42,
                semanticsLabel: label,
                backgroundColor: track,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              )
            : LinearProgressIndicator(
                semanticsLabel: label,
                backgroundColor: track,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
      ),
    );
  }
}
