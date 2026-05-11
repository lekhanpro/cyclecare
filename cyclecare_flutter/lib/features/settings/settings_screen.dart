import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/security_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../presentation/providers/app_providers.dart';
import '../../presentation/screens/education/education_screen.dart';
import '../../widgets/soft_card.dart';
import '../auth/sign_in_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../partner/partner_screen.dart';
import '../reminders/reminders_screen.dart';
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

            // Profile and mode
            _SettingsGroup(
              title: 'Profile',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.person, color: CycleCareColors.rose),
                  title: Text(
                    data.preferences.profileName.isEmpty
                        ? 'Optional profile'
                        : data.preferences.profileName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      data.preferences.goal.label,
                      if (data.preferences.profileBirthYear != null)
                        'Born ${data.preferences.profileBirthYear}',
                    ].join(' · '),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () => _editProfile(context, ref, data.preferences),
                ),
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

            // AI Assistant
            _SettingsGroup(
              title: 'AI Assistant',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable AI'),
                  subtitle: const Text('Chat with CycleCare AI for educational info'),
                  value: ref.watch(aiEnabledProvider),
                  activeColor: CycleCareColors.rose,
                  onChanged: (value) => ref.read(aiEnabledProvider.notifier).setEnabled(value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use personal data in AI'),
                  subtitle: const Text('Allow AI to see cycle summaries for personalization'),
                  value: ref.watch(aiUsePersonalDataProvider),
                  activeColor: CycleCareColors.rose,
                  onChanged: (value) => ref.read(aiUsePersonalDataProvider.notifier).setUsePersonalData(value),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.sparkles, color: CycleCareColors.rose),
                  title: const Text('Open AI chat', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Ask educational cycle-care questions'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AIChatScreen()),
                  ),
                ),
              ],
            ),

            _SettingsGroup(
              title: 'Education',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.book, color: CycleCareColors.rose),
                  title: const Text('Health library', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Cycle, fertility, pregnancy, and mood basics'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const EducationScreen()),
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
                  value: data.preferences.periodReminderEnabled,
                  activeColor: CycleCareColors.rose,
                  onChanged: (value) => _saveReminderToggle(
                    ref,
                    data.preferences.copyWith(periodReminderEnabled: value),
                    ReminderType.periodReminder,
                    value,
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ovulation reminders'),
                  subtitle: const Text('Around your estimated ovulation date'),
                  value: data.preferences.ovulationReminderEnabled,
                  activeColor: CycleCareColors.rose,
                  onChanged: (value) => _saveReminderToggle(
                    ref,
                    data.preferences.copyWith(ovulationReminderEnabled: value),
                    ReminderType.ovulationReminder,
                    value,
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily logging reminder'),
                  subtitle: const Text('A gentle check-in each day'),
                  value: data.preferences.dailyLogReminderEnabled,
                  activeColor: CycleCareColors.rose,
                  onChanged: (value) => _saveReminderToggle(
                    ref,
                    data.preferences.copyWith(dailyLogReminderEnabled: value),
                    ReminderType.dailyLogReminder,
                    value,
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pill or medicine reminder'),
                  subtitle: const Text('For daily medicine or birth control'),
                  value: data.preferences.pillReminderEnabled,
                  activeColor: CycleCareColors.rose,
                  onChanged: (value) => _saveReminderToggle(
                    ref,
                    data.preferences.copyWith(pillReminderEnabled: value),
                    ReminderType.pillReminder,
                    value,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.alarm, color: CycleCareColors.rose),
                  title: const Text('Manage Reminders', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Add custom reminders and adjust times'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: CycleCareColors.muted),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemindersScreen())),
                ),
              ],
            ),

            // Privacy & Security
            _SettingsGroup(
              title: 'Privacy & Security',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.lock_shield, color: CycleCareColors.rose),
                  title: const Text('Privacy explanation', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('What stays local and what AI may receive'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                  onTap: () => _showPrivacyDialog(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.lock, color: CycleCareColors.rose),
                  title: const Text('App Lock', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('PIN or biometric authentication'),
                  trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: CycleCareColors.muted),
                  onTap: () => _showAppLockDialog(context, ref),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hide in app switcher'),
                  subtitle: const Text('Mask app content in recent apps'),
                  value: ref.watch(privacyModeProvider),
                  activeColor: CycleCareColors.rose,
                  onChanged: (value) => ref.read(privacyModeProvider.notifier).setPrivacyMode(value),
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
                  subtitle: const Text('Export and share your local data'),
                  onTap: () async {
                    final export = await ref
                        .read(cycleTrackerControllerProvider.notifier)
                        .exportJson();
                    if (context.mounted) {
                      await Share.share(
                        export,
                        subject: 'CycleCare data export',
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

  Future<void> _saveReminderToggle(
    WidgetRef ref,
    CyclePreferences preferences,
    ReminderType type,
    bool enabled,
  ) async {
    _save(ref, preferences);
    final service = ref.read(notificationServiceProvider);
    final reminders = await service.loadReminders();
    final updated = reminders
        .map((reminder) =>
            reminder.type == type ? reminder.copyWith(enabled: enabled) : reminder)
        .toList();
    await service.saveReminders(updated);
    ref.invalidate(remindersProvider);
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    CyclePreferences preferences,
  ) async {
    final nameController = TextEditingController(text: preferences.profileName);
    final birthYearController = TextEditingController(
      text: preferences.profileBirthYear?.toString() ?? '',
    );
    var goal = preferences.goal;
    final updated = await showDialog<CyclePreferences>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name or nickname',
                    hintText: 'Optional',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: birthYearController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Birth year',
                    hintText: 'Optional',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TrackingGoal>(
                  value: goal,
                  decoration: const InputDecoration(labelText: 'Goal'),
                  items: [
                    for (final item in TrackingGoal.values)
                      DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => goal = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  ctx,
                  preferences.copyWith(
                    profileName: nameController.text.trim(),
                    profileBirthYear: int.tryParse(birthYearController.text.trim()),
                    goal: goal,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    birthYearController.dispose();
    if (updated != null) {
      _save(ref, updated);
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy in CycleCare'),
        content: const SingleChildScrollView(
          child: Text(
            'CycleCare is local-first. Your periods, daily logs, notes, symptoms, moods, and settings stay on this device unless you choose features that need network access.\n\n'
            'AI is optional. If you enable personal data for AI, CycleCare sends a short summary such as cycle day, prediction dates, recent moods, and symptom names. It does not need your full export or private notes to answer most questions.\n\n'
            'Partner sharing and cloud sync require Google/Firebase sign-in and are opt-in. You can revoke sharing, export local data, or delete local data from Settings.\n\n'
            'CycleCare is not a doctor and does not diagnose. For severe pain, very heavy bleeding, unusual symptoms, missed periods with concern, or anything serious, speak with a doctor, guardian, or trusted adult.',
            style: TextStyle(height: 1.4),
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

  Future<void> _showAppLockDialog(BuildContext context, WidgetRef ref) async {
    final security = ref.read(securityServiceProvider);
    final canBio = await security.canUseBiometric;
    final currentType = await security.lockType;
    if (!context.mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('App Lock'),
        content: const Text('Choose how to secure CycleCare.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final pin = await _askForPin(context);
              if (pin != null && pin.length >= 4) {
                await security.setPin(pin);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN lock enabled')));
                }
              }
            },
            child: const Text('Set PIN'),
          ),
          if (canBio)
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await security.authenticateWithBiometric();
                if (ok) {
                  await security.enableBiometricLock();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric lock enabled')));
                  }
                }
              },
              child: const Text('Use Biometric'),
            ),
          if (currentType != LockType.none)
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(ctx);
                await security.disableLock();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lock disabled')));
                }
              },
              child: const Text('Disable'),
            ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askForPin(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Enter PIN'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            placeholder: '4-6 digits',
          ),
        ),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
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
