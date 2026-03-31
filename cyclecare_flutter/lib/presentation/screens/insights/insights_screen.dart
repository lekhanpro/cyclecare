import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../providers/app_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(periodsProvider);
    final logsAsync = ref.watch(dailyLogsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        centerTitle: true,
      ),
      body: periodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading data: $e')),
        data: (periods) {
          return logsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error loading data: $e')),
            data: (logs) {
              if (periods.isEmpty && logs.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CycleStatisticsCard(
                    periods: periods,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _CycleLengthTrendCard(
                    periods: periods,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _SymptomFrequencyCard(
                    logs: logs,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _MoodPatternsCard(
                    logs: logs,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _BBTChartCard(
                    logs: logs,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _CyclePhaseCard(
                    periods: periods,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Not enough data yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your cycles and daily data to see '
              'insights and analytics here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──

List<int> _cycleLengths(List<PeriodRecord> periods) {
  if (periods.length < 2) return [];
  final sorted = List<PeriodRecord>.from(periods)
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  final lengths = <int>[];
  for (int i = 1; i < sorted.length; i++) {
    lengths.add(
      sorted[i].startDate.difference(sorted[i - 1].startDate).inDays,
    );
  }
  return lengths;
}

List<int> _periodLengths(List<PeriodRecord> periods) {
  return periods
      .where((p) => p.endDate != null)
      .map((p) => p.endDate!.difference(p.startDate).inDays + 1)
      .toList();
}

// ═════════════════════════════════════════════════════════
//  Card 1: Cycle Statistics
// ═════════════════════════════════════════════════════════

class _CycleStatisticsCard extends StatelessWidget {
  final List<PeriodRecord> periods;
  final ColorScheme colorScheme;

  const _CycleStatisticsCard({
    required this.periods,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final cycles = _cycleLengths(periods);
    final periodLens = _periodLengths(periods);

    final avgCycle = cycles.isEmpty
        ? 0.0
        : cycles.reduce((a, b) => a + b) / cycles.length;
    final avgPeriod = periodLens.isEmpty
        ? 0.0
        : periodLens.reduce((a, b) => a + b) / periodLens.length;

    double regularity = 0;
    if (cycles.isNotEmpty) {
      final regular =
          cycles.where((c) => (c - avgCycle).abs() <= 3).length;
      regularity = (regular / cycles.length) * 100;
    }

    return _InsightCard(
      title: 'Cycle Statistics',
      icon: Icons.bar_chart_outlined,
      colorScheme: colorScheme,
      child: cycles.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Log at least 2 periods to see cycle statistics.',
              ),
            )
          : Row(
              children: [
                _StatTile(
                  label: 'Avg Cycle',
                  value: '${avgCycle.round()}',
                  unit: 'days',
                  colorScheme: colorScheme,
                ),
                _StatTile(
                  label: 'Avg Period',
                  value: '${avgPeriod.round()}',
                  unit: 'days',
                  colorScheme: colorScheme,
                ),
                _StatTile(
                  label: 'Regularity',
                  value: '${regularity.round()}',
                  unit: '%',
                  colorScheme: colorScheme,
                ),
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final ColorScheme colorScheme;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
          Text(unit, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
//  Card 2: Cycle Length Trend (LineChart)
// ═════════════════════════════════════════════════════════

class _CycleLengthTrendCard extends StatelessWidget {
  final List<PeriodRecord> periods;
  final ColorScheme colorScheme;

  const _CycleLengthTrendCard({
    required this.periods,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final cycles = _cycleLengths(periods);
    final display =
        cycles.length > 6 ? cycles.sublist(cycles.length - 6) : cycles;

    return _InsightCard(
      title: 'Cycle Length Trend',
      icon: Icons.show_chart_outlined,
      colorScheme: colorScheme,
      child: display.length < 2
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Log at least 3 periods to see cycle trends.',
              ),
            )
          : SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.round()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'C${value.round() + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: (display.reduce(min) - 3).toDouble(),
                  maxY: (display.reduce(max) + 3).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        display.length,
                        (i) => FlSpot(
                          i.toDouble(),
                          display[i].toDouble(),
                        ),
                      ),
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: colorScheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════
//  Card 3: Symptom Frequency (bar chart)
// ═════════════════════════════════════════════════════════

class _SymptomFrequencyCard extends StatelessWidget {
  final List<DailyLogRecord> logs;
  final ColorScheme colorScheme;

  const _SymptomFrequencyCard({
    required this.logs,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final log in logs) {
      try {
        final symptoms = jsonDecode(log.symptoms) as List;
        for (final s in symptoms) {
          counts[s as String] = (counts[s] ?? 0) + 1;
        }
      } catch (_) {}
    }

    if (counts.isEmpty) {
      return _InsightCard(
        title: 'Symptom Frequency',
        icon: Icons.healing_outlined,
        colorScheme: colorScheme,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('No symptom data logged yet.'),
        ),
      );
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();
    final maxVal = top5.first.value.toDouble();

    return _InsightCard(
      title: 'Symptom Frequency',
      icon: Icons.healing_outlined,
      colorScheme: colorScheme,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal + 1,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= top5.length) {
                      return const SizedBox.shrink();
                    }
                    final name = top5[idx].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        name.length > 8
                            ? '${name.substring(0, 7)}...'
                            : name,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.outline,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(top5.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: top5[i].value.toDouble(),
                    color: colorScheme.primary,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
//  Card 4: Mood Patterns (PieChart)
// ═════════════════════════════════════════════════════════

class _MoodPatternsCard extends StatelessWidget {
  final List<DailyLogRecord> logs;
  final ColorScheme colorScheme;

  const _MoodPatternsCard({
    required this.logs,
    required this.colorScheme,
  });

  static const _moodColors = [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFFF5722),
  ];

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final log in logs) {
      if (log.mood.isNotEmpty) {
        for (final m in log.mood.split(',')) {
          final mood = m.trim();
          if (mood.isNotEmpty) {
            counts[mood] = (counts[mood] ?? 0) + 1;
          }
        }
      }
    }

    if (counts.isEmpty) {
      return _InsightCard(
        title: 'Mood Patterns',
        icon: Icons.emoji_emotions_outlined,
        colorScheme: colorScheme,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('No mood data logged yet.'),
        ),
      );
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (s, e) => s + e.value);
    final displayCount = sorted.length.clamp(0, 8);

    return _InsightCard(
      title: 'Mood Patterns',
      icon: Icons.emoji_emotions_outlined,
      colorScheme: colorScheme,
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: List.generate(displayCount, (i) {
                    final pct = sorted[i].value / total * 100;
                    return PieChartSectionData(
                      value: sorted[i].value.toDouble(),
                      title: '${pct.round()}%',
                      color: _moodColors[i % _moodColors.length],
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(displayCount, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _moodColors[i % _moodColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sorted[i].key,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
//  Card 5: BBT Chart (LineChart)
// ═════════════════════════════════════════════════════════

class _BBTChartCard extends StatelessWidget {
  final List<DailyLogRecord> logs;
  final ColorScheme colorScheme;

  const _BBTChartCard({
    required this.logs,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final tempLogs = logs
        .where((l) => l.temperature != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final display = tempLogs.length > 30
        ? tempLogs.sublist(tempLogs.length - 30)
        : tempLogs;

    if (display.length < 2) {
      return _InsightCard(
        title: 'BBT Chart',
        icon: Icons.thermostat_outlined,
        colorScheme: colorScheme,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Log at least 2 days of temperature data to see '
            'BBT trends.',
          ),
        ),
      );
    }

    final temps = display.map((l) => l.temperature!).toList();
    final minTemp = temps.reduce(min) - 0.3;
    final maxTemp = temps.reduce(max) + 0.3;

    return _InsightCard(
      title: 'BBT Chart',
      icon: Icons.thermostat_outlined,
      colorScheme: colorScheme,
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 0.2,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 0.2,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval:
                      max(1, (display.length / 5).ceilToDouble()),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= display.length) {
                      return const SizedBox.shrink();
                    }
                    final d = display[idx].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${d.day}/${d.month}',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.outline,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: minTemp,
            maxY: maxTemp,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  display.length,
                  (i) => FlSpot(
                    i.toDouble(),
                    display[i].temperature!,
                  ),
                ),
                isCurved: true,
                color: colorScheme.tertiary,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: colorScheme.tertiary,
                    strokeWidth: 1.5,
                    strokeColor: colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: colorScheme.tertiary.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
//  Card 6: Cycle Phase Analysis
// ═════════════════════════════════════════════════════════

class _CyclePhaseCard extends StatelessWidget {
  final List<PeriodRecord> periods;
  final ColorScheme colorScheme;

  const _CyclePhaseCard({
    required this.periods,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return _InsightCard(
        title: 'Cycle Phase Analysis',
        icon: Icons.donut_large_outlined,
        colorScheme: colorScheme,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Log a period to see your current cycle phase.'),
        ),
      );
    }

    final sorted = List<PeriodRecord>.from(periods)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final latest = sorted.first;
    final now = DateTime.now();
    final daysSinceStart = now.difference(latest.startDate).inDays;

    final cycles = _cycleLengths(periods);
    final avgCycle = cycles.isEmpty
        ? AppConstants.defaultCycleLength
        : (cycles.reduce((a, b) => a + b) / cycles.length).round();
    final periodLens = _periodLengths(periods);
    final avgPeriod = periodLens.isEmpty
        ? AppConstants.defaultPeriodLength
        : (periodLens.reduce((a, b) => a + b) / periodLens.length)
            .round();
    final ovulationDay = avgCycle - AppConstants.defaultLutealPhase;

    String phase;
    String description;
    IconData phaseIcon;
    Color phaseColor;

    if (daysSinceStart < avgPeriod) {
      phase = AppConstants.phaseMenstrual;
      description =
          'Day ${daysSinceStart + 1} of your period. Your body is '
          'shedding the uterine lining. Rest and stay hydrated.';
      phaseIcon = Icons.water_drop;
      phaseColor = const Color(0xFFE91E63);
    } else if (daysSinceStart < ovulationDay - 2) {
      phase = AppConstants.phaseFollicular;
      description =
          'Your body is preparing for ovulation. Estrogen levels '
          'are rising, and energy typically increases.';
      phaseIcon = Icons.trending_up;
      phaseColor = const Color(0xFF4CAF50);
    } else if (daysSinceStart < ovulationDay + 2) {
      phase = AppConstants.phaseOvulation;
      description =
          'Around day $ovulationDay. This is your most fertile '
          'window. LH surge triggers egg release.';
      phaseIcon = Icons.egg_outlined;
      phaseColor = const Color(0xFFFF9800);
    } else {
      phase = AppConstants.phaseLuteal;
      final daysUntilPeriod = avgCycle - daysSinceStart;
      description =
          'Progesterone is dominant. ${daysUntilPeriod > 0 ? 'Estimated $daysUntilPeriod days until next period.' : 'Your period may start soon.'}';
      phaseIcon = Icons.nights_stay_outlined;
      phaseColor = const Color(0xFF9C27B0);
    }

    return _InsightCard(
      title: 'Cycle Phase Analysis',
      icon: Icons.donut_large_outlined,
      colorScheme: colorScheme,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: phaseColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(phaseIcon, color: phaseColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: phaseColor,
                          ),
                    ),
                    Text(
                      'Day ${daysSinceStart + 1} of ~$avgCycle',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (daysSinceStart / avgCycle).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colorScheme.surfaceVariant,
              color: phaseColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════
//  Shared Card Wrapper
// ═════════════════════════════════════════════════════════

class _InsightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme colorScheme;
  final Widget child;

  const _InsightCard({
    required this.title,
    required this.icon,
    required this.colorScheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
