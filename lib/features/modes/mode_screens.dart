import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import '../pregnancy/pregnancy_screen.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';
import 'tracking_mode.dart';

/// Goal changes affect presentation only. No record or pregnancy state is cleared.
Future<bool> showModeChange(
  BuildContext context,
  WidgetRef ref,
  TrackingGoal target,
) async {
  final before = ref.read(cycleTrackerControllerProvider).valueOrNull;
  if (before == null || before.preferences.goal == target) return false;
  final mode = describeTrackingMode(target);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Switch to ${target.label.toLowerCase()}?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${before.preferences.goal.label} → ${target.label}'),
            const SizedBox(height: 12),
            Text(mode.intro),
            const SizedBox(height: 12),
            for (final focus in mode.focus)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $focus'),
              ),
            const Text(
              'Your records, reminders and saved pregnancy details stay. All features remain available.',
            ),
            const SizedBox(height: 12),
            Text(modeBoundary(target)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep current mode'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm switch'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    final latest = ref.read(cycleTrackerControllerProvider).requireValue;
    await ref
        .read(cycleTrackerControllerProvider.notifier)
        .updatePreferences(latest.preferences.copyWith(goal: target));
    if (context.mounted) context.go('/mode-introduction');
    return true;
  } catch (_) {
    if (context.mounted) {
      showAppToast(
        context,
        message: 'Could not save the mode change. Please try again.',
        kind: ToastKind.error,
      );
    }
    return false;
  }
}

