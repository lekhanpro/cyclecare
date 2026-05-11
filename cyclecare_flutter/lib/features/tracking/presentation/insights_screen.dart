import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/soft_card.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_models.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleTrackerControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: state.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              _PredictionAccuracyCard(data: data),
              const SizedBox(height: 14),
              _CycleLengthTrendCard(periods: data.periods),
              const SizedBox(height: 14),
              _PeriodLengthTrendCard(periods: data.periods),
              const SizedBox(height: 14),
              _SymptomFrequencyCard(logs: data.logs),
              const SizedBox(height: 14),
              _MoodTrendCard(logs: data.logs),
              const SizedBox(height: 14),
              _FlowHistoryCard(logs: data.logs),
              const SizedBox(height: 14),
              _PainTrendCard(logs: data.logs),
            ],
          );
        },
      ),
    );
  }
}

class _PredictionAccuracyCard extends StatelessWidget {
  const _PredictionAccuracyCard({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context) {
    final prediction = data.prediction;
    return _InsightCard(
      title: 'Prediction quality',
      icon: Icons.auto_graph,
      child: prediction == null
          ? const Text('Log your first period to begin predictions.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow('Confidence', '${(prediction.confidence * 100).round()}%'),
                _StatRow('Cycle pattern', prediction.isIrregular ? 'Irregular' : 'Fairly regular'),
                _StatRow('Next estimate', shortDate(prediction.nextPeriodStart)),
                if (prediction.isLate)
                  _StatRow('Late detection', '${prediction.daysLate} days late'),
              ],
            ),
    );
  }
}

class _CycleLengthTrendCard extends StatelessWidget {
  const _CycleLengthTrendCard({required this.periods});

  final List<CycleEvent> periods;

  @override
  Widget build(BuildContext context) {
    final lengths = _cycleLengths(periods);
    return _InsightCard(
      title: 'Cycle length trend',
      icon: Icons.timeline,
      child: lengths.length < 2
          ? const Text('Log at least three periods to see cycle length trends.')
          : _LineMiniChart(values: lengths.map((e) => e.toDouble()).toList()),
    );
  }
}

class _PeriodLengthTrendCard extends StatelessWidget {
  const _PeriodLengthTrendCard({required this.periods});

  final List<CycleEvent> periods;

  @override
  Widget build(BuildContext context) {
    final lengths = periods
        .where((period) => period.endDate != null)
        .map((period) => dateOnly(period.endDate!).difference(dateOnly(period.startDate)).inDays + 1)
        .where((length) => length > 0)
        .toList()
      ..sort();
    return _InsightCard(
      title: 'Period length trend',
      icon: Icons.water_drop,
      child: lengths.length < 2
          ? const Text('Period length appears here once you have several completed periods.')
          : _LineMiniChart(values: lengths.map((e) => e.toDouble()).toList()),
    );
  }
}

class _SymptomFrequencyCard extends StatelessWidget {
  const _SymptomFrequencyCard({required this.logs});

  final List<DailyLog> logs;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final log in logs) {
      for (final symptom in log.symptoms) {
        counts[symptom] = (counts[symptom] ?? 0) + 1;
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _InsightCard(
      title: 'Symptom frequency',
      icon: Icons.healing_outlined,
      child: top.isEmpty
          ? const Text('No symptom patterns yet.')
          : _BarMiniChart(
              labels: top.take(5).map((e) => e.key).toList(),
              values: top.take(5).map((e) => e.value.toDouble()).toList(),
            ),
    );
  }
}

class _MoodTrendCard extends StatelessWidget {
  const _MoodTrendCard({required this.logs});

  final List<DailyLog> logs;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final log in logs) {
      final mood = log.mood;
      if (mood != null) counts[mood] = (counts[mood] ?? 0) + 1;
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _InsightCard(
      title: 'Mood trends',
      icon: Icons.mood_outlined,
      child: top.isEmpty
          ? const Text('Mood patterns appear after a few daily logs.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in top.take(6))
                  Chip(
                    label: Text('${entry.key} ${entry.value}'),
                    backgroundColor: CycleCareColors.predicted,
                  ),
              ],
            ),
    );
  }
}

class _FlowHistoryCard extends StatelessWidget {
  const _FlowHistoryCard({required this.logs});

  final List<DailyLog> logs;

  @override
  Widget build(BuildContext context) {
    final flowLogs = logs.where((log) => log.flow != null && log.flow != FlowIntensity.none).toList();
    return _InsightCard(
      title: 'Flow history',
      icon: Icons.water_drop_outlined,
      child: flowLogs.isEmpty
          ? const Text('Flow history appears after you log period days.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final log in flowLogs.take(12))
                  Chip(
                    label: Text('${shortDate(log.date)}: ${log.flow!.name}'),
                  ),
              ],
            ),
    );
  }
}

class _PainTrendCard extends StatelessWidget {
  const _PainTrendCard({required this.logs});

  final List<DailyLog> logs;

  @override
  Widget build(BuildContext context) {
    final values = logs
        .where((log) => log.painLevel > 0)
        .map((log) => log.painLevel.toDouble())
        .toList();
    return _InsightCard(
      title: 'Pain trends',
      icon: Icons.monitor_heart_outlined,
      child: values.length < 2
          ? const Text('Log pain levels over time to see a trend.')
          : _LineMiniChart(values: values.take(30).toList()),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: CycleCareColors.rose, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: CycleCareColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DefaultTextStyle(
            style: const TextStyle(
              color: CycleCareColors.muted,
              height: 1.4,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              color: CycleCareColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineMiniChart extends StatelessWidget {
  const _LineMiniChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final minY = max(0, values.reduce(min) - 2).toDouble();
    final maxY = values.reduce(max) + 2;
    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: CycleCareColors.line,
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                values.length,
                (index) => FlSpot(index.toDouble(), values[index]),
              ),
              isCurved: true,
              color: CycleCareColors.rose,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: CycleCareColors.rose.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarMiniChart extends StatelessWidget {
  const _BarMiniChart({
    required this.labels,
    required this.values,
  });

  final List<String> labels;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final maxY = values.reduce(max) + 1;
    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  final label = labels[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label.length > 9 ? '${label.substring(0, 8)}.' : label,
                      style: const TextStyle(
                        color: CycleCareColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 22,
                    color: CycleCareColors.rose,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

List<int> _cycleLengths(List<CycleEvent> periods) {
  final sorted = periods.toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  final lengths = <int>[];
  for (var i = 1; i < sorted.length; i++) {
    final length = dateOnly(sorted[i].startDate).difference(dateOnly(sorted[i - 1].startDate)).inDays;
    if (length >= 15 && length <= 90) {
      lengths.add(length);
    }
  }
  return lengths;
}
