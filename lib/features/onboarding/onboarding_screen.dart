import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_card.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';
import '../pet/pet_models.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  int _page = 0;
  DateTime _lastPeriod = DateTime.now().subtract(const Duration(days: 7));
  double _cycleLength = 28;
  double _periodLength = 5;
  TrackingGoal _goal = TrackingGoal.trackPeriods;
  PetType _petType = PetType.bunny;
  bool _saving = false;

  static const _totalPages = 5;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(cycleTrackerControllerProvider.notifier).completeOnboarding(
          lastPeriodStart: _lastPeriod,
          cycleLength: _cycleLength.round(),
          periodLength: _periodLength.round(),
          goal: _goal,
          profileName: _nameCtrl.text.trim(),
        );
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Text(
                    'CycleCare',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1}/$_totalPages',
                    style: AppTextStyles.textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_page + 1) / _totalPages,
                  minHeight: 4,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(nameCtrl: _nameCtrl),
                  _GoalPage(
                    selected: _goal,
                    onChanged: (g) => setState(() => _goal = g),
                  ),
                  _CycleLengthPage(
                    lastPeriod: _lastPeriod,
                    cycleLength: _cycleLength,
                    periodLength: _periodLength,
                    onLastPeriodChanged: (d) => setState(() => _lastPeriod = d),
                    onCycleLengthChanged: (v) => setState(() => _cycleLength = v),
                    onPeriodLengthChanged: (v) => setState(() => _periodLength = v),
                  ),
                  _PetPage(
                    selected: _petType,
                    onChanged: (p) => setState(() => _petType = p),
                  ),
                  _ReadyPage(goal: _goal, petType: _petType),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: PrimaryButton(
                        label: 'Back',
                        outlined: true,
                        onPressed: _back,
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _page == _totalPages - 1 ? 'Start CycleCare 🌸' : 'Continue',
                      loading: _saving,
                      onPressed: _next,
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
}

// ─── Page 1: Welcome ─────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.nameCtrl});
  final TextEditingController nameCtrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('🌸', style: TextStyle(fontSize: 72))),
          const SizedBox(height: 24),
          Text(
            'Welcome to CycleCare',
            style: AppTextStyles.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your private, offline-first cycle companion. Let\'s set things up.',
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your name (optional)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 24),
          SoftCard(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔒 Privacy first',
                    style: AppTextStyles.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                Text(
                  'All your data is stored locally on your device. No account required. You control what gets shared.',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.4,
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

// ─── Page 2: Goal ────────────────────────────────────────────────────────────
class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.selected, required this.onChanged});
  final TrackingGoal selected;
  final ValueChanged<TrackingGoal> onChanged;

  @override
  Widget build(BuildContext context) {
    final goals = [
      (TrackingGoal.trackPeriods, '🌸', 'Track my period'),
      (TrackingGoal.tryingToConceive, '🌿', 'Trying to conceive'),
      (TrackingGoal.pregnancy, '🤰', 'I\'m pregnant'),
      (TrackingGoal.perimenopause, '🌙', 'Perimenopause'),
      (TrackingGoal.symptomWellness, '💜', 'Symptom & wellness'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your goal?',
            style: AppTextStyles.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps CycleCare personalise your experience.',
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 24),
          ...goals.map((g) {
            final isSelected = selected == g.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                onTap: () => onChanged(g.$1),
                child: Row(
                  children: [
                    Text(g.$2, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        g.$3,
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Page 3: Cycle length ─────────────────────────────────────────────────────
class _CycleLengthPage extends StatelessWidget {
  const _CycleLengthPage({
    required this.lastPeriod,
    required this.cycleLength,
    required this.periodLength,
    required this.onLastPeriodChanged,
    required this.onCycleLengthChanged,
    required this.onPeriodLengthChanged,
  });

  final DateTime lastPeriod;
  final double cycleLength;
  final double periodLength;
  final ValueChanged<DateTime> onLastPeriodChanged;
  final ValueChanged<double> onCycleLengthChanged;
  final ValueChanged<double> onPeriodLengthChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your cycle',
            style: AppTextStyles.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'These are estimates — CycleCare will learn your pattern over time.',
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 24),

          // Last period
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last period start date',
                    style: AppTextStyles.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: lastPeriod,
                      firstDate: DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) onLastPeriodChanged(picked);
                  },
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(
                    '${lastPeriod.day}/${lastPeriod.month}/${lastPeriod.year}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cycle length
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cycle length',
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    Text('${cycleLength.round()} days',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        )),
                  ],
                ),
                Slider(
                  value: cycleLength,
                  min: 18,
                  max: 60,
                  divisions: 42,
                  label: '${cycleLength.round()} days',
                  onChanged: onCycleLengthChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Period length
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Period length',
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    Text('${periodLength.round()} days',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        )),
                  ],
                ),
                Slider(
                  value: periodLength,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${periodLength.round()} days',
                  onChanged: onPeriodLengthChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 4: Pet selection ────────────────────────────────────────────────────
class _PetPage extends StatelessWidget {
  const _PetPage({required this.selected, required this.onChanged});
  final PetType selected;
  final ValueChanged<PetType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your companion',
            style: AppTextStyles.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your pet grows with you as you track your health.',
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: PetType.values.map((p) {
              final isSelected = selected == p;
              return SoftCard(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                onTap: () => onChanged(p),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(p.name,
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Page 5: Ready ────────────────────────────────────────────────────────────
class _ReadyPage extends StatelessWidget {
  const _ReadyPage({required this.goal, required this.petType});
  final TrackingGoal goal;
  final PetType petType;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(petType.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text(
            "You're all set! 🎉",
            style: AppTextStyles.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'CycleCare is ready to help you understand your cycle.',
            textAlign: TextAlign.center,
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SoftCard(
            child: Text(
              '⚕️ CycleCare is for educational and personal tracking purposes only. It is not a medical device and does not provide medical advice. Always consult a healthcare professional for medical concerns.',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
