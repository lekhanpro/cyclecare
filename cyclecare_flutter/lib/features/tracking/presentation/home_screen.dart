import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
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
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              const Text(
                'CycleCare',
                style: TextStyle(
                  color: CycleCareColors.ink,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'A calm view of your cycle today.',
                style: TextStyle(
                  color: CycleCareColors.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              CycleSummaryCard(
                prediction: data.prediction,
                onLogPeriod: () => ref
                    .read(cycleTrackerControllerProvider.notifier)
                    .logPeriodStart(DateTime.now()),
              ),
              const SizedBox(height: 18),
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
          ),
        ),
      ),
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
