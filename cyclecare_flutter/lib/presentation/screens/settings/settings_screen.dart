import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    final mode = ref.watch(userModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // App Mode
          _buildSection(context, 'App Mode', [
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Current Mode'),
              subtitle: Text(_modeName(mode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showModeDialog(context, ref),
            ),
          ]),

          // Privacy & Security
          _buildSection(context, 'Privacy & Security', [
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('PIN Lock'),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric Lock'),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Privacy Mode'),
              subtitle: const Text('Hide in app switcher'),
              trailing: Switch(
                value: ref.watch(privacyModeProvider),
                onChanged: (v) => ref.read(privacyModeProvider.notifier).state = v,
              ),
            ),
          ]),

          // Notifications
          _buildSection(context, 'Notifications', [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Enable Notifications'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            const ListTile(
              leading: Icon(Icons.nightlight),
              title: Text('Quiet Hours'),
              subtitle: Text('22:00 - 07:00'),
            ),
          ]),

          // Cycle Settings
          _buildSection(context, 'Cycle Settings', [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Average Cycle Length'),
              subtitle: Text('${ref.watch(cycleLengthProvider)} days'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCycleLengthDialog(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop),
              title: const Text('Average Period Length'),
              subtitle: Text('${ref.watch(periodLengthProvider)} days'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPeriodLengthDialog(context, ref),
            ),
          ]),

          // Appearance
          _buildSection(context, 'Appearance', [
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              value: isDark,
              onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme & Colors'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/settings/theme'),
            ),
          ]),

          // Features
          _buildSection(context, 'Features', [
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Birth Control'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/birth-control'),
            ),
            if (mode == AppConstants.modePregnancy)
              ListTile(
                leading: const Icon(Icons.pregnant_woman),
                title: const Text('Pregnancy Dashboard'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/pregnancy'),
              ),
            ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: const Text('Health Conditions'),
              subtitle: const Text('PCOS, Endometriosis, PMDD'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/health/conditions'),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Education Library'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/education'),
            ),
          ]),

          // Cloud & Sharing
          _buildSection(context, 'Cloud & Sharing', [
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Backup & Restore'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/settings/backup'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Partner Sharing'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/partner'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Accounts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/settings/account'),
            ),
          ]),

          // Data
          _buildSection(context, 'Data', [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('CSV or JSON'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature - data will be exported')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete All Data', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete All Data?'),
                    content: const Text('This action cannot be undone. All your cycle, health, and tracking data will be permanently deleted.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All data deleted')),
                          );
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),

          // About
          _buildSection(context, 'About', [
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('Version'),
              subtitle: Text('1.0.0'),
            ),
            const ListTile(
              leading: Icon(Icons.privacy_tip),
              title: Text('Privacy Policy'),
              subtitle: Text('Your data stays on your device'),
            ),
            const ListTile(
              leading: Icon(Icons.medical_information),
              title: Text('Medical Disclaimer'),
              subtitle: Text('CycleCare is not a medical device. Predictions are estimates only.'),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _modeName(String mode) {
    switch (mode) {
      case AppConstants.modeTrackPeriods: return 'Track Periods';
      case AppConstants.modeTryingToConceive: return 'Trying to Conceive';
      case AppConstants.modePregnancy: return 'Pregnancy';
      case AppConstants.modePerimenopause: return 'Perimenopause';
      case AppConstants.modeAbstinence: return 'Abstinence';
      default: return 'Track Periods';
    }
  }

  void _showModeDialog(BuildContext context, WidgetRef ref) {
    final modes = [
      (AppConstants.modeTrackPeriods, 'Track Periods', 'Standard cycle tracking'),
      (AppConstants.modeTryingToConceive, 'Trying to Conceive', 'Fertility-focused tracking'),
      (AppConstants.modePregnancy, 'Pregnancy', 'Week-by-week pregnancy tracking'),
      (AppConstants.modePerimenopause, 'Perimenopause', 'Adapted for irregular cycles'),
      (AppConstants.modeAbstinence, 'Abstinence', 'Period-only, no fertility data'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Mode'),
        children: modes.map((m) => SimpleDialogOption(
          onPressed: () {
            ref.read(userModeProvider.notifier).state = m.$1;
            Navigator.pop(ctx);
          },
          child: ListTile(
            title: Text(m.$2),
            subtitle: Text(m.$3),
            leading: Radio<String>(
              value: m.$1,
              groupValue: ref.read(userModeProvider),
              onChanged: null,
            ),
          ),
        )).toList(),
      ),
    );
  }

  void _showCycleLengthDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        int value = ref.read(cycleLengthProvider);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Cycle Length'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$value days', style: Theme.of(context).textTheme.headlineMedium),
                Slider(
                  value: value.toDouble(),
                  min: 21,
                  max: 45,
                  divisions: 24,
                  label: '$value',
                  onChanged: (v) => setState(() => value = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  ref.read(cycleLengthProvider.notifier).state = value;
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPeriodLengthDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        int value = ref.read(periodLengthProvider);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Period Length'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$value days', style: Theme.of(context).textTheme.headlineMedium),
                Slider(
                  value: value.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  label: '$value',
                  onChanged: (v) => setState(() => value = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  ref.read(periodLengthProvider.notifier).state = value;
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
