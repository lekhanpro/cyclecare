import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../domain/entities/amenorrhea_result.dart';
import '../../../widgets/cycle_calendar.dart';
import '../../../widgets/cycle_summary_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/soft_card.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleTrackerControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, _) =>
              Center(child: Text('CycleCare could not load: $error')),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _Header(data: data),
              const SizedBox(height: 18),
              AmenorrheaBanner(periods: data.periods),
              const SizedBox(height: 18),
              CycleSummaryCard(
                prediction: data.prediction,
                onLogPeriod: () => ref
                    .read(cycleTrackerControllerProvider.notifier)
                    .logPeriodStart(DateTime.now()),
              ),
              const SizedBox(height: 18),
              if (data.prediction != null) ...[
                _PhaseIndicator(prediction: data.prediction!),
                const SizedBox(height: 18),
              ],
              CycleCalendar(
                compact: true,
                month: _month,
                selectedDate: data.selectedDate,
                statusFor: data.statusFor,
                hasLogFor: data.hasLogFor,
                onSelected:
                    ref.read(cycleTrackerControllerProvider.notifier).selectDate,
                onMonthChanged: (month) => setState(() => _month = month),
              ),
              const SizedBox(height: 18),
              _SelectedDayCard(data: data),
              const SizedBox(height: 18),
              _TodaySummaryCard(data: data),
              const SizedBox(height: 18),
              _AIInsightCard(data: data),
              const SizedBox(height: 18),
              _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});
  final CycleTrackerState data;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final name = data.preferences.profileName;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isNotEmpty ? '$greeting, $name 👋' : '$greeting 👋',
                style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A calm view of your cycle today.',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push(AppRoutes.settings),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '👤',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({required this.prediction});
  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final phases = [
      _PhaseInfo('Menstrual', AppColors.period, prediction.averagePeriodLength),
      _PhaseInfo(
        'Follicular',
        AppColors.info,
        (prediction.averageCycleLength - 14 - prediction.averagePeriodLength)
            .clamp(1, 40),
      ),
      _PhaseInfo('Ovulation', AppColors.ovulation, 3),
      _PhaseInfo('Luteal', AppColors.luteal, 11),
    ];

    int accumulated = 0;
    int activeIndex = 0;
    for (int i = 0; i < phases.length; i++) {
      accumulated += phases[i].days;
      if (prediction.cycleDay <= accumulated) {
        activeIndex = i;
        break;
      }
    }

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cycle phases',
            style: AppTextStyles.textTheme.labelMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                for (int i = 0; i < phases.length; i++)
                  Expanded(
                    flex: phases[i].days,
                    child: Container(
                      height: 8,
                      color: i == activeIndex
                          ? phases[i].color
                          : phases[i].color.withOpacity(0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < phases.length; i++)
                Text(
                  phases[i].name,
                  style: AppTextStyles.textTheme.labelSmall?.copyWith(
                    fontWeight:
                        i == activeIndex ? FontWeight.w800 : FontWeight.w500,
                    color: i == activeIndex ? AppColors.ink : AppColors.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.data});
  final CycleTrackerState data;

  @override
  Widget build(BuildContext context) {
    final log = data.logFor(DateTime.now());
    final parts = <String>[];
    if (log != null) {
      if (log.flow != null && log.flow != FlowIntensity.none) {
        parts.add('Flow: ${log.flow!.name}');
      }
      if (log.mood != null) parts.add('Mood: ${log.mood}');
      if (log.painLevel > 0) parts.add('Pain: ${log.painLevel}/10');
      if (log.waterMl > 0) parts.add('Water: ${log.waterMl} ml');
      if (log.sleepHours != null) {
        parts.add('Sleep: ${log.sleepHours!.toStringAsFixed(1)}h');
      }
    }
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's health summary",
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            parts.isEmpty
                ? 'No log yet today. A quick check-in helps predictions improve.'
                : parts.join(' · '),
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIInsightCard extends StatelessWidget {
  const _AIInsightCard({required this.data});
  final CycleTrackerState data;

  @override
  Widget build(BuildContext context) {
    final prediction = data.prediction;
    final message = prediction == null
        ? 'Add your last period to unlock gentle cycle insights.'
        : prediction.isLate
            ? 'Your period is later than expected. Cycle timing can shift with stress, illness, travel, and sleep changes. If you have concerns, speak with a healthcare provider.'
            : 'You are in the ${prediction.phase.toLowerCase()} phase. Your next period estimate adapts as you log more cycles.';

    return SoftCard(
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'CycleCare insight',
                style: AppTextStyles.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.aiChat),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('Ask AI'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            label: 'Log today',
            icon: Icons.add_rounded,
            onPressed: () => context.push(AppRoutes.log),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: 'Calendar',
            icon: Icons.calendar_month_rounded,
            outlined: true,
            onPressed: () => context.go(AppRoutes.calendar),
          ),
        ),
      ],
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({required this.data});
  final CycleTrackerState data;

  @override
  Widget build(BuildContext context) {
    final log = data.logFor(data.selectedDate);
    final status = data.statusFor(data.selectedDate);
    final statusText = switch (status) {
      DayStatus.period => 'Period day',
      DayStatus.predictedPeriod => 'Predicted period',
      DayStatus.fertile => 'Fertile window',
      DayStatus.ovulation => 'Estimated ovulation',
      DayStatus.normal => 'Normal cycle day',
    };
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shortDate(data.selectedDate),
            style: AppTextStyles.textTheme.labelMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (log != null &&
              (log.symptoms.isNotEmpty || log.notes.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (log.mood != null) log.mood!,
                if (log.symptoms.isNotEmpty) log.symptoms.join(', '),
                if (log.notes.isNotEmpty) log.notes,
              ].join(' · '),
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhaseInfo {
  const _PhaseInfo(this.name, this.color, this.days);
  final String name;
  final Color color;
  final int days;
}

class AmenorrheaBanner extends StatelessWidget {
  const AmenorrheaBanner({super.key, required this.periods});
  final List<CycleEvent> periods;

  @override
  Widget build(BuildContext context) {
    final result = _detect(periods);
    if (result == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _severityColor(result.severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _severityColor(result.severity).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: _severityColor(result.severity), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.severity.displayName,
                  style: AppTextStyles.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _severityColor(result.severity),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.description,
            style: AppTextStyles.textTheme.bodySmall?.copyWith(
              color: _severityColor(result.severity).withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This is a general observation, not a diagnosis. Please consult a healthcare professional if concerned.',
            style: AppTextStyles.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  AmenorrheaResult? _detect(List<CycleEvent> periods) {
    if (periods.isEmpty) return null;
    final sorted = List<CycleEvent>.from(periods)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final last = sorted.first;
    final daysSince = DateTime.now().difference(last.startDate).inDays;
    if (daysSince <= 45) return null;
    final severity = daysSince >= 180
        ? AmenorrheaSeverity.severe
        : daysSince >= 90
            ? AmenorrheaSeverity.moderate
            : AmenorrheaSeverity.mild;
    return AmenorrheaResult(
      severity: severity,
      daysSinceLastPeriod: daysSince,
      description:
          'It has been $daysSince days since your last logged period. ${severity.description}',
    );
  }

  Color _severityColor(AmenorrheaSeverity severity) => switch (severity) {
        AmenorrheaSeverity.none => Colors.green,
        AmenorrheaSeverity.mild => Colors.orange,
        AmenorrheaSeverity.moderate => Colors.deepOrange,
        AmenorrheaSeverity.severe => Colors.red,
      };
}
