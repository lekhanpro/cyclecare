import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../domain/cycle_analytics.dart';
import '../domain/cycle_models.dart';
import '../domain/insights_extras.dart';
import 'insights_extra_cards.dart';

// Phase, heatmap, comparison and logging cards. Split from
// insights_extra_cards.dart only to keep each file readable.

const _phaseOrder = [
  CyclePhase.menstrual,
  CyclePhase.follicular,
  CyclePhase.ovulation,
  CyclePhase.luteal,
];

const _needsCycles =
    'Shows once you have logged $minCyclesForInsight complete cycles.';

/// Mood, sleep and water per phase, as one table so the phases line up.
class ByPhaseCard extends StatelessWidget {
  const ByPhaseCard({super.key, required this.analytics});
  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final mood = moodByPhase(analytics);
    final sleep = sleepByPhase(analytics);
    final water = waterByPhase(analytics);
    final text = Theme.of(context).textTheme;
    final phases = PhaseColors.of(context);
    final empty = mood.isEmpty && sleep.isEmpty && water.isEmpty;

    String topMood(CyclePhase p) {
      final m = mood[p];
      if (m == null || m.isEmpty) return '—';
      final best = m.entries.reduce((a, b) => a.value >= b.value ? a : b);
      return '${best.key} ${(best.value * 100).round()}%';
    }

    String sleepOf(CyclePhase p) =>
        sleep[p] == null ? '—' : '${sleep[p]!.value.toStringAsFixed(1)} h';
    String waterOf(CyclePhase p) => water[p] == null
        ? '—'
        : '${(water[p]!.value / 1000).toStringAsFixed(1)} L';

    return InsightCard(
      icon: AppIcons.basics,
      title: 'Through your cycle',
      basis: empty ? null : 'Typical mood, sleep and water in each phase',
      emptyMessage: empty
          ? 'Log mood, sleep or water across a full cycle to see how they '
              'change from phase to phase.'
          : null,
      child: Column(
        children: [
          for (final p in _phaseOrder)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: phases.phase(p).fill,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: Text(p.label,
                      style: text.labelLarge?.copyWith(
                        color: context.inkColor,
                        fontWeight: FontWeight.w800,
                      )),
                ),
                Expanded(flex: 4, child: _cell(context, Icons.mood_rounded, topMood(p))),
                Expanded(flex: 3, child: _cell(context, AppIcons.sleep, sleepOf(p))),
                Expanded(flex: 3, child: _cell(context, AppIcons.water, waterOf(p))),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, IconData icon, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.subtleColor),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: context.inkColor)),
          ),
        ],
      );
}

/// Symptoms by cycle day. Cell strength is how many cycles had the symptom
/// that day, and the count is printed in the cell so shade is never the only
/// reading.
class SymptomHeatmapCard extends StatelessWidget {
  const SymptomHeatmapCard({super.key, required this.analytics});
  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final h = symptomHeatmap(analytics);
    return InsightCard(
      icon: AppIcons.symptoms,
      title: 'When symptoms show up',
      basis: h == null ? null : 'Across ${h.cycles} cycles, by cycle day',
      emptyMessage: h == null
          ? 'Log symptoms through $minCyclesForInsight complete cycles to see '
              'which days they tend to land on.'
          : null,
      child: h == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in h.symptoms) _HeatRow(map: h, symptom: s),
                  _DayAxis(length: h.cycleLength),
                ],
              ),
            ),
    );
  }
}

const _labelWidth = 96.0;
const _cellWidth = 14.0;
const _cellGap = 2.0;

class _HeatRow extends StatelessWidget {
  const _HeatRow({required this.map, required this.symptom});
  final SymptomHeatmap map;
  final String symptom;

