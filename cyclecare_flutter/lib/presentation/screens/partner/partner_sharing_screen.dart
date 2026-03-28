import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PartnerSharingScreen extends ConsumerStatefulWidget {
  const PartnerSharingScreen({super.key});
  @override
  ConsumerState<PartnerSharingScreen> createState() => _PartnerSharingScreenState();
}

class _PartnerSharingScreenState extends ConsumerState<PartnerSharingScreen> {
  bool _hasPartner = false;
  String _inviteCode = '';
  bool _shareCyclePhase = true;
  bool _sharePeriodPrediction = true;
  bool _shareMoodSummary = false;
  bool _shareSymptoms = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Sharing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.people, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share a read-only dashboard with your partner. You control what they see.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!_hasPartner) ...[
            // Generate invite
            Center(
              child: Column(
                children: [
                  Icon(Icons.person_add, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No partner connected', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _inviteCode = const Uuid().v4().substring(0, 8).toUpperCase();
                        _hasPartner = true;
                      });
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Generate Invite Link'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Invite code display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Share this code with your partner:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_inviteCode,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          )),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Code'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sharing preferences
            Text('What your partner can see:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Cycle Phase'),
              subtitle: const Text('Current phase (menstrual, follicular, etc.)'),
              value: _shareCyclePhase,
              onChanged: (v) => setState(() => _shareCyclePhase = v),
            ),
            SwitchListTile(
              title: const Text('Period Prediction'),
              subtitle: const Text('Upcoming period date'),
              value: _sharePeriodPrediction,
              onChanged: (v) => setState(() => _sharePeriodPrediction = v),
            ),
            SwitchListTile(
              title: const Text('Mood Summary'),
              subtitle: const Text('General mood overview'),
              value: _shareMoodSummary,
              onChanged: (v) => setState(() => _shareMoodSummary = v),
            ),
            SwitchListTile(
              title: const Text('Symptoms'),
              subtitle: const Text('Symptom list'),
              value: _shareSymptoms,
              onChanged: (v) => setState(() => _shareSymptoms = v),
            ),
            const SizedBox(height: 16),

            // Revoke access
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Revoke Access'),
                      content: const Text('Your partner will no longer be able to see your data.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            setState(() {
                              _hasPartner = false;
                              _inviteCode = '';
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Revoke'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.link_off),
                label: const Text('Revoke Partner Access'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
