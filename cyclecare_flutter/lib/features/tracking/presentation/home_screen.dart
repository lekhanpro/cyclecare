import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../core/services/partner_service.dart';
import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../domain/entities/amenorrhea_result.dart';
import '../../../widgets/cycle_calendar.dart';
import '../../../widgets/cycle_summary_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/soft_card.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_models.dart';
import 'log_screen.dart';

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
          error: (error, _) => Center(child: Text('CycleCare could not load: $error')),
          data: (data) {
            _pushSharedData(data);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CycleCare',
                            style: TextStyle(
                              color: CycleCareColors.ink,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A calm view of your cycle today.',
                            style: TextStyle(
                              color: CycleCareColors.muted,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _UserAvatar(),
                  ],
                ),
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
                  onSelected: ref.read(cycleTrackerControllerProvider.notifier).selectDate,
                  onMonthChanged: (month) => setState(() => _month = month),
                ),
                const SizedBox(height: 18),
                _SelectedDayCard(data: data),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Log symptoms',
                        icon: CupertinoIcons.plus,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LogScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _pushSharedData(CycleTrackerState data) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final prediction = data.prediction;
    if (prediction == null) return;
    final todayLog = data.logFor(DateTime.now());

    final shared = SharedCycleData(
      cycleDay: prediction.cycleDay,
      currentPhase: _phaseName(prediction),
      daysUntilPeriod: prediction.daysUntilPeriod,
      nextPeriodDate: shortDate(prediction.nextPeriodStart),
      mood: todayLog?.mood,
      symptoms: todayLog?.symptoms,
      flow: todayLog?.flow?.name,
      confidence: prediction.confidence,
    );

    ref.read(partnerServiceProvider).pushSharedData(user.uid, shared);
  }

  String _phaseName(CyclePrediction prediction) {
    final day = prediction.cycleDay;
    final cycleLen = prediction.averageCycleLength;
    final periodLen = prediction.averagePeriodLength;
    if (day <= periodLen) return 'Menstrual';
    if (day <= cycleLen - 14 - 1) return 'Follicular';
    if (day <= cycleLen - 14 + 1) return 'Ovulation';
    return 'Luteal';
  }
}

class _UserAvatar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: CycleCareColors.predicted,
        image: user.photoURL != null
            ? DecorationImage(
                image: NetworkImage(user.photoURL!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: user.photoURL == null
          ? Center(
              child: Text(
                (user.displayName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: CycleCareColors.rose,
                ),
              ),
            )
          : null,
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({required this.prediction});

  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final phases = [
      _PhaseInfo('Menstrual', CycleCareColors.rose, prediction.averagePeriodLength),
      _PhaseInfo('Follicular', CycleCareColors.mint,
          prediction.averageCycleLength - 14 - prediction.averagePeriodLength),
      _PhaseInfo('Ovulation', CycleCareColors.ovulation, 3),
      _PhaseInfo('Luteal', CycleCareColors.lavender, 11),
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
          const Text(
            'Cycle phases',
            style: TextStyle(
              color: CycleCareColors.muted,
              fontSize: 13,
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        i == activeIndex ? FontWeight.w800 : FontWeight.w500,
                    color: i == activeIndex
                        ? CycleCareColors.ink
                        : CycleCareColors.muted,
                  ),
                ),
            ],
          ),
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
        border: Border.all(color: _severityColor(result.severity).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _severityColor(result.severity), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.severity.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _severityColor(result.severity),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.description,
            style: TextStyle(
              color: _severityColor(result.severity).withOpacity(0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This is a general observation, not a diagnosis. Please consult a healthcare professional if you are concerned.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
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
      description: 'It has been $daysSince days since your last logged period. ${severity.description}',
    );
  }

  Color _severityColor(AmenorrheaSeverity severity) {
    return switch (severity) {
      AmenorrheaSeverity.mild => Colors.orange,
      AmenorrheaSeverity.moderate => Colors.deepOrange,
      AmenorrheaSeverity.severe => Colors.red,
    };
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
            style: const TextStyle(
              color: CycleCareColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: CycleCareColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (log != null && (log.symptoms.isNotEmpty || log.notes.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (log.mood != null) log.mood!,
                if (log.symptoms.isNotEmpty) log.symptoms.join(', '),
                if (log.notes.isNotEmpty) log.notes,
              ].join(' · '),
              style: const TextStyle(color: CycleCareColors.muted, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}
