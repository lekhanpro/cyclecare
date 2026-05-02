import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/services/partner_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_card.dart';

class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myLink = ref.watch(myPartnerLinkProvider);
    final partnerLink = ref.watch(partnerLinkForMeProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partner Sharing')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.person_2,
                    size: 64, color: CycleCareColors.muted),
                const SizedBox(height: 20),
                const Text(
                  'Sign in required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: CycleCareColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Partner sharing requires a Google account to securely sync data between devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CycleCareColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: _loading ? 'Signing in...' : 'Sign in with Google',
                  icon: CupertinoIcons.person_crop_circle,
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          try {
                            await ref
                                .read(authServiceProvider)
                                .signInWithGoogle();
                          } catch (e) {
                            if (mounted) {
                              setState(() => _error = e.toString());
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _loading = false);
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Sharing')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          SoftCard(
            color: const Color(0xFFFFFCFB),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CycleCareColors.lavender.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(CupertinoIcons.person_2_fill,
                      color: CycleCareColors.rose),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Share a read-only view with your partner. You control exactly what they see.',
                    style: TextStyle(
                      color: CycleCareColors.ink,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // My invite link section (I'm the data owner)
          myLink.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (link) => link != null
                ? _OwnerLinkCard(
                    link: link,
                    onPermissionsChanged: (updated) =>
                        _updatePermissions(updated),
                    onRevoke: () => _revokeLink(link.inviteCode),
                  )
                : _CreateInviteCard(
                    loading: _loading,
                    onCreate: _createInvite,
                  ),
          ),
          const SizedBox(height: 18),

          // Partner link section (I'm the partner viewing someone's data)
          partnerLink.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (link) => link != null
                ? _PartnerViewCard(link: link)
                : _JoinPartnerCard(
                    controller: _codeController,
                    loading: _loading,
                    error: _error,
                    onJoin: _joinPartner,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvite() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(partnerServiceProvider).createInvite(user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create invite: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _joinPartner() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final link =
          await ref.read(partnerServiceProvider).acceptInvite(user, code);
      if (link == null && mounted) {
        setState(() => _error = 'Invalid code or already linked');
      } else if (mounted) {
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to partner!')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to connect');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updatePermissions(PartnerLink link) async {
    try {
      await ref.read(partnerServiceProvider).updatePermissions(link);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _revokeLink(String code) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Revoke access?'),
        content: const Text(
          'Your partner will lose access to your cycle data immediately.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(partnerServiceProvider).revokeLink(code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Revoke failed: $e')),
        );
      }
    }
  }
}

class _CreateInviteCard extends StatelessWidget {
  const _CreateInviteCard({required this.loading, required this.onCreate});

  final bool loading;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          const Icon(CupertinoIcons.link,
              size: 48, color: CycleCareColors.muted),
          const SizedBox(height: 14),
          const Text(
            'Share your cycle data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CycleCareColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Generate an invite code for your partner.',
            style: TextStyle(color: CycleCareColors.muted),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: loading ? 'Creating...' : 'Generate invite code',
            icon: CupertinoIcons.plus,
            onPressed: loading ? null : onCreate,
          ),
        ],
      ),
    );
  }
}

class _OwnerLinkCard extends StatelessWidget {
  const _OwnerLinkCard({
    required this.link,
    required this.onPermissionsChanged,
    required this.onRevoke,
  });

  final PartnerLink link;
  final ValueChanged<PartnerLink> onPermissionsChanged;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.link, color: CycleCareColors.rose),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Your invite code',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CycleCareColors.ink,
                  ),
                ),
              ),
              if (link.isLinked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CycleCareColors.fertile,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Connected',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: link.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: CycleCareColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    link.inviteCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: CycleCareColors.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(CupertinoIcons.doc_on_doc,
                      size: 18, color: CycleCareColors.muted),
                ],
              ),
            ),
          ),
          if (link.isLinked) ...[
            const SizedBox(height: 8),
            Text(
              'Partner: ${link.partnerDisplayName ?? 'Unknown'}',
              style: const TextStyle(
                color: CycleCareColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'What your partner can see:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: CycleCareColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          _PermissionSwitch(
            label: 'Cycle Phase',
            subtitle: 'Current phase (menstrual, follicular, etc.)',
            value: link.shareCyclePhase,
            onChanged: (v) =>
                onPermissionsChanged(link.copyWith(shareCyclePhase: v)),
          ),
          _PermissionSwitch(
            label: 'Period Prediction',
            subtitle: 'Next period date and countdown',
            value: link.sharePeriodPrediction,
            onChanged: (v) =>
                onPermissionsChanged(link.copyWith(sharePeriodPrediction: v)),
          ),
          _PermissionSwitch(
            label: 'Mood Summary',
            subtitle: 'General mood overview',
            value: link.shareMoodSummary,
            onChanged: (v) =>
                onPermissionsChanged(link.copyWith(shareMoodSummary: v)),
          ),
          _PermissionSwitch(
            label: 'Symptoms',
            subtitle: 'Logged symptom list',
            value: link.shareSymptoms,
            onChanged: (v) =>
                onPermissionsChanged(link.copyWith(shareSymptoms: v)),
          ),
          _PermissionSwitch(
            label: 'Flow',
            subtitle: 'Flow intensity',
            value: link.shareFlow,
            onChanged: (v) => onPermissionsChanged(link.copyWith(shareFlow: v)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(14),
              onPressed: onRevoke,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.xmark_circle,
                      size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Revoke access',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionSwitch extends StatelessWidget {
  const _PermissionSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CycleCareColors.ink,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CycleCareColors.muted,
                    )),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: CycleCareColors.rose,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _JoinPartnerCard extends StatelessWidget {
  const _JoinPartnerCard({
    required this.controller,
    required this.loading,
    required this.error,
    required this.onJoin,
  });

  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join a partner',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: CycleCareColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter the invite code your partner shared with you.',
            style: TextStyle(color: CycleCareColors.muted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
            decoration: InputDecoration(
              hintText: 'ABCD1234',
              errorText: error,
              hintStyle: TextStyle(
                color: CycleCareColors.muted.withOpacity(0.4),
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: loading ? 'Connecting...' : 'Connect',
            icon: CupertinoIcons.link,
            onPressed: loading ? null : onJoin,
          ),
        ],
      ),
    );
  }
}

class _PartnerViewCard extends StatelessWidget {
  const _PartnerViewCard({required this.link});

  final PartnerLink link;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: const Color(0xFFF5FFF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CycleCareColors.fertile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.heart_fill,
                    color: CycleCareColors.rose, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected to partner',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CycleCareColors.ink,
                      ),
                    ),
                    Text(
                      link.ownerDisplayName ?? 'Your partner',
                      style: const TextStyle(
                        color: CycleCareColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Tap the Partner tab on the home screen to view shared cycle data.',
            style: TextStyle(
              color: CycleCareColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
