import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';
import '../auth/sign_in_screen.dart';
import '../partner/partner_screen.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleTrackerControllerProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: state.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            // Account section
            _SettingsGroup(
              title: 'Account',
              children: [
                if (user != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: CycleCareColors.predicted,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Text(
                              (user.displayName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: CycleCareColors.rose,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.displayName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(user.email ?? ''),
                    trailing: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                      minSize: 0,
                      onPressed: () => _signOut(context, ref),
                      child: const Text(
                        'Sign out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: CycleCareColors.cream,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(CupertinoIcons.person_crop_circle,
                          color: CycleCareColors.muted),
                    ),
                    title: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Enable backup & partner sharing'),
                    trailing: const Icon(CupertinoIcons.chevron_right,
                        size: 16, color: CycleCareColors.muted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SignInScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),

            // Partner sharing
            _SettingsGroup(
              title: 'Partner',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.person_2,
                      color: CycleCareColors.rose),
                  title: const Text(
                    'Partner Sharing',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Share cycle data with your partner'),
                  trailing: const Icon(CupertinoIcons.chevron_right,
                      size: 16, color: CycleCareColors.muted),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PartnerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Cycle defaults
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

            // Reminders
            _SettingsGroup(
              title: 'Reminders',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Period reminders'),
                  subtitle: const Text('Get notified before your period'),
                  value: data.preferences.remindersEnabled,
                  activeColor: CycleCareColors.rose,
                  onChanged: (value) => _save(
                    ref,
                    data.preferences.copyWith(remindersEnabled: value),
                  ),
                ),
              ],
            ),

            // Data
            _SettingsGroup(
              title: 'Data',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.square_arrow_down),
                  title: const Text('Export JSON'),
                  subtitle: const Text('Export your local data'),
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
                              export.length > 900
                                  ? '${export.substring(0, 900)}...'
                                  : export,
                              style: const TextStyle(fontSize: 12),
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
                  subtitle: const Text('GDPR right to erasure'),
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),

            // Privacy
            const SizedBox(height: 10),
            const SoftCard(
              color: Color(0xFFFFFCFB),
              child: Row(
                children: [
                  Icon(CupertinoIcons.lock_shield,
                      color: CycleCareColors.muted, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All health data stays on this device. Sign-in only enables partner sharing and cloud backup.',
                      style: TextStyle(
                        color: CycleCareColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'CycleCare is not a medical device. Predictions are estimates and should not replace clinical advice.',
              style: TextStyle(color: CycleCareColors.muted, height: 1.35, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _save(WidgetRef ref, CyclePreferences preferences) {
    ref.read(cycleTrackerControllerProvider.notifier).updatePreferences(preferences);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your local data will remain on this device. Partner sharing will be paused.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete local data?'),
        content: const Text(
          'This permanently removes all periods, logs, and preferences from this device. This cannot be undone.',
        ),
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
