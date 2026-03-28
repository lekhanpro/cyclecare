import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            'Privacy & Security',
            [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('PIN Lock'),
                subtitle: const Text('Protect your data with a PIN'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Toggle PIN
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Biometric Lock'),
                subtitle: const Text('Use fingerprint or face ID'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Toggle biometric
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Privacy Mode'),
                subtitle: const Text('Hide sensitive information'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Toggle privacy mode
                  },
                ),
              ),
            ],
          ),
          
          _buildSection(
            context,
            'Notifications',
            [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Enable Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Toggle notifications
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.nightlight),
                title: const Text('Quiet Hours'),
                subtitle: const Text('22:00 - 07:00'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Toggle quiet hours
                  },
                ),
              ),
            ],
          ),
          
          _buildSection(
            context,
            'Cycle Settings',
            [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Average Cycle Length'),
                subtitle: const Text('28 days'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Edit cycle length
                },
              ),
              ListTile(
                leading: const Icon(Icons.water_drop),
                title: const Text('Average Period Length'),
                subtitle: const Text('5 days'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Edit period length
                },
              ),
            ],
          ),
          
          _buildSection(
            context,
            'Data',
            [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Data'),
                subtitle: const Text('Download your data as CSV'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Export data
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Delete All Data'),
                subtitle: const Text('Permanently delete all your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Delete data
                },
              ),
            ],
          ),
          
          _buildSection(
            context,
            'About',
            [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show privacy policy
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show terms
                },
              ),
            ],
          ),
        ],
      ),
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