  @override
  Widget build(BuildContext context) {
    final tone = context.accentColor;
    final counts = map.counts[symptom]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        SizedBox(
          width: _labelWidth,
          child: Text(symptom,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: context.inkColor)),
        ),
        for (final n in counts)
          Container(
            width: _cellWidth,
            height: 18,
            margin: const EdgeInsets.only(right: _cellGap),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: n == 0
                  ? context.lineColor.withOpacity(0.5)
                  : tone.withOpacity(0.2 + 0.8 * n / map.cycles),
              borderRadius: BorderRadius.circular(3),
            ),
            child: n == 0
                ? null
                : Text('$n',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: n / map.cycles > 0.5
                          ? Colors.white
                          : context.inkColor,
                    )),
          ),
      ]),
    );
  }
}

class _DayAxis extends StatelessWidget {
  const _DayAxis({required this.length});
  final int length;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(fontSize: 9, color: context.mutedColor);
    return Padding(
      padding: const EdgeInsets.only(left: _labelWidth, top: 2),
      child: Row(children: [
        for (var d = 1; d <= length; d++)
          SizedBox(
            width: _cellWidth + _cellGap,
            child: Text(d % 7 == 1 ? '$d' : '', style: style),
          ),
      ]),
    );
  }
}

class CycleComparisonCard extends StatelessWidget {
  const CycleComparisonCard({super.key, required this.analytics});
  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final c = cycleComparison(analytics);
    final text = Theme.of(context).textTheme;

    Widget row(String label, String now, String usual, {bool head = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(children: [
            Expanded(
              flex: 4,
              child: Text(label,
                  style: text.bodySmall?.copyWith(color: context.mutedColor)),
            ),
            Expanded(
              flex: 3,
              child: Text(now,
                  textAlign: TextAlign.end,
                  style: (head ? text.labelSmall : text.labelLarge)?.copyWith(
                    color: head ? context.mutedColor : context.inkColor,
                    fontWeight: head ? FontWeight.w600 : FontWeight.w800,
                  )),
            ),
            Expanded(
              flex: 3,
              child: Text(usual,
                  textAlign: TextAlign.end,
                  style: (head ? text.labelSmall : text.labelMedium)
                      ?.copyWith(color: context.mutedColor)),
            ),
          ]),
        );

    String pain(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)}/10';

    return InsightCard(
      icon: Icons.compare_arrows_rounded,
      title: 'This cycle so far',
      basis: c == null
          ? null
          : 'Compared with your past cycles up to the same day',
      emptyMessage: c == null ? _needsCycles : null,
      child: c == null
          ? const SizedBox.shrink()
          : Column(children: [
              row('', 'This cycle', 'Usually', head: true),
              row('Cycle day', '${c.dayToday}', 'of about ${c.averageLength}'),
              row(
                'Days with symptoms',
                '${c.symptomDaysThisCycle}',
                c.averageSymptomDaysByNow?.toStringAsFixed(1) ?? '—',
              ),
              row('Average pain', pain(c.averagePainThisCycle),
                  pain(c.averagePainOverall)),
            ]),
    );
  }
}

class LoggingPerCycleCard extends StatelessWidget {
  const LoggingPerCycleCard({super.key, required this.analytics});
  final CycleAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final rows = loggingPerCycle(analytics).reversed.take(6).toList();
    final text = Theme.of(context).textTheme;
    final f = DateFormat('d MMM');
    return InsightCard(
      icon: AppIcons.notes,
      title: 'How much you logged',
      basis: rows.isEmpty ? null : 'Last ${rows.length} cycles',
      emptyMessage:
          rows.isEmpty ? 'Shows once you have a complete cycle logged.' : null,
      child: Column(children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(children: [
              SizedBox(
                width: 64,
                child: Text(f.format(r.cycle.start),
                    style: text.labelMedium?.copyWith(color: context.inkColor)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: r.share.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: context.lineColor,
                    color: context.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${r.daysLogged}/${r.cycle.length} days',
                  style: text.labelSmall?.copyWith(color: context.mutedColor)),
            ]),
          ),
      ]),
    );
  }
}
