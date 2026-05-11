import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../core/services/notification_service.dart';
import '../../presentation/providers/app_providers.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_card.dart';
import '../app/main_shell.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _birthYearController = TextEditingController();
  int _page = 0;
  DateTime _lastPeriod = DateTime.now().subtract(const Duration(days: 7));
  double _cycleLength = 28;
  double _periodLength = 5;
  bool _periodReminder = true;
  bool _ovulationReminder = false;
  bool _dailyReminder = false;
  bool _pillReminder = false;
  TrackingGoal _goal = TrackingGoal.trackPeriods;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CycleTrackerState>>(
      cycleTrackerControllerProvider,
      (_, next) {
        if (next.valueOrNull?.preferences.onboardingCompleted == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const MainShell()),
            (_) => false,
          );
        }
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
              child: Row(
                children: [
                  const Text(
                    'CycleCare',
                    style: TextStyle(
                      color: CycleCareColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1}/5',
                    style: const TextStyle(
                      color: CycleCareColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_page + 1) / 5,
                  minHeight: 6,
                  color: CycleCareColors.rose,
                  backgroundColor: CycleCareColors.line,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  const _WelcomeStep(),
                  _DateStep(
                    lastPeriod: _lastPeriod,
                    onPick: _pickDate,
                  ),
                  _LengthsStep(
                    cycleLength: _cycleLength,
                    periodLength: _periodLength,
                    onCycleChanged: (value) => setState(() => _cycleLength = value),
                    onPeriodChanged: (value) => setState(() => _periodLength = value),
                  ),
                  _RemindersStep(
                    periodReminder: _periodReminder,
                    ovulationReminder: _ovulationReminder,
                    dailyReminder: _dailyReminder,
                    pillReminder: _pillReminder,
                    onPeriodChanged: (value) => setState(() => _periodReminder = value),
                    onOvulationChanged: (value) => setState(() => _ovulationReminder = value),
                    onDailyChanged: (value) => setState(() => _dailyReminder = value),
                    onPillChanged: (value) => setState(() => _pillReminder = value),
                  ),
                  _ProfileStep(
                    goal: _goal,
                    nameController: _nameController,
                    birthYearController: _birthYearController,
                    onGoalChanged: (value) => setState(() => _goal = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: _previous,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 72),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: _page == 4 ? 'Start tracking' : 'Continue',
                      icon: _page == 4 ? CupertinoIcons.heart : CupertinoIcons.arrow_right,
                      onPressed: _page == 4 ? _finish : _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriod,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lastPeriod = picked);
    }
  }

  Future<void> _finish() async {
    final birthYear = int.tryParse(_birthYearController.text.trim());
    await ref.read(cycleTrackerControllerProvider.notifier).completeOnboarding(
          lastPeriodStart: _lastPeriod,
          cycleLength: _cycleLength.round(),
          periodLength: _periodLength.round(),
          goal: _goal,
          profileName: _nameController.text.trim(),
          profileBirthYear: birthYear,
          periodReminderEnabled: _periodReminder,
          ovulationReminderEnabled: _ovulationReminder,
          dailyLogReminderEnabled: _dailyReminder,
          pillReminderEnabled: _pillReminder,
        );
    final notificationService = ref.read(notificationServiceProvider);
    final reminders = await notificationService.loadReminders();
    final updated = reminders.map((reminder) {
      final enabled = switch (reminder.type) {
        ReminderType.periodReminder => _periodReminder,
        ReminderType.ovulationReminder => _ovulationReminder,
        ReminderType.fertileWindowReminder => _ovulationReminder,
        ReminderType.dailyLogReminder => _dailyReminder,
        ReminderType.pillReminder => _pillReminder,
        ReminderType.customReminder => reminder.enabled,
      };
      return reminder.copyWith(enabled: enabled);
    }).toList();
    await notificationService.saveReminders(updated);
    ref.invalidate(remindersProvider);
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      children: [
        Text(
          title,
          style: const TextStyle(
            color: CycleCareColors.ink,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: CycleCareColors.muted,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 22),
        child,
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Private cycle care, made gentle.',
      subtitle:
          'CycleCare estimates your cycle from what you choose to log. Your health data stays local by default.',
      child: Column(
        children: const [
          _PrivacyPoint(
            icon: CupertinoIcons.lock_shield,
            title: 'Local-first',
            text: 'Your period, mood, symptom, and note history is stored on this device unless you opt into sync.',
          ),
          SizedBox(height: 12),
          _PrivacyPoint(
            icon: CupertinoIcons.sparkles,
            title: 'AI is optional',
            text: 'You decide whether AI can use cycle summaries. It is educational and never a doctor.',
          ),
          SizedBox(height: 12),
          _PrivacyPoint(
            icon: CupertinoIcons.trash,
            title: 'Your control',
            text: 'Export your data or delete it from Settings whenever you want.',
          ),
        ],
      ),
    );
  }
}

class _DateStep extends StatelessWidget {
  const _DateStep({
    required this.lastPeriod,
    required this.onPick,
  });

  final DateTime lastPeriod;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'When did your last period start?',
      subtitle: 'This anchors your first prediction. You can edit period history later.',
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last period start',
              style: TextStyle(
                color: CycleCareColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onPick,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CycleCareColors.cream,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${lastPeriod.month}/${lastPeriod.day}/${lastPeriod.year}',
                  style: const TextStyle(
                    color: CycleCareColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LengthsStep extends StatelessWidget {
  const _LengthsStep({
    required this.cycleLength,
    required this.periodLength,
    required this.onCycleChanged,
    required this.onPeriodChanged,
  });

  final double cycleLength;
  final double periodLength;
  final ValueChanged<double> onCycleChanged;
  final ValueChanged<double> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Your usual timing',
      subtitle: 'If you are not sure, the defaults are a good starting point.',
      child: Column(
        children: [
          _SliderCard(
            label: 'Average cycle length',
            value: cycleLength,
            min: 21,
            max: 45,
            onChanged: onCycleChanged,
          ),
          const SizedBox(height: 14),
          _SliderCard(
            label: 'Average period length',
            value: periodLength,
            min: 2,
            max: 10,
            onChanged: onPeriodChanged,
          ),
        ],
      ),
    );
  }
}

class _RemindersStep extends StatelessWidget {
  const _RemindersStep({
    required this.periodReminder,
    required this.ovulationReminder,
    required this.dailyReminder,
    required this.pillReminder,
    required this.onPeriodChanged,
    required this.onOvulationChanged,
    required this.onDailyChanged,
    required this.onPillChanged,
  });

  final bool periodReminder;
  final bool ovulationReminder;
  final bool dailyReminder;
  final bool pillReminder;
  final ValueChanged<bool> onPeriodChanged;
  final ValueChanged<bool> onOvulationChanged;
  final ValueChanged<bool> onDailyChanged;
  final ValueChanged<bool> onPillChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Helpful reminders',
      subtitle: 'You can tune exact times and custom reminders later.',
      child: SoftCard(
        child: Column(
          children: [
            _ReminderSwitch(
              title: 'Period reminder',
              subtitle: 'A few days before your estimate',
              value: periodReminder,
              onChanged: onPeriodChanged,
            ),
            _ReminderSwitch(
              title: 'Ovulation reminder',
              subtitle: 'Around estimated ovulation',
              value: ovulationReminder,
              onChanged: onOvulationChanged,
            ),
            _ReminderSwitch(
              title: 'Daily logging reminder',
              subtitle: 'A gentle evening check-in',
              value: dailyReminder,
              onChanged: onDailyChanged,
            ),
            _ReminderSwitch(
              title: 'Pill or medicine reminder',
              subtitle: 'Useful if you take daily medication',
              value: pillReminder,
              onChanged: onPillChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.goal,
    required this.nameController,
    required this.birthYearController,
    required this.onGoalChanged,
  });

  final TrackingGoal goal;
  final TextEditingController nameController;
  final TextEditingController birthYearController;
  final ValueChanged<TrackingGoal> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Personalize your space',
      subtitle: 'These are optional and can be changed in Settings.',
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name or nickname',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: birthYearController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'Birth year',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Goal',
              style: TextStyle(
                color: CycleCareColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in TrackingGoal.values)
                  ChoiceChip(
                    label: Text(value.label),
                    selected: goal == value,
                    onSelected: (_) => onGoalChanged(value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CycleCareColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${value.round()} days',
            style: const TextStyle(
              color: CycleCareColors.rose,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            label: '${value.round()}',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CycleCareColors.rose),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CycleCareColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: CycleCareColors.muted,
                    height: 1.35,
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

class _ReminderSwitch extends StatelessWidget {
  const _ReminderSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      activeColor: CycleCareColors.rose,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