class ModeIntroductionScreen extends ConsumerWidget {
  const ModeIntroductionScreen({super.key, this.offerTour = false});
  final bool offerTour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleTrackerControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your tracking mode')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(cycleTrackerControllerProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (data) {
          final mode = describeTrackingMode(data.preferences.goal);
          return _ModePage(
            children: [
              Icon(
                mode.icon,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(mode.title, style: AppTextStyles.heading(fontSize: 32)),
              const SizedBox(height: 12),
              Text(mode.intro),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    for (final focus in mode.focus)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_rounded),
                        title: Text(focus),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                modeBoundary(data.preferences.goal),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Change your mode anytime in Settings. Your records stay.',
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: offerTour ? 'Continue' : 'Open my dashboard',
                onPressed: () => context.go(offerTour ? '/tour' : '/mode'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ModeDashboardScreen extends ConsumerWidget {
  const ModeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleTrackerControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My dashboard'),
        actions: [
          IconButton(
            tooltip: 'About my mode',
            onPressed: () => context.push('/mode-introduction'),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(cycleTrackerControllerProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (data) {
          final goal = data.preferences.goal;
          final mode = describeTrackingMode(goal);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final recent = data.logs
              .where(
                (l) =>
                    !l.date.isBefore(
                      today.subtract(const Duration(days: 29)),
                    ) &&
                    l.date.isBefore(today.add(const Duration(days: 1))),
              )
              .toList();
          final observations = [...data.logs]
            ..sort((a, b) => b.date.compareTo(a.date));
          final tests = observations
              .where((l) => l.ovulationTest != null)
              .toList();
          final temperatures = observations
              .where((l) => l.temperatureCelsius != null)
              .toList();
          return _ModePage(
            children: [
              Text(mode.title, style: AppTextStyles.heading(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                DateFormat.yMMMMd().format(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              if (goal == TrackingGoal.pregnancy)
                const _PregnancySummary()
              else if (goal == TrackingGoal.tryingToConceive)
                _SummaryCard(
                  title: 'Your recorded signs',
                  lines: [
                    tests.isEmpty
                        ? 'LH test: not logged'
                        : 'Latest LH: ${tests.first.ovulationTest} · ${DateFormat.MMMd().format(tests.first.date)}',
                    temperatures.isEmpty
                        ? 'Temperature: not logged'
                        : 'Latest BBT: ${temperatures.first.temperatureCelsius!.toStringAsFixed(2)} °C · ${DateFormat.MMMd().format(temperatures.first.date)}',
                  ],
                )
              else if (goal == TrackingGoal.trackPeriods)
                _SummaryCard(
                  title: 'Next period estimate',
                  lines: [
                    data.prediction == null
                        ? 'Log a period to see an estimate'
                        : DateFormat.yMMMd().format(
                            data.prediction!.nextPeriodStart,
                          ),
                    '${data.periods.length} recorded period starts',
                  ],
                )
              else if (goal == TrackingGoal.perimenopause)
                _SummaryCard(
                  title: 'Your recent observations',
                  lines: [
                    '${recent.length} days logged in the last 30 days',
                    '${recent.where((l) => l.sleepHours != null).length} days with sleep observations',
                    '${data.periods.length} recorded period starts',
                  ],
                )
              else
                _SummaryCard(
                  title: 'Your last 30 days',
                  lines: [
                    '${recent.length} days logged',
                    '${recent.where((l) => l.mood != null).length} days with mood observations',
                    '${recent.where((l) => l.symptoms.isNotEmpty).length} days with symptoms recorded',
                  ],
                ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: goal == TrackingGoal.pregnancy
                    ? 'Open pregnancy tracking'
                    : 'Log today',
                icon: goal == TrackingGoal.pregnancy
                    ? AppIcons.pregnancy
                    : AppIcons.notes,
                onPressed: () async {
                  if (goal == TrackingGoal.pregnancy) {
                    context.push('/pregnancy');
                    return;
                  }
                  try {
                    await ref
                        .read(cycleTrackerControllerProvider.notifier)
                        .selectDate(DateTime.now());
                    if (context.mounted) context.push('/log');
                  } catch (_) {
                    if (context.mounted)
                      showAppToast(
                        context,
                        message: 'Could not open today’s log. Try again.',
                        kind: ToastKind.error,
                      );
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                modeBoundary(goal),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              if (goal == TrackingGoal.tryingToConceive) ...[
                _link(
                  context,
                  'Fertility calendar',
                  'Estimates alongside recorded dates',
                  AppIcons.calendar,
                  '/calendar',
                ),
                _link(
                  context,
                  'Temperature & symptom trends',
                  'Review your observations and coverage',
                  AppIcons.insights,
                  '/insights',
                ),
              ] else if (goal == TrackingGoal.perimenopause) ...[
                _link(
                  context,
                  'Cycle changes & patterns',
                  'Variation and recorded symptom history',
                  AppIcons.insights,
                  '/insights',
                ),
                _link(
                  context,
                  'Health & pain diary',
                  'Keep a record for your care team',
                  Icons.health_and_safety_outlined,
                  '/health',
                ),
              ] else if (goal == TrackingGoal.symptomWellness) ...[
                _link(
                  context,
                  'Symptoms & wellbeing patterns',
                  'Based on observed days, with missing-data coverage',
                  AppIcons.insights,
                  '/insights',
                ),
                _link(
                  context,
                  'Pain diary',
                  'Levels, locations and activity impact',
                  Icons.health_and_safety_outlined,
                  '/health',
                ),
              ] else if (goal == TrackingGoal.pregnancy) ...[
                _link(
                  context,
                  'Daily observations',
                  'Mood, symptoms and other optional details',
                  AppIcons.notes,
                  '/log',
                ),
                _link(
                  context,
                  'Pregnancy reading',
                  'Browse the offline learning library',
                  Icons.menu_book_outlined,
                  '/education',
                ),
              ] else ...[
                _link(
                  context,
                  'Cycle calendar',
                  'Recorded dates and estimates',
                  AppIcons.calendar,
                  '/calendar',
                ),
                _link(
                  context,
                  'Cycle history & patterns',
                  'Lengths, variation and symptom observations',
                  AppIcons.insights,
                  '/insights',
                ),
              ],
              _link(
                context,
                'Cycle-health report',
                'Choose records and preview before sharing',
                AppIcons.notes,
                '/health-report',
              ),
              _link(
                context,
                'Reminders',
                'Your local schedules and permission status',
                AppIcons.reminders,
                '/reminders',
              ),
              _link(
                context,
                'Companion',
                'A quiet moment with your pet',
                AppIcons.petBunny,
                '/pet',
              ),
              _link(
                context,
                'All cycle tools',
                'Home, phase bar, windows and check-ins',
                AppIcons.home,
                '/home?cycle=1',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _link(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route,
  ) => ListRow(
    title: title,
    subtitle: subtitle,
    icon: icon,
    onTap: () => context.push(route),
  );
}

class _PregnancySummary extends ConsumerWidget {
  const _PregnancySummary();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(pregnancyProvider)
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const _SummaryCard(
          title: 'Pregnancy details unavailable',
          lines: ['Open pregnancy tracking to retry.'],
        ),
        data: (preg) => _SummaryCard(
          title: preg.isActive
              ? 'Week ${preg.weeksPregnant} + ${preg.dayOfWeek} days'
              : 'Start with your due date',
          lines: [
            if (preg.isActive && preg.dueDate != null)
              'Due ${DateFormat.yMMMd().format(preg.dueDate!)}'
            else
              'No pregnancy dates have been set.',
            if (preg.isActive)
              '${preg.kickCount} movements in the saved session',
          ],
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.lines});
  final String title;
  final List<String> lines;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        for (final line in lines)
          Padding(padding: const EdgeInsets.only(top: 10), child: Text(line)),
      ],
    ),
  );
}

class _ModePage extends StatelessWidget {
  const _ModePage({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}
