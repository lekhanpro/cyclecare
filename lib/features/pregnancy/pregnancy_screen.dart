import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';

// ─── State ────────────────────────────────────────────────────────────────────
class PregnancyState {
  const PregnancyState({
    this.isActive = false,
    this.dueDate,
    this.kickCount = 0,
    this.lastKickSession,
  });

  final bool isActive;
  final DateTime? dueDate;
  final int kickCount;
  final DateTime? lastKickSession;

  int get weeksPregnant {
    if (dueDate == null) return 0;
    final conception = dueDate!.subtract(const Duration(days: 280));
    final diff = DateTime.now().difference(conception).inDays;
    return (diff / 7).floor().clamp(0, 42);
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays.clamp(0, 280);
  }
}

class PregnancyNotifier extends AsyncNotifier<PregnancyState> {
  static const _activeKey = 'cc.preg.active';
  static const _dueDateKey = 'cc.preg.dueDate';
  static const _kickKey = 'cc.preg.kicks';

  @override
  Future<PregnancyState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(_activeKey) ?? false;
    final dueDateStr = prefs.getString(_dueDateKey);
    final kicks = prefs.getInt(_kickKey) ?? 0;
    return PregnancyState(
      isActive: active,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      kickCount: kicks,
    );
  }

  Future<void> activate(DateTime dueDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, true);
    await prefs.setString(_dueDateKey, dueDate.toIso8601String());
    state = AsyncData(PregnancyState(isActive: true, dueDate: dueDate));
  }

  Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, false);
    state = const AsyncData(PregnancyState());
  }

  Future<void> logKick() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.valueOrNull ?? const PregnancyState();
    final newCount = current.kickCount + 1;
    await prefs.setInt(_kickKey, newCount);
    state = AsyncData(PregnancyState(
      isActive: current.isActive,
      dueDate: current.dueDate,
      kickCount: newCount,
      lastKickSession: DateTime.now(),
    ));
  }

  Future<void> resetKicks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kickKey, 0);
    final current = state.valueOrNull ?? const PregnancyState();
    state = AsyncData(PregnancyState(
      isActive: current.isActive,
      dueDate: current.dueDate,
      kickCount: 0,
    ));
  }
}

final pregnancyProvider =
    AsyncNotifierProvider<PregnancyNotifier, PregnancyState>(
  PregnancyNotifier.new,
);

// ─── Screen ───────────────────────────────────────────────────────────────────
class PregnancyScreen extends ConsumerWidget {
  const PregnancyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregAsync = ref.watch(pregnancyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pregnancy')),
      body: pregAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (preg) => preg.isActive
            ? _ActivePregnancyView(preg: preg)
            : _SetupView(),
      ),
    );
  }
}

class _SetupView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends ConsumerState<_SetupView> {
  DateTime? _selectedDue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        const Center(
          child: Text('🤰', style: TextStyle(fontSize: 80)),
        ),
        const SizedBox(height: 24),
        Text(
          'Pregnancy Mode',
          textAlign: TextAlign.center,
          style: AppTextStyles.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your pregnancy journey week by week.',
          textAlign: TextAlign.center,
          style: AppTextStyles.textTheme.bodyLarge?.copyWith(
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 32),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter your due date',
                  style: AppTextStyles.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 180)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 300)),
                  );
                  if (picked != null) setState(() => _selectedDue = picked);
                },
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(_selectedDue == null
                    ? 'Pick due date'
                    : DateFormat('MMM d, yyyy').format(_selectedDue!)),
              ),
              if (_selectedDue != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref
                      .read(pregnancyProvider.notifier)
                      .activate(_selectedDue!),
                  child: const Text('Start pregnancy tracking'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftCard(
          child: Text(
            '⚕️ CycleCare is not a medical device. Always follow your healthcare provider\'s guidance during pregnancy.',
            style: AppTextStyles.textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivePregnancyView extends ConsumerWidget {
  const _ActivePregnancyView({required this.preg});
  final PregnancyState preg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final weeks = preg.weeksPregnant;
    final daysLeft = preg.daysUntilDue;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primaryContainer, scheme.secondaryContainer],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text('Week $weeks', style: AppTextStyles.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
              Text('of pregnancy', style: AppTextStyles.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoChip(label: 'Days left', value: '$daysLeft'),
                  _InfoChip(
                    label: 'Due date',
                    value: preg.dueDate != null
                        ? DateFormat('MMM d').format(preg.dueDate!)
                        : '—',
                  ),
                  _InfoChip(label: 'Trimester', value: _trimester(weeks)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Kick counter
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kick Counter',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${preg.kickCount} kicks',
                      style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () =>
                        ref.read(pregnancyProvider.notifier).logKick(),
                    child: const Text('+ Kick'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(pregnancyProvider.notifier).resetKicks(),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Aim for 10 kicks in 2 hours. Contact your provider if movement decreases significantly.',
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Week info
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Week $weeks highlights',
                  style: AppTextStyles.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 8),
              Text(
                _weekInfo(weeks),
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: () =>
              ref.read(pregnancyProvider.notifier).deactivate(),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Exit pregnancy mode'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  String _trimester(int weeks) {
    if (weeks <= 13) return '1st';
    if (weeks <= 26) return '2nd';
    return '3rd';
  }

  String _weekInfo(int weeks) {
    if (weeks < 4) return 'Very early pregnancy. The embryo is implanting.';
    if (weeks < 8) return 'Major organs are beginning to form. Morning sickness may start.';
    if (weeks < 12) return 'The embryo becomes a fetus. Heartbeat is detectable.';
    if (weeks < 16) return 'Baby can make facial expressions. You may start showing.';
    if (weeks < 20) return 'You may feel the first movements (quickening).';
    if (weeks < 24) return 'Baby\'s hearing is developing. Viability milestone approaching.';
    if (weeks < 28) return 'Baby opens eyes. Brain development is rapid.';
    if (weeks < 32) return 'Baby is practicing breathing movements.';
    if (weeks < 36) return 'Baby is gaining weight rapidly. Getting into position.';
    if (weeks < 40) return 'Full term! Baby could arrive any day.';
    return 'Past due date. Stay in close contact with your healthcare provider.';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            )),
        Text(label,
            style: AppTextStyles.textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
            )),
      ],
    );
  }
}
