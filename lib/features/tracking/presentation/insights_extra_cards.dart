import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/cycle_analytics.dart';
import '../domain/insights_extras.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cards for the analyses in insights_extras.dart.
//
// Every card names the data it stands on ("from 4 cycles", "12 days logged")
// and has an empty state that says what it needs, because a chart built on two
// data points looks exactly as confident as one built on two hundred.
// ─────────────────────────────────────────────────────────────────────────────

/// Shared frame: icon, title, one-line basis, then the body or the empty state.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.basis,
    this.emptyMessage,
  });

  final IconData icon;
  final String title;

  /// e.g. "From 4 cycles". Omitted when the card is empty.
  final String? basis;

  /// When set, shown instead of [child].
  final String? emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      emphasis: CardEmphasis.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(
                    context.isDark ? 0.2 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.compact),
                ),
                child: Icon(icon, size: 18, color: context.accentColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(
                        color: context.inkColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (basis != null && emptyMessage == null)
                      Text(
                        basis!,
                        style: text.labelSmall?.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (emptyMessage != null)
            Text(
              emptyMessage!,
              style: text.bodySmall?.copyWith(color: context.mutedColor),
            )
          else
            child,
        ],
      ),
    );
  }
}

const _needsCycles =
    'Shows once you have logged $minCyclesForInsight complete cycles.';

class RegularityCard extends StatelessWidget {
  const RegularityCard({super.key, required this.analytics});
  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final r = regularityScore(analytics);
    final text = Theme.of(context).textTheme;
    return InsightCard(
      icon: AppIcons.cycle,
      title: 'How regular your cycle is',
      basis: r == null ? null : 'From ${r.cycles} cycles',
      emptyMessage: r == null ? _needsCycles : null,
      child: r == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.bucket.label,
                  style: text.headlineSmall?.copyWith(
                    color: context.inkColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your cycles ran ${r.shortest}–${r.longest} days, usually '
                  'within about ${r.spreadDays.toStringAsFixed(1)} days of '
                  'each other. Some variation is normal for most people.',
                  style: text.bodyMedium?.copyWith(color: context.mutedColor),
                ),
              ],
            ),
    );
  }
}

class PredictionAccuracyCard extends StatelessWidget {
  const PredictionAccuracyCard({super.key, required this.analytics});
  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final p = predictionAccuracy(analytics);
    final text = Theme.of(context).textTheme;
    final f = DateFormat('d MMM');
    return InsightCard(
      icon: Icons.track_changes_rounded,
      title: 'How close the estimates were',
      basis: p == null ? null : 'Checked against ${p.checks.length} cycles',
      emptyMessage: p == null ? _needsCycles : null,
      child: p == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Off by about ${p.averageAbsoluteError.toStringAsFixed(1)} '
                  'days on average',
                  style: text.titleMedium?.copyWith(
                    color: context.inkColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${p.withinTwoDays} of ${p.checks.length} within 2 days',
                  style: text.bodySmall?.copyWith(color: context.mutedColor),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Retrospective replay of the current predictor using only '
                  'earlier period starts, with current settings and exclusions. '
                  'This is not clinical validation or a guarantee of future accuracy.',
                  style: text.bodySmall?.copyWith(color: context.mutedColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final c in p.checks.reversed.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Cycle from ${f.format(c.cycleStart)}',
                            style: text.bodySmall?.copyWith(
                              color: context.inkColor,
                            ),
                          ),
                        ),
                        Text(
                          c.errorDays == 0
                              ? 'On the day'
                              : '${c.errorDays.abs()} '
                                    '${c.errorDays.abs() == 1 ? 'day' : 'days'} '
                                    '${c.errorDays > 0 ? 'later' : 'earlier'}',
                          style: text.labelMedium?.copyWith(
                            color: context.mutedColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
