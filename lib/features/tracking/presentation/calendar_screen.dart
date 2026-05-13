import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/cycle_calendar.dart';
import '../../../widgets/soft_card.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_models.dart';
import 'log_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
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
      appBar: AppBar(title: const Text('Calendar')),
      body: state.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            CycleCalendar(
              month: _month,
              selectedDate: data.selectedDate,
              statusFor: data.statusFor,
              hasLogFor: data.hasLogFor,
              onSelected: ref.read(cycleTrackerControllerProvider.notifier).selectDate,
              onMonthChanged: (month) => setState(() => _month = month),
            ),
            const SizedBox(height: 18),
            _DayDetail(data: data),
          ],
        ),
      ),
    );
  }
}

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.data});

  final CycleTrackerState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = data.logFor(data.selectedDate);
    final period = data.periodFor(data.selectedDate);
    final status = data.statusFor(data.selectedDate);
    final title = switch (status) {
      DayStatus.period => 'Recorded period',
      DayStatus.predictedPeriod => 'Predicted period',
      DayStatus.fertile => 'Fertile window',
      DayStatus.ovulation => 'Ovulation estimate',
      DayStatus.normal => 'No special marker',
    };
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shortDate(data.selectedDate),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            log == null
                ? 'No symptoms or notes logged for this day yet.'
                : [
                    if (log.flow != null) 'Flow: ${log.flow!.name}',
                    if (log.mood != null) 'Mood: ${log.mood}',
                    if (log.symptoms.isNotEmpty) 'Symptoms: ${log.symptoms.join(', ')}',
                    if (log.painLevel > 0) 'Pain: ${log.painLevel}/10',
                    if (log.temperatureCelsius != null)
                      'Temp: ${log.temperatureCelsius!.toStringAsFixed(1)} C',
                    if (log.weightKg != null)
                      'Weight: ${log.weightKg!.toStringAsFixed(1)} kg',
                    if (log.notes.isNotEmpty) 'Notes: ${log.notes}',
                  ].join('\n'),
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.45,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const LogScreen()),
                  );
                },
                icon: const Icon(CupertinoIcons.pencil),
                label: Text(log == null ? 'Add log' : 'Edit log'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final controller = ref.read(cycleTrackerControllerProvider.notifier);
                  final start = data.selectedDate;
                  controller.upsertPeriod(
                    existingId: period?.id,
                    startDate: period?.startDate ?? start,
                    endDate: period?.endDate ??
                        start.add(Duration(days: data.preferences.averagePeriodLength - 1)),
                  );
                },
                icon: const Icon(Icons.water_drop),
                label: Text(period == null ? 'Add period' : 'Update period'),
              ),
              if (period != null)
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(cycleTrackerControllerProvider.notifier)
                        .deletePeriod(period.id);
                  },
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Delete period'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
