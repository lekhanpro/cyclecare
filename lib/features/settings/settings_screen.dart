import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/app_settings_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/services/security_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../features/tracking/application/cycle_tracker_controller.dart';
import '../../widgets/soft_card.dart';

final _securityProvider = Provider<SecurityService>((_) => SecurityService());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsSyncProvider);
    final trackerAsync = ref.watch(cycleTrackerControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile section
          trackerAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (tracker) => SoftCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        tracker.preferences.profileName.isNotEmpty
                            ? tracker.preferences.profileName[0].toUpperCase()
                            : '👤',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tracker.preferences.profileName.isNotEmpty
                              ? tracker.preferences.profileName
                              : 'Your Profile',
                          style: AppTextStyles.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Goal: ${tracker.preferences.goal.label}',
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Appearance
          _SectionHeader(title: 'Appearance'),
          SoftCard(
            child: Column(
              children: [
                // Dark mode
                SwitchListTile(
                  title: const Text('Dark mode'),
                  secondary: const Icon(Icons.dark_mode_rounded),
                  value: settings.isDark,
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).setDark(v),
                ),
                const Divider(height: 1),
                // Palette picker
                ListTile(
                  leading: const Icon(Icons.palette_rounded),
                  title: const Text('Color palette'),
                  subtitle: Text(settings.palette.label),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: settings.palette.seed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => _showPalettePicker(context, ref, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cycle settings
          _SectionHeader(title: 'Cycle'),
          SoftCard(
            child: Column(
              children: [
                trackerAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (tracker) => Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.loop_rounded),
                        title: const Text('Average cycle length'),
                        trailing: Text(
                          '${tracker.preferences.averageCycleLength} days',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        onTap: () => _editCycleLength(context, ref, tracker.preferences.averageCycleLength),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.water_drop_rounded),
                        title: const Text('Average period length'),
                        trailing: Text(
                          '${tracker.preferences.averagePeriodLength} days',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        onTap: () => _editPeriodLength(context, ref, tracker.preferences.averagePeriodLength),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Privacy & Security
          _SectionHeader(title: 'Privacy & Security'),
          SoftCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Privacy mode'),
                  subtitle: const Text('Hides content when app is in background'),
                  secondary: const Icon(Icons.visibility_off_rounded),
                  value: settings.privacyMode,
                  onChanged: (v) =>
                      ref.read(appSettingsProvider.notifier).setPrivacy(v),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: const Text('App lock (PIN / Biometric)'),
                  subtitle: const Text('Protect your health data'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showLockSettings(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // More features
          _SectionHeader(title: 'Features'),
          SoftCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pregnant_woman_rounded),
                  title: const Text('Pregnancy'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.pregnancy),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.medication_rounded),
                  title: const Text('Birth Control'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.birthControl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.people_rounded),
                  title: const Text('Partner'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.partner),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.health_and_safety_rounded),
                  title: const Text('Health Conditions'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.health),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_rounded),
                  title: const Text('Education'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.education),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data
          _SectionHeader(title: 'Data'),
          SoftCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('Export my data'),
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.error),
                  title: const Text('Delete all data',
                      style: TextStyle(color: AppColors.error)),
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About
          _SectionHeader(title: 'About'),
          SoftCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_rounded),
                  title: const Text('Version'),
                  trailing: Text('1.0.0',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      )),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_rounded),
                  title: const Text('Medical disclaimer'),
                  onTap: () => _showDisclaimer(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showPalettePicker(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose palette',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppPalette.values.map((p) {
                final selected = p == settings.palette;
                return GestureDetector(
                  onTap: () {
                    ref.read(appSettingsProvider.notifier).setPalette(p);
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: p.seed,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: p.seed.withOpacity(0.4),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(p.label,
                          style: AppTextStyles.textTheme.labelSmall),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _editCycleLength(
      BuildContext context, WidgetRef ref, int current) async {
    final result = await _showNumberPicker(
      context,
      title: 'Cycle length (days)',
      min: 18,
      max: 60,
      initial: current,
    );
    if (result != null) {
      final tracker = ref.read(cycleTrackerControllerProvider).valueOrNull;
      if (tracker != null) {
        await ref
            .read(cycleTrackerControllerProvider.notifier)
            .updatePreferences(
              tracker.preferences.copyWith(averageCycleLength: result),
            );
      }
    }
  }

  Future<void> _editPeriodLength(
      BuildContext context, WidgetRef ref, int current) async {
    final result = await _showNumberPicker(
      context,
      title: 'Period length (days)',
      min: 1,
      max: 10,
      initial: current,
    );
    if (result != null) {
      final tracker = ref.read(cycleTrackerControllerProvider).valueOrNull;
      if (tracker != null) {
        await ref
            .read(cycleTrackerControllerProvider.notifier)
            .updatePreferences(
              tracker.preferences.copyWith(averagePeriodLength: result),
            );
      }
    }
  }

  Future<int?> _showNumberPicker(
    BuildContext context, {
    required String title,
    required int min,
    required int max,
    required int initial,
  }) async {
    int selected = initial;
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$selected days',
                  style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
              Slider(
                value: selected.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: '$selected',
                onChanged: (v) => setState(() => selected = v.round()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final json = await ref
        .read(cycleTrackerControllerProvider.notifier)
        .exportJson();
    await Share.share(json, subject: 'CycleCare data export');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
            'This will permanently delete all your cycle data, logs, and settings. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cycleTrackerControllerProvider.notifier).deleteAllData();
    }
  }

  void _showLockSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _LockSettingsSheet(),
    );
  }

  void _showDisclaimer(BuildContext context) {    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Medical Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'CycleCare is a personal health tracking app designed for educational and informational purposes only. '
            'It is not a medical device and does not provide medical advice, diagnosis, or treatment.\n\n'
            'Cycle predictions are estimates based on your logged data and may not be accurate for everyone. '
            'Do not rely on CycleCare as a method of contraception.\n\n'
            'Always consult a qualified healthcare professional for medical concerns, diagnosis, or treatment decisions.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.textTheme.labelSmall?.copyWith(
          color: AppColors.muted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Lock Settings Sheet ──────────────────────────────────────────────────────
class _LockSettingsSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LockSettingsSheet> createState() => _LockSettingsSheetState();
}

class _LockSettingsSheetState extends ConsumerState<_LockSettingsSheet> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App Lock',
              style: AppTextStyles.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'New PIN (4–6 digits)',
              errorText: _error,
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _setPin,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Set PIN'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _disableLock,
                  child: const Text('Disable lock'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your PIN is stored securely on this device and never sent anywhere.',
            style: AppTextStyles.textTheme.bodySmall
                ?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _setPin() async {
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await SecurityService().setPin(pin);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN set. App lock is now enabled.')),
      );
    }
  }

  Future<void> _disableLock() async {
    await SecurityService().disableLock();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App lock disabled.')),
      );
    }
  }
}
