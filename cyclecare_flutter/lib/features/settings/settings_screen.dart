import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleTrackerControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: state.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            _SettingsGroup(
              title: 'Cycle defaults',
              children: [
                _StepperRow(
                  label: 'Cycle length',
                  value: data.preferences.averageCycleLength,
                  min: 21,
                  max: 45,
                  onChanged: (value) => _save(
                    ref,
                    data.preferences.copyWith(averageCycleLength: value),
                  ),
                ),
                _StepperRow(
                  label: 'Period length',
                  value: data.preferences.averagePeriodLength,
                  min: 2,
                  max: 10,
                  onChanged: (value) => _save(
                    ref,
                    data.preferences.copyWith(averagePeriodLength: value),
                  ),
                ),
                _StepperRow(
                  label: 'Luteal phase',
                  value: data.preferences.lutealPhaseLength,
                  min: 10,
                  max: 16,
                  onChanged: (value) => _save(
                    ref,
                    data.preferences.copyWith(lutealPhaseLength: value),
                  ),
                ),
              ],
            ),
            _SettingsGroup(
              title: 'Reminders',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Period reminders'),
                  subtitle: const Text('Notification scheduling is ready for a native pass.'),
                  value: data.preferences.remindersEnabled,
                  onChanged: (value) => _save(
                    ref,
                    data.preferences.copyWith(remindersEnabled: value),
                  ),
                ),
              ],
            ),
            _SettingsGroup(
              title: 'Data',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.square_arrow_down),
                  title: const Text('Export JSON'),
                  subtitle: const Text('Copies a local export preview to the app log path later.'),
                  onTap: () async {
                    final export = await ref
                        .read(cycleTrackerControllerProvider.notifier)
                        .exportJson();
                    if (context.mounted) {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Export preview'),
                          content: SingleChildScrollView(
                            child: Text(
                              export.length > 900 ? '${export.substring(0, 900)}...' : export,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                  title: const Text('Delete local data'),
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'CycleCare is not a medical device. Predictions are estimates and should not replace clinical advice.',
              style: TextStyle(color: CycleCareColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  void _save(WidgetRef ref, CyclePreferences preferences) {
    ref.read(cycleTrackerControllerProvider.notifier).updatePreferences(preferences);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete local data?'),
        content: const Text('This removes periods, logs, and preferences from this device.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cycleTrackerControllerProvider.notifier).deleteAllData();
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: CycleCareColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SoftCard(
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Decrease',
            onPressed: value <= min ? null : () => onChanged(value - 1),
            icon: const Icon(CupertinoIcons.minus_circle),
          ),
          SizedBox(
            width: 72,
            child: Text(
              '$value days',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: value >= max ? null : () => onChanged(value + 1),
            icon: const Icon(CupertinoIcons.plus_circle),
          ),
        ],
      ),
    );
  }
}
