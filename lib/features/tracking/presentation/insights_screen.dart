import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../widgets/widgets.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_analytics.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Insights
//
// Reading order: summary numbers first, then one visualisation per question,
// then the raw history at the bottom for anyone who wants to check the working.
//
// Every card follows the same three beats:
//
//   1. A plain-language takeaway. The answer, in words, before any chart. If
//      the sentence needs the chart to make sense, it is a bad sentence.
//   2. The visualisation.
//   3. The fine print: units, date range, sample size.
//
// The honesty rules, because health analytics on small noisy data sets is
// where tracking apps most often overclaim:
//
//  • Every card states the sample size it is drawn from. "Based on 3 cycles"
//    is the difference between information and a horoscope.
//  • Nothing appears until it can be supported. Cards gate themselves behind a
//    minimum number of observations and explain what is still needed instead
//    of rendering an empty chart.
//  • Correlations are reported as co-occurrence, never causation, and only
//    when the effect clears a real threshold (see SymptomPattern.isMeaningful).
//  • No trend line is drawn through fewer than three points. Two points is a
//    line through anything.
//  • Nothing here describes a condition. Ranges, averages and directions only.
//
// Accessibility rules for the charts, which are pixels and therefore invisible
// to a screen reader:
//
//  • Each chart is a single semantics node carrying direction, range, average
//    and latest value as text. Its internals are dropped from the tree.
//  • No series is distinguished by colour alone — every one is named in a
//    legend, and the temperature chart changes dot *shape* across the
//    coverline, not just hue.
// ─────────────────────────────────────────────────────────────────────────────

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleTrackerControllerProvider);

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(title: const Text('Insights')),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Working out your insights',
          ),
        ),
        // Raw exception text tells the user nothing they can act on. Their data
        // is local, so the useful information is "nothing was lost, try again".
        error: (error, _) => _Bounded(
          child: EmptyState(
            icon: Icons.refresh_rounded,
            title: 'Could not load your insights',
            message: 'Your logs are still saved on this device. Something went '
                'wrong reading them back.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(cycleTrackerControllerProvider),
          ),
        ),
        data: (data) => _InsightsBody(data: data),
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context) {
    final analytics = data.analytics;
    final history = analytics.cycleHistory();

    if (data.periods.isEmpty) {
      // Names the two things that unlock this screen, and how long it takes,
      // rather than saying "no data".
      return const _Bounded(
        child: EmptyState(
          emoji: '📊',
          title: 'Nothing to analyse yet',
          message: 'Log a period, then tick symptoms and moods on a few daily '
              'entries. Cycle length needs two period starts; the pattern '
              'cards need two or three cycles before they can say anything '
              'honest.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

        return ListView(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.sm,
            gutter,
            AppSpacing.xxxl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Reveal(
                      child: _SummaryPanel(
                        data: data,
                        analytics: analytics,
                        history: history,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _Section(
                      index: 1,
                      title: 'Cycle trends',
                      subtitle: history.isEmpty
                          ? 'Needs two logged periods'
                          : 'Based on ${history.length} '
                              '${_plural(history.length, 'cycle')}',
                    ),
                    Reveal(
                      index: 2,
                      child: _CycleLengthCard(analytics: analytics),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Reveal(
                      index: 3,
                      child: _PeriodLengthCard(analytics: analytics),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _Section(
                      index: 4,
                      title: 'Patterns',
                      subtitle: 'Where your symptoms tend to land',
                    ),
                    Reveal(
                      index: 5,
                      child: _SymptomPatternCard(analytics: analytics),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Reveal(
                      index: 6,
                      child: _SymptomFrequencyCard(analytics: analytics),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Reveal(index: 7, child: _MoodCard(analytics: analytics)),
                    const SizedBox(height: AppSpacing.xxl),
                    const _Section(
                      index: 8,
                      title: 'Body signals',
                      subtitle: 'Temperature, pain and weight over time',
                    ),
                    Reveal(
                      index: 8,
                      child: _TemperatureCard(analytics: analytics),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Reveal(index: 8, child: _PainCard(analytics: analytics)),
                    const SizedBox(height: AppSpacing.md),
                    Reveal(index: 8, child: _WeightCard(analytics: analytics)),
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      const _Section(
                        index: 8,
                        title: 'Cycle history',
                        subtitle: 'Every completed cycle, most recent first',
                      ),
                      _CycleHistoryList(
                        history: history,
                        average: data.prediction?.averageCycleLength ??
                            data.preferences.averageCycleLength,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    const InfoBanner(
                      icon: Icons.insights_rounded,
                      tone: AppColors.info,
                      title: 'How to read this',
                      message:
                          'These are patterns in what you logged, not medical '
                          'findings. Small data sets show coincidences easily, '
                          'so treat anything here as a question worth asking '
                          'rather than an answer.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Summary ─────────────────────────────────────────────────────────────────

/// The four numbers worth reading before any chart.
///
/// Laid out by available width rather than a fixed 3-across grid: at 320dp, or
/// at 200% text scale on any width, the tiles stack into one column instead of
/// squeezing a 24pt number into 90dp.
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.data,
    required this.analytics,
    required this.history,
  });

  final CycleTrackerState data;
  final CycleAnalytics analytics;
  final List<CycleRecord> history;

  @override
  Widget build(BuildContext context) {
    final prediction = data.prediction;
    final tracked = prediction?.cyclesTracked ?? history.length;
    final measured = prediction != null && tracked >= 2;
    final variable = prediction?.isIrregular == true;

    final averageCycle =
        prediction?.averageCycleLength ?? data.preferences.averageCycleLength;
    final averagePeriod =
        prediction?.averagePeriodLength ?? data.preferences.averagePeriodLength;

    final streak = analytics.loggingStreak();
    final consistency = (analytics.loggingConsistency() * 100).round();
    final oldest = history.isEmpty ? null : history.last.start;

    final notes = <Widget>[
      if (measured &&
          prediction.shortestCycle != null &&
          prediction.longestCycle != null)
        _SummaryNote(
          icon: Icons.straighten_rounded,
          text: 'Your cycles have ranged from ${prediction.shortestCycle} '
              'to ${prediction.longestCycle} days.',
        ),
      _SummaryNote(
        icon: Icons.local_fire_department_rounded,
        tone: AppColors.luteal,
        text: '$streak ${_plural(streak, 'day')} logged in a row, covering '
            '$consistency% of the last 30 days.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          tiles: [
            _MetricTile(
              icon: Icons.repeat_rounded,
              label: 'Average cycle',
              value: '$averageCycle',
              unit: 'days',
              caption: tracked == 0
                  ? 'From your settings'
                  : 'From $tracked ${_plural(tracked, 'cycle')}',
            ),
            _MetricTile(
              icon: Icons.water_drop_rounded,
              accent: AppColors.period,
              label: 'Average period',
              value: '$averagePeriod',
              unit: 'days',
              caption: 'Days of bleeding',
            ),
            _MetricTile(
              icon: Icons.show_chart_rounded,
              accent: variable ? AppColors.warning : AppColors.success,
              label: 'Variability',
              value: measured
                  ? '±${prediction.cycleLengthVariation.toStringAsFixed(1)}'
                  : '—',
              unit: measured ? 'days' : null,
              caption: measured
                  ? (variable ? 'Variable' : 'Steady')
                  : 'Needs 2+ cycles',
              semanticValue: measured
                  ? 'plus or minus '
                      '${prediction.cycleLengthVariation.toStringAsFixed(1)} '
                      'days, ${variable ? 'variable' : 'steady'}'
                  : 'Not enough cycles measured yet',
            ),
            _MetricTile(
              icon: Icons.event_repeat_rounded,
              accent: AppColors.ovulation,
              label: 'Cycles tracked',
              value: '$tracked',
              unit: _plural(tracked, 'cycle'),
              caption: oldest == null
                  ? 'Two period starts make one cycle'
                  : 'Since ${DateFormat('MMM yyyy').format(oldest)}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          emphasis: CardEmphasis.outlined,
          padding: AppInsets.compactCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < notes.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                notes[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Chooses one or two columns from the space and the user's text size, then
/// equalises tile heights within a row.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    // Grows with text scale, so a 200% user gets a single column at any width
    // a phone can offer.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);
    final minTileWidth = 150.0 * scale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsTwo =
            constraints.maxWidth >= minTileWidth * 2 + AppSpacing.md;

        if (!fitsTwo) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                tiles[i],
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < tiles.length; i += 2) {
          final second = i + 1 < tiles.length ? tiles[i + 1] : null;
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: AppSpacing.md));
          }
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: second ?? const SizedBox.shrink()),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// One summary number. Nothing inside is width-locked: the label wraps to two
/// lines and the value and its unit wrap onto separate lines when the text is
/// scaled up.
class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.caption,
    this.accent,
    this.semanticValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String? caption;
  final Color? accent;

  /// Spoken form, when the printed one is shorthand ("±2.3").
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = _legibleTone(context, accent ?? context.accentColor);
    final spoken = semanticValue ?? [value, unit].whereType<String>().join(' ');

    return Semantics(
      container: true,
      label: label,
      value: caption == null ? spoken : '$spoken. $caption',
      child: ExcludeSemantics(
        child: AppCard(
          emphasis: CardEmphasis.outlined,
          padding: AppInsets.compactCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: tone),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: context.mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    value,
                    style: text.headlineSmall?.copyWith(
                      color: context.inkColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (unit != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                      child: Text(
                        unit!,
                        style: text.labelMedium?.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                    ),
                ],
              ),
              if (caption != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  caption!,
                  style: text.bodySmall?.copyWith(color: context.subtleColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryNote extends StatelessWidget {
  const _SummaryNote({required this.icon, required this.text, this.tone});

  final IconData icon;
  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: _legibleTone(context, tone ?? context.accentColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: styles.bodySmall?.copyWith(
                color: context.inkColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trend cards ─────────────────────────────────────────────────────────────

class _CycleLengthCard extends StatelessWidget {
  const _CycleLengthCard({required this.analytics});

  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final points = analytics.cycleLengthTrend();

    return _TrendCard(
      title: 'Cycle length',
      icon: Icons.timeline_rounded,
      color: context.accentColor,
      // The palette accent is already resolved per brightness by the theme,
      // so it needs no further lifting for dark surfaces.
      seriesColor: context.accentColor,
      points: points,
      subject: 'Your cycle length',
      unitLabel: 'days',
      unitSuffix: 'd',
      footnoteUnit: 'Days between period starts',
      sampleNoun: 'cycles',
      driftWords: const (
        steady: 'and lengths have been holding steady',
        rising: 'and recent cycles have been running longer',
        falling: 'and recent cycles have been running shorter',
      ),
      lowData: points.isEmpty
          ? const (
              takeaway: 'No cycle length to show yet.',
              detail: 'Log two periods and the gap between them becomes your '
                  'first cycle length.',
            )
          : (
              takeaway: 'One cycle measured so far — not enough for a trend.',
              detail:
                  'One more cycle and there will be enough to draw a trend.',
            ),
    );
  }
}

class _PeriodLengthCard extends StatelessWidget {
  const _PeriodLengthCard({required this.analytics});

  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final points = analytics.periodLengthTrend();

    return _TrendCard(
      title: 'Period length',
      icon: Icons.water_drop_rounded,
      color: AppColors.period,
      // Bleeding is a phase, so the line takes the phase system's own
      // brightness-tuned rose rather than the raw token.
      seriesColor: PhaseColors.of(context).period.fill,
      points: points,
      subject: 'Your period length',
      unitLabel: 'days',
      unitSuffix: 'd',
      footnoteUnit: 'Days of bleeding',
      sampleNoun: 'periods',
      driftWords: const (
        steady: 'and recent periods have been holding steady',
        rising: 'and recent periods have been running longer',
        falling: 'and recent periods have been running shorter',
      ),
      lowData: const (
        takeaway: 'Not enough completed periods for a trend yet.',
        detail: 'Set an end date when you mark a period and this fills in. '
            'Three completed periods gives a trend.',
      ),
    );
  }
}

class _PainCard extends StatelessWidget {
  const _PainCard({required this.analytics});

  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final points = analytics.painTrend();

    return _TrendCard(
      title: 'Pain levels',
      icon: Icons.monitor_heart_rounded,
      color: AppColors.error,
      seriesColor: _seriesTone(context, AppColors.error),
      points: points,
      subject: 'Your logged pain',
      unitLabel: 'out of 10',
      unitSuffix: '',
      footnoteUnit: 'Self-rated 0–10',
      sampleNoun: 'days',
      minY: 0,
      maxY: 10,
      driftWords: const (
        steady: 'and recent days are holding steady',
        rising: 'and recent days have been rated higher',
        falling: 'and recent days have been rated lower',
      ),
      lowData: const (
        takeaway: 'Not enough pain entries to show movement yet.',
        detail: 'Log pain on three or more days to see how it moves.',
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.analytics});

  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final points = analytics.weightTrend();

    return _TrendCard(
      title: 'Weight',
      icon: Icons.monitor_weight_rounded,
      color: AppColors.success,
      seriesColor: _seriesTone(context, AppColors.success),
      points: points,
      subject: 'Your weight',
      unitLabel: 'kg',
      unitSuffix: 'kg',
      footnoteUnit: 'Kilograms',
      sampleNoun: 'entries',
      decimals: 1,
      driftThreshold: 0.5,
      driftWords: const (
        steady: 'and recent entries are holding steady',
        rising: 'and recent entries have been higher',
        falling: 'and recent entries have been lower',
      ),
      lowData: const (
        takeaway: 'Not enough weight entries for a trend yet.',
        detail: 'Weight shifts a kilogram or two across a normal cycle. Three '
            'entries and the pattern starts to show.',
      ),
    );
  }
}

/// Shared shell for the four dated-value series.
///
/// The takeaway sentence, the chart's spoken summary and the fine print are all
/// derived from the same [_TrendStats], so they cannot drift apart.
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.seriesColor,
    required this.points,
    required this.subject,
    required this.unitLabel,
    required this.unitSuffix,
    required this.footnoteUnit,
    required this.sampleNoun,
    required this.driftWords,
    required this.lowData,
    this.decimals = 0,
    this.driftThreshold = 1,
    this.minY,
    this.maxY,
  });

  /// No trend is drawn through fewer than three points — two points is a line
  /// through anything. Deliberately not a per-card parameter: the gate should
  /// not be relaxable at a call site.
  static const int _minimumPoints = 3;

  /// The average always carries one decimal, even for whole-day series. The
  /// mean of six integers is rarely an integer, and rounding it flatters the
  /// data.
  static const int _averageDecimals = 1;

  final String title;
  final IconData icon;

  /// Header accent. Stays the raw semantic token so the icon tile keeps its
  /// meaning; [_InsightCard] darkens it for legibility itself.
  final Color color;

  /// Stroke for the plotted line and its legend swatch — the same value for
  /// both, so the key can never disagree with the chart.
  final Color seriesColor;

  final List<TrendPoint> points;

  /// Sentence subject, e.g. "Your cycle length".
  final String subject;

  /// Reads inside a sentence: "ranged 26 to 31 **days**".
  final String unitLabel;

  /// Compact axis and tooltip suffix.
  final String unitSuffix;

  /// Printed in the fine print, where there is room to be explicit.
  final String footnoteUnit;

  final String sampleNoun;
  final ({String steady, String rising, String falling}) driftWords;

  /// What to say, and what is still needed, below the minimum sample.
  final ({String takeaway, String detail}) lowData;

  final int decimals;

  /// How much the recent mean must move before a direction is claimed.
  final double driftThreshold;

  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    if (points.length < _minimumPoints) {
      return _InsightCard(
        title: title,
        icon: icon,
        accent: color,
        takeaway: lowData.takeaway,
        child: _NotYet(message: lowData.detail),
      );
    }

    final stats = _TrendStats.from(points, driftThreshold);
    final range = _dateRangeLabel(points.map((point) => point.date));
    final low = _number(stats.min, decimals);
    final high = _number(stats.max, decimals);
    final latest = _number(stats.latest, decimals);
    final average = _number(stats.average, _averageDecimals);
    final drift = switch (stats.drift) {
      _Drift.steady => driftWords.steady,
      _Drift.rising => driftWords.rising,
      _Drift.falling => driftWords.falling,
    };

    return _InsightCard(
      title: title,
      icon: icon,
      accent: color,
      takeaway: '$subject has ranged $low to $high $unitLabel across '
          '${stats.count} $sampleNoun, averaging $average. The latest is '
          '$latest $unitLabel, $drift.',
      footnote: [
        footnoteUnit,
        if (range != null) range,
        '${stats.count} $sampleNoun',
      ].join(' · '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartFrame(
            semanticsLabel: 'Line chart of ${title.toLowerCase()}. '
                '${stats.count} points'
                '${range == null ? '' : ' from $range'}. '
                'Values from $low to $high $unitLabel, averaging $average. '
                'Latest $latest. Direction: ${_driftWord(stats.drift)}.',
            child: _TrendChart(
              points: points,
              color: seriesColor,
              unitSuffix: unitSuffix,
              decimals: decimals,
              average: stats.average,
              minY: minY,
              maxY: maxY,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ChartLegend(
            items: [
              (mark: _LegendMark.line, color: seriesColor, label: 'Your logs'),
              (
                mark: _LegendMark.dash,
                color: context.subtleColor,
                label: 'Average $average$unitSuffix',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Patterns ────────────────────────────────────────────────────────────────

class _SymptomPatternCard extends StatelessWidget {
  const _SymptomPatternCard({required this.analytics});

  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final phases = PhaseColors.of(context);
    // Only patterns that clear both the effect-size and sample-size bars.
    final patterns = analytics
        .symptomPatterns()
        .where((pattern) => pattern.isMeaningful)
        .take(5)
        .toList();
    final symptomLogs = analytics.logs.where((log) => log.symptoms.isNotEmpty);
    final loggedDays = symptomLogs.length;
    final range = _dateRangeLabel(symptomLogs.map((log) => log.date));

    if (patterns.isEmpty) {
      return const _InsightCard(
        title: 'Symptom timing',
        icon: Icons.hub_rounded,
        accent: AppColors.ovulation,
        takeaway: 'No symptom is clustering in one phase yet.',
        child: _NotYet(
          message:
              'Once you have logged symptoms across a couple of full cycles, '
              'anything that clusters in one phase shows up here.',
        ),
      );
    }

    return _InsightCard(
      title: 'Symptom timing',
      icon: Icons.hub_rounded,
      accent: AppColors.ovulation,
      takeaway: '${patterns.length} of your symptoms show up in one phase '
          'more often than an even spread would predict.',
      footnote: [
        'Co-occurrence, not cause',
        if (range != null) range,
        '$loggedDays ${_plural(loggedDays, 'day')} with symptoms logged',
        '${patterns.length} shown',
      ].join(' · '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final pattern in patterns)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.description,
                      style: text.bodyMedium?.copyWith(
                        color: context.inkColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Phase is named in text as well as tinted, so the
                    // grouping survives greyscale and colour blindness.
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Tag(
                          label: '${pattern.dominantPhase.label} phase',
                          swatch: phases.phase(pattern.dominantPhase),
                        ),
                        Text(
                          '${pattern.occurrences} logs · '
                          '${pattern.lift.toStringAsFixed(1)}× more often '
                          'than an even spread',
                          style: text.labelSmall?.copyWith(
                            color: context.mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Text(
            'These are co-occurrences in your own logs, not causes.',
            style: text.bodySmall?.copyWith(
              color: context.mutedColor,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomFrequencyCard extends StatelessWidget {
  const _SymptomFrequencyCard({required this.analytics});

  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final top = analytics.topSymptoms();
    final logs = analytics.logs.where((log) => log.symptoms.isNotEmpty);
    final days = logs.length;
    final range = _dateRangeLabel(logs.map((log) => log.date));

    if (top.isEmpty) {
      return const _InsightCard(
        title: 'Most logged symptoms',
        icon: Icons.healing_rounded,
        accent: AppColors.luteal,
        takeaway: 'No symptoms logged yet.',
        child: _NotYet(
          message: 'Tick whatever you notice on a daily log and the most '
              'frequent ones rank here.',
        ),
      );
    }

    final first = top.first;
    final takeaway = top.length == 1
        ? '${first.symptom} is the only symptom you have logged, on '
            '${first.count} ${_plural(first.count, 'day')}.'
        : '${first.symptom} is your most logged symptom '
            '(${first.count} ${_plural(first.count, 'day')}), followed by '
            '${top[1].symptom} (${top[1].count}).';

    return _InsightCard(
      title: 'Most logged symptoms',
      icon: Icons.healing_rounded,
      accent: AppColors.luteal,
      takeaway: takeaway,
      footnote: [
        'Days logged',
        if (range != null) range,
        '$days ${_plural(days, 'day')} with symptoms',
      ].join(' · '),
      child: _RankedBars(
        color: AppColors.luteal,
        unitNoun: 'day',
        entries: [
          for (final entry in top) (label: entry.symptom, count: entry.count),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.analytics});

  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final moods = analytics.moodDistribution();
    final logs =
        analytics.logs.where((log) => log.mood != null && log.mood!.isNotEmpty);
    final total = moods.fold(0, (sum, entry) => sum + entry.count);
    final range = _dateRangeLabel(logs.map((log) => log.date));

    if (moods.isEmpty) {
      return const _InsightCard(
        title: 'Mood distribution',
        icon: Icons.mood_rounded,
        accent: AppColors.info,
        takeaway: 'No moods logged yet.',
        child: _NotYet(
          message: 'Mood patterns appear after a handful of daily logs.',
        ),
      );
    }

    final shown = moods.take(6).toList();
    final first = shown.first;
    final share = total == 0 ? 0 : ((first.count / total) * 100).round();

    return _InsightCard(
      title: 'Mood distribution',
      icon: Icons.mood_rounded,
      accent: AppColors.info,
      takeaway: 'You logged ${first.mood} most often — ${first.count} of '
          '$total ${_plural(total, 'entry', 'entries')}, about $share%.',
      footnote: [
        'Entries logged',
        if (range != null) range,
        '$total mood ${_plural(total, 'entry', 'entries')}',
      ].join(' · '),
      child: _RankedBars(
        color: AppColors.info,
        unitNoun: 'entry',
        unitNounPlural: 'entries',
        entries: [
          for (final entry in shown) (label: entry.mood, count: entry.count),
        ],
      ),
    );
  }
}

/// Ranked horizontal bars.
///
/// Chosen over a donut deliberately: symptom and mood names are long, a
/// rotated axis is unreadable on a phone, and a ring forces the reader to
/// compare arc lengths when the honest answer is a number. Rank and count are
/// printed next to every bar, so the bar is reinforcement rather than the only
/// way to read the value.
class _RankedBars extends StatelessWidget {
  const _RankedBars({
    required this.entries,
    required this.color,
    required this.unitNoun,
    this.unitNounPlural,
  });

  final List<({String label, int count})> entries;
  final Color color;
  final String unitNoun;
  final String? unitNounPlural;

  @override
  Widget build(BuildContext context) {
    final highest = entries.first.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == entries.length - 1 ? 0 : AppSpacing.md,
            ),
            child: _RankedBar(
              rank: i + 1,
              total: entries.length,
              label: entries[i].label,
              count: entries[i].count,
              max: highest,
              color: color,
              unitNoun: unitNoun,
              unitNounPlural: unitNounPlural,
            ),
          ),
      ],
    );
  }
}

class _RankedBar extends StatelessWidget {
  const _RankedBar({
    required this.rank,
    required this.total,
    required this.label,
    required this.count,
    required this.max,
    required this.color,
    required this.unitNoun,
    this.unitNounPlural,
  });

  final int rank;
  final int total;
  final String label;
  final int count;
  final int max;
  final Color color;
  final String unitNoun;
  final String? unitNounPlural;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final fraction = max == 0 ? 0.0 : count / max;

    return Semantics(
      container: true,
      label: label,
      value: '$count ${_plural(count, unitNoun, unitNounPlural)}, '
          'ranked $rank of $total',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$rank',
                  style: text.labelSmall?.copyWith(
                    color: context.subtleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: context.inkColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$count',
                  style: text.labelLarge?.copyWith(color: context.inkColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              // Deliberately the workhorse duration rather than the long
              // reveal: a ListView rebuilds these every time they scroll back
              // into view, so anything slower turns into a tic.
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: fraction),
                duration: motion(AppDurations.normal),
                curve: AppCurves.out,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: AppSpacing.sm,
                  backgroundColor: context.lineColor,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Body signals ────────────────────────────────────────────────────────────

class _TemperatureCard extends StatelessWidget {
  const _TemperatureCard({required this.analytics});

  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final analysis = analytics.temperatureAnalysis();
    final points = analysis.points;

    if (!analysis.hasEnoughData) {
      return _InsightCard(
        title: 'Basal temperature',
        icon: Icons.thermostat_rounded,
        accent: AppColors.fertile,
        takeaway: points.isEmpty
            ? 'No temperature readings this cycle yet.'
            : '${points.length} of the 8 readings needed this cycle.',
        child: _NotYet(
          message: points.isEmpty
              ? 'Log your temperature each morning before getting up. After '
                  'about eight readings the post-ovulation shift becomes '
                  'visible.'
              : '${points.length} of 8 readings needed this cycle '
                  'before a coverline can be drawn.',
        ),
      );
    }

    final values = points.map((point) => point.celsius).toList();
    final low = values.reduce(min);
    final high = values.reduce(max);
    final coverline = analysis.coverline;
    final shift = analysis.thermalShiftDay;
    final firstDay = points.first.cycleDay;
    final lastDay = points.last.cycleDay;

    // Resolved once and shared by the plot and its legend. Both hues come from
    // the phase system, which tunes them per brightness, so the teal and
    // violet keep their identity on a near-black card instead of going muddy.
    final phases = PhaseColors.of(context);
    final readingTone = phases.fertile.fill;
    final aboveTone = phases.ovulation.fill;

    return _InsightCard(
      title: 'Basal temperature',
      icon: Icons.thermostat_rounded,
      accent: AppColors.fertile,
      takeaway: shift == null
          ? 'No sustained rise detected yet this cycle. Temperature confirms '
              'ovulation after it happens, so this can stay flat until the '
              'luteal phase begins.'
          : 'Your readings have stayed above a '
              '${coverline!.toStringAsFixed(2)} °C coverline since day $shift '
              '— consistent with ovulation having happened.',
      footnote: 'Degrees Celsius · cycle days $firstDay–$lastDay · '
          '${points.length} readings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartFrame(
            aspectRatio: 1.6,
            semanticsLabel: 'Line chart of basal temperature by cycle day. '
                '${points.length} readings from cycle day $firstDay to '
                '$lastDay, ranging ${low.toStringAsFixed(2)} to '
                '${high.toStringAsFixed(2)} degrees Celsius. '
                '${coverline == null ? 'No coverline yet.' : 'Coverline '
                    '${coverline.toStringAsFixed(2)}.'} '
                '${shift == null ? 'No sustained rise detected yet.' : 'Sustained rise from day $shift.'}',
            child: _TemperatureChart(
              analysis: analysis,
              readingTone: readingTone,
              aboveTone: aboveTone,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ChartLegend(
            items: [
              (
                mark: _LegendMark.dot,
                color: readingTone,
                label: 'Reading',
              ),
              if (coverline != null) ...[
                (
                  mark: _LegendMark.square,
                  color: aboveTone,
                  label: 'At or above coverline',
                ),
                (
                  mark: _LegendMark.dash,
                  color: aboveTone,
                  label: 'Coverline ${coverline.toStringAsFixed(2)} °C',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Cycle history ───────────────────────────────────────────────────────────

class _CycleHistoryList extends StatelessWidget {
  const _CycleHistoryList({required this.history, required this.average});

  final List<CycleRecord> history;
  final int average;

  static const _visible = 12;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shown = history.take(_visible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final record in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _HistoryRow(record: record, average: average),
          ),
        if (history.length > _visible)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              left: AppSpacing.xs,
            ),
            child: Text(
              'Showing the $_visible most recent of ${history.length} cycles.',
              style: text.labelSmall?.copyWith(color: context.subtleColor),
            ),
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record, required this.average});

  final CycleRecord record;
  final int average;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final deviation = record.deviationFrom(average);
    final span = '${DateFormat('MMM d').format(record.start)} to '
        '${DateFormat('MMM d, yyyy').format(record.end)}';
    final deviationPhrase = deviation == 0
        ? 'matching your $average day average'
        : '${deviation.abs()} ${_plural(deviation.abs(), 'day')} '
            '${deviation > 0 ? 'longer' : 'shorter'} than your $average day '
            'average';

    return Semantics(
      container: true,
      label: span,
      value: '${record.length} day cycle, $deviationPhrase'
          '${record.periodLength == null ? '' : ', ${record.periodLength} '
              'day period'}',
      child: ExcludeSemantics(
        child: AppCard(
          emphasis: CardEmphasis.outlined,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          // Wrap rather than Row: at normal text size the dates and the pills
          // sit on one line pushed apart, and when the text is scaled up the
          // pills drop onto a second run instead of overflowing. A Row would
          // hand the trailing group unbounded width and clip it.
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d').format(record.start),
                    style: text.titleSmall?.copyWith(
                      color: context.inkColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'to ${DateFormat('MMM d, yyyy').format(record.end)}',
                    style: text.labelSmall?.copyWith(
                      color: context.mutedColor,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (record.periodLength != null)
                    _Pill(
                      label: '${record.periodLength}d bleed',
                      color: AppColors.period,
                    ),
                  _DeviationPill(length: record.length, deviation: deviation),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(AppRadii.compact),
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: _legibleTone(context, color),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Cycle length with its deviation from the average.
///
/// The deviation is the useful number — "31 days" means nothing without
/// knowing that this person usually runs 28. The sign is printed, so the
/// traffic-light tint is a second signal rather than the only one.
class _DeviationPill extends StatelessWidget {
  const _DeviationPill({required this.length, required this.deviation});

  final int length;
  final int deviation;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = deviation.abs() <= 2
        ? AppColors.success
        : deviation.abs() <= 5
            ? AppColors.warning
            : AppColors.error;
    final ink = _legibleTone(context, color);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(context.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(AppRadii.compact),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${length}d',
            style: text.labelMedium?.copyWith(
              color: ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (deviation != 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              deviation > 0 ? '+$deviation' : '$deviation',
              style: text.labelSmall?.copyWith(color: ink),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared chrome ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, this.index = 0});

  final String title;
  final String? subtitle;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      index: index,
      child: MergeSemantics(
        child: Semantics(
          header: true,
          child: SectionHeader(
            title: title,
            subtitle: subtitle,
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              bottom: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }
}

/// Centres a full-screen state and holds it to the same measure as the scroll
/// body, so a tablet gets a readable column instead of one long line of type.
class _Bounded extends StatelessWidget {
  const _Bounded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// Card shell: title, plain-language takeaway, content, fine print.
class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.icon,
    required this.takeaway,
    required this.child,
    this.accent,
    this.footnote,
  });

  final String title;
  final IconData icon;

  /// What the data says, in words, before the reader meets a chart.
  final String takeaway;

  final Widget child;
  final Color? accent;

  /// Units, date range and sample size. Every chart in this app carries the
  /// number of observations behind it.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = accent ?? context.accentColor;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.xxxl,
                height: AppSpacing.xxxl,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withOpacity(context.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.compact),
                ),
                child: Icon(icon, size: 17, color: _legibleTone(context, tone)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      color: context.inkColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            takeaway,
            style: text.bodyMedium?.copyWith(
              color: context.inkColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
          if (footnote != null) ...[
            Divider(
              height: AppSpacing.xxl,
              thickness: AppStrokes.hairline,
              color: context.lineColor,
            ),
            Text(
              footnote!,
              style: text.labelSmall?.copyWith(color: context.subtleColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// Explains what is still needed rather than showing an empty chart.
class _NotYet extends StatelessWidget {
  const _NotYet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'Not enough data yet',
      value: message,
      child: ExcludeSemantics(
        child: Container(
          padding: AppInsets.compactCard,
          decoration: BoxDecoration(
            color: context.lineColor.withOpacity(context.isDark ? 0.38 : 0.44),
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                size: 16,
                color: context.mutedColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: text.bodySmall?.copyWith(
                    color: context.mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gives a chart a shape that survives both a 320dp phone and a tablet, and
/// replaces its internals with one spoken sentence.
class _ChartFrame extends StatelessWidget {
  const _ChartFrame({
    required this.semanticsLabel,
    required this.child,
    this.aspectRatio = 16 / 9,
  });

  /// Ceiling for wide layouts, so a 700dp card does not get a 400px chart.
  static const double _maxHeight = 240;

  final String semanticsLabel;
  final Widget child;

  /// Ratio rather than a fixed height: 160px clips on a small screen and looks
  /// like a strip on a tablet.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    // Axis ticks are shorthand rather than content — they are all restated in
    // the takeaway, the fine print and the spoken summary — so their scaling
    // is capped to keep the plot area readable at 200%.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);

    return Semantics(
      container: true,
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _maxHeight * scale),
            child: AspectRatio(aspectRatio: aspectRatio, child: child),
          ),
        ),
      ),
    );
  }
}

/// Line chart for a series of dated values.
class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.points,
    required this.color,
    required this.unitSuffix,
    required this.decimals,
    required this.average,
    this.minY,
    this.maxY,
  });

  final List<TrendPoint> points;
  final Color color;
  final String unitSuffix;
  final int decimals;
  final double average;
  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final values = points.map((point) => point.value).toList();
    final lowest = minY ?? (values.reduce(min) - 2).clamp(0, double.infinity);
    final highest = maxY ?? values.reduce(max) + 2;
    final tickStyle = text.labelSmall?.copyWith(color: context.subtleColor);

    return LineChart(
      duration: motion(AppDurations.normal),
      curve: AppCurves.out,
      LineChartData(
        minY: lowest.toDouble(),
        maxY: highest,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.lineColor,
            strokeWidth: AppStrokes.hairline,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                // Only the extremes get a label. A full axis of numbers on a
                // chart this size is noise.
                if (value != meta.min && value != meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(value.toStringAsFixed(0), style: tickStyle);
              },
            ),
          ),
        ),
        // The average line is what turns a wiggle into a reading: it shows
        // whether the latest point is high or low for this person.
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: average,
              color: context.subtleColor.withOpacity(0.5),
              strokeWidth: AppStrokes.hairline,
              dashArray: const [4, 4],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: AppRadii.compact,
            tooltipBorder: BorderSide(color: color, width: AppStrokes.selected),
            getTooltipColor: (_) =>
                context.isDark ? AppColors.darkCard : AppColors.ink,
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${spot.y.toStringAsFixed(decimals)}$unitSuffix\n'
                  '${_labelAt(spot.x.toInt())}',
                  text.labelMedium?.copyWith(
                        color: context.isDark
                            ? AppColors.darkText
                            : AppColors.white,
                      ) ??
                      const TextStyle(color: AppColors.white),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            // Kept low: heavy smoothing invents values between points that
            // were never measured.
            curveSmoothness: 0.22,
            color: color,
            barWidth: 2.8,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 2,
                strokeColor: context.cardColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.22), color.withOpacity(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelAt(int index) =>
      index >= 0 && index < points.length ? points[index].label : '';
}

/// Temperature chart with the fertility-awareness coverline drawn across it.
class _TemperatureChart extends StatelessWidget {
  const _TemperatureChart({
    required this.analysis,
    required this.readingTone,
    required this.aboveTone,
  });

  final TemperatureAnalysis analysis;

  /// Pre-ovulatory readings.
  final Color readingTone;

  /// Readings at or above the coverline, and the coverline itself.
  final Color aboveTone;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final points = analysis.points;
    final values = points.map((point) => point.celsius).toList();
    final coverline = analysis.coverline;
    final tickStyle = text.labelSmall?.copyWith(color: context.subtleColor);

    // Padded to include the coverline, otherwise it can sit outside the
    // plotted range and simply not render.
    final lowest =
        min(values.reduce(min), coverline ?? values.reduce(min)) - 0.2;
    final highest =
        max(values.reduce(max), coverline ?? values.reduce(max)) + 0.2;

    return LineChart(
      duration: motion(AppDurations.normal),
      curve: AppCurves.out,
      LineChartData(
        minY: lowest,
        maxY: highest,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.lineColor,
            strokeWidth: AppStrokes.hairline,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value != meta.min && value != meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(value.toStringAsFixed(1), style: tickStyle);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (points.length / 5).ceilToDouble(),
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('d${points[index].cycleDay}', style: tickStyle),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (coverline != null)
              HorizontalLine(
                y: coverline,
                color: aboveTone,
                strokeWidth: 1.4,
                dashArray: const [5, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: text.labelSmall?.copyWith(
                    color: _legibleTone(context, AppColors.ovulation),
                    fontWeight: FontWeight.w900,
                  ),
                  labelResolver: (_) => 'Coverline',
                ),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.2,
            color: readingTone,
            barWidth: 2.6,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                // Readings at or above the coverline are the post-ovulatory
                // ones — the point of the chart. Marked by shape as well as
                // colour so the distinction survives greyscale.
                final above = coverline != null && spot.y >= coverline;
                if (above) {
                  return FlDotSquarePainter(
                    size: 6,
                    color: aboveTone,
                    strokeWidth: 2,
                    strokeColor: context.cardColor,
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: readingTone,
                  strokeWidth: 2,
                  strokeColor: context.cardColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  readingTone.withOpacity(0.2),
                  readingTone.withOpacity(0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LegendMark { line, dash, dot, square }

/// Names every series. A chart that can only be read by matching hues is not
/// readable by everyone.
class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});

  final List<({_LegendMark mark, Color color, String label})> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // A Row nested in a Wrap is handed unbounded width, so at 200% text scale
    // a label like "At or above coverline" would run off the card instead of
    // wrapping. Each item is bounded to the card width and its label made
    // flexible, so long labels wrap in place and short ones still pack
    // several to a line.
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          for (final item in items)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: _LegendMarker(mark: item.mark, color: item.color),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Flexible(
                    child: Text(
                      item.label,
                      style: text.labelSmall?.copyWith(
                        color: context.mutedColor,
                      ),
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

class _LegendMarker extends StatelessWidget {
  const _LegendMarker({required this.mark, required this.color});

  final _LegendMark mark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (mark) {
      case _LegendMark.line:
        return _bar(14, 3, AppRadii.connected);
      case _LegendMark.dash:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(6, 2, AppRadii.connected),
            const SizedBox(width: 3),
            _bar(6, 2, AppRadii.connected),
          ],
        );
      case _LegendMark.dot:
        return _bar(9, 9, AppRadii.pill);
      case _LegendMark.square:
        return _bar(9, 9, 2);
    }
  }

  Widget _bar(double width, double height, double radius) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Small text badge. Carries the phase name so phase grouping is never colour
/// alone.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.swatch});

  final String label;
  final PhaseSwatch swatch;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: swatch.surface,
        borderRadius: BorderRadius.circular(AppRadii.compact),
        border: Border.all(
          color: swatch.border,
          width: AppStrokes.hairline,
        ),
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: swatch.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Presentation-only helpers ───────────────────────────────────────────────

enum _Drift { rising, falling, steady }

/// Display statistics for a trend series.
///
/// Nothing here changes how a value was measured — it reads the same points the
/// chart plots and describes them, so the sentence, the spoken summary and the
/// plot can never disagree.
class _TrendStats {
  const _TrendStats._({
    required this.count,
    required this.min,
    required this.max,
    required this.average,
    required this.latest,
    required this.drift,
  });

  factory _TrendStats.from(List<TrendPoint> points, double driftThreshold) {
    final values = points.map((point) => point.value).toList();
    return _TrendStats._(
      count: values.length,
      min: values.reduce((a, b) => a < b ? a : b),
      max: values.reduce((a, b) => a > b ? a : b),
      average: values.reduce((a, b) => a + b) / values.length,
      latest: values.last,
      drift: _driftOf(values, driftThreshold),
    );
  }

  final int count;
  final double min;
  final double max;
  final double average;
  final double latest;
  final _Drift drift;

  /// Recent mean against earlier mean, and only called a direction once the
  /// gap clears a threshold. Otherwise every series "trends" somewhere.
  static _Drift _driftOf(List<double> values, double threshold) {
    if (values.length < 3) return _Drift.steady;
    final split =
        values.length >= 6 ? values.length - 3 : (values.length / 2).ceil();
    final earlier = values.sublist(0, split);
    final recent = values.sublist(split);
    final delta = _mean(recent) - _mean(earlier);
    if (delta >= threshold) return _Drift.rising;
    if (delta <= -threshold) return _Drift.falling;
    return _Drift.steady;
  }

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;
}

String _driftWord(_Drift drift) => switch (drift) {
      _Drift.rising => 'rising',
      _Drift.falling => 'falling',
      _Drift.steady => 'holding steady',
    };

String _number(double value, int decimals) => value.toStringAsFixed(decimals);

String _plural(int count, String singular, [String? plural]) =>
    count == 1 ? singular : (plural ?? '${singular}s');

/// "Mar 3 – Jun 12", with years added only when the span crosses one.
String? _dateRangeLabel(Iterable<DateTime?> dates) {
  final sorted = dates.whereType<DateTime>().toList()..sort();
  if (sorted.isEmpty) return null;

  final first = sorted.first;
  final last = sorted.last;
  final sameYear = first.year == last.year;
  final format = DateFormat(sameYear ? 'MMM d' : 'MMM d, yyyy');
  if (first == last) return format.format(first);
  return '${format.format(first)} – ${format.format(last)}';
}

/// Pulls a pastel semantic hue toward the ink (or toward white in dark mode)
/// so it can carry text and iconography.
///
/// The raw phase and status colours stay untouched for fills, lines and dots,
/// where they are read as areas rather than glyphs.
Color _legibleTone(BuildContext context, Color tone) => context.isDark
    ? Color.lerp(tone, Colors.white, 0.22)!
    : Color.lerp(tone, AppColors.ink, 0.26)!;

/// Stroke colour for a chart series drawn from a fixed status token.
///
/// Applies the same lift [PhaseColors] uses on dark surfaces, so a 2.8px line
/// in a saturated hue keeps its separation from a near-black card. Untouched in
/// light mode, where the raw token already reads cleanly on cream.
Color _seriesTone(BuildContext context, Color tone) =>
    context.isDark ? Color.lerp(tone, Colors.white, 0.18)! : tone;
