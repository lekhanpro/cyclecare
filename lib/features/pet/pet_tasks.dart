import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../core/utils/date_helpers.dart';
import '../../widgets/widgets.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';
import 'pet_care.dart';
import 'pet_companion.dart';
import 'pet_models.dart';
import 'pet_provider.dart';

/// User-confirmed water observations. Each operation reads the latest log and
/// changes only its water field; repeated taps are serialized within this scope.
class PetTaskActions {
  PetTaskActions(this.ref);
  final Ref ref;
  Future<void> _queue = Future.value();

  Future<void> recordWater(int amountMl, {DateTime? now}) {
    if (amountMl <= 0 || amountMl > 10000) {
      return Future.error(ArgumentError.value(amountMl, 'amountMl'));
    }
    final next = _queue.then((_) async {
      final day = dateOnly(now ?? DateTime.now());
      final data = await ref.read(cycleTrackerControllerProvider.future);
      final existing = data.logFor(day) ?? DailyLog(date: day);
      final total = (existing.waterMl ?? 0) + amountMl;
      if (total > 10000)
        throw StateError(
          'The recorded daily total cannot exceed 10,000 ml. Edit the log to correct it.',
        );
      await ref
          .read(cycleTrackerControllerProvider.notifier)
          .saveLog(existing.copyWith(waterMl: total));
    });
    _queue = next.catchError((Object _) {});
    return next;
  }
}

final petTaskActionsProvider = Provider<PetTaskActions>(PetTaskActions.new);

class PetCareTasks extends ConsumerStatefulWidget {
  const PetCareTasks({super.key, required this.pet, required this.onReward});
  final PetState pet;
  final ValueChanged<PetAction> onReward;
  @override
  ConsumerState<PetCareTasks> createState() => _PetCareTasksState();
}

class _PetCareTasksState extends ConsumerState<PetCareTasks> {
  bool _busy = false;
  String? _failure;

  Future<void> _openLog() async {
    try {
      await ref
          .read(cycleTrackerControllerProvider.notifier)
          .selectDate(DateTime.now());
      if (mounted) context.go('/log');
    } catch (_) {
      if (mounted)
        setState(() => _failure = 'Could not open your log. Try again.');
    }
  }

  Future<void> _claim(PetGoal goal) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final result = await ref
          .read(petProvider.notifier)
          .claimCareGoal(goal.id);
      if (!mounted) return;
      if (result == PetClaimResult.awarded) {
        widget.onReward(PetAction.celebrate);
        showAppToast(context, message: '${goal.xp} XP claimed');
      } else {
        showAppToast(
          context,
          message: result == PetClaimResult.alreadyClaimed
              ? 'Today’s reward is already claimed.'
              : 'Record this in today’s log first.',
          kind: ToastKind.info,
        );
      }
    } catch (_) {
      if (mounted)
        setState(() => _failure = 'Could not save your reward. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _water() async {
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => const _WaterAmountDialog(),
    );
    if (amount == null || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(petTaskActionsProvider).recordWater(amount);
      if (mounted) {
        widget.onReward(PetAction.water);
        showAppToast(context, message: '$amount ml added to today’s log');
      }
    } catch (_) {
      if (mounted)
        setState(
          () => _failure =
              'Could not record the water amount. Check your log total and try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(cycleTrackerControllerProvider);
    return records.when(
      loading: () => const LinearProgressIndicator(
        semanticsLabel: 'Loading your care tasks',
      ),
      error: (_, __) => TextButton(
        onPressed: () => ref.invalidate(cycleTrackerControllerProvider),
        child: const Text('Try loading care tasks again'),
      ),
      data: (data) {
        final day = dateOnly(DateTime.now());
        final goals = recordedCareGoals(data.logFor(day));
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Small steps for you',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text('Optional recording goals. No targets or penalties.'),
              for (final goal in goals) ...[
                const Divider(height: 24),
                Text(goal.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  widget.pet.careClaims.contains(goalClaimKey(goal.id, day))
                      ? 'Reward claimed today'
                      : goal.done
                      ? 'Recorded · reward ready'
                      : 'Not recorded today',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _busy ? null : _openLog,
                      child: Text(goal.done ? 'Review log' : 'Record in log'),
                    ),
                    if (goal.id == 'water')
                      TextButton.icon(
                        onPressed: _busy ? null : _water,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add water'),
                      ),
                    if (goal.done &&
                        !widget.pet.careClaims.contains(
                          goalClaimKey(goal.id, day),
                        ))
                      FilledButton(
                        onPressed: _busy ? null : () => _claim(goal),
                        child: Text('Claim ${goal.xp} XP'),
                      ),
                  ],
                ),
              ],
              if (_failure != null)
                Text(
                  _failure!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('/reminders'),
                    icon: const Icon(AppIcons.reminders),
                    label: const Text('Reminders'),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/education'),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Learn'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterAmountDialog extends StatefulWidget {
  const _WaterAmountDialog();
  @override
  State<_WaterAmountDialog> createState() => _WaterAmountDialogState();
}

class _WaterAmountDialogState extends State<_WaterAmountDialog> {
  final _amount = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = int.tryParse(_amount.text.trim());
    if (value == null || value <= 0 || value > 10000) {
      setState(() => _error = 'Enter an amount from 1 to 10,000 ml.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Record water you’ve had'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose the amount to add to today’s recorded total. This is a record, not an intake recommendation.',
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('pet-water-amount'),
          controller: _amount,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount (ml)',
            errorText: _error,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _confirm, child: const Text('Confirm amount')),
    ],
  );
}
