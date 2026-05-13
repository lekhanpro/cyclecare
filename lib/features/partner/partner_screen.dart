import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  String? _inviteCode;
  bool _sharingEnabled = false;

  void _generateCode() {
    setState(() {
      _inviteCode = const Uuid().v4().substring(0, 8).toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Text('💑', style: TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 16),
          Text(
            'Share with a partner',
            textAlign: TextAlign.center,
            style: AppTextStyles.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite a trusted partner to view a read-only summary of your cycle.',
            textAlign: TextAlign.center,
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 32),

          // Sharing toggle
          SoftCard(
            child: SwitchListTile(
              title: const Text('Enable partner sharing'),
              subtitle: const Text('Your partner can see cycle phase and mood'),
              secondary: const Icon(Icons.share_rounded),
              value: _sharingEnabled,
              onChanged: (v) => setState(() => _sharingEnabled = v),
            ),
          ),
          const SizedBox(height: 16),

          if (_sharingEnabled) ...[
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite code',
                      style: AppTextStyles.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 12),
                  if (_inviteCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _inviteCode!,
                            style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _inviteCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Code copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Share this code with your partner. It expires in 24 hours.',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _generateCode,
                      child: const Text('Generate new code'),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: _generateCode,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Generate invite code'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // What partner can see
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What your partner can see',
                      style: AppTextStyles.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 12),
                  ...[
                    ('✅', 'Current cycle phase'),
                    ('✅', 'Days until next period'),
                    ('✅', 'Today\'s mood (if logged)'),
                    ('❌', 'Symptoms and health details'),
                    ('❌', 'BBT and cervical data'),
                    ('❌', 'Notes'),
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(item.$1),
                            const SizedBox(width: 8),
                            Text(item.$2,
                                style: AppTextStyles.textTheme.bodyMedium),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SoftCard(
            child: Text(
              '🔒 Your health data is private. Partner access is read-only and can be revoked at any time.',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
