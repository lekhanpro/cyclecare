import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/widgets.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import 'application/partner_live_controller.dart';
import 'application/partner_sharing_controller.dart';
import 'data/partner_sync_models.dart';
import 'partner_hub_screen.dart';
import 'partner_view.dart';

const partnerFieldLabels = {
  'name': 'My name',
  'phase': 'Cycle phase & day',
  'next_period': 'Period estimate',
  'mood': 'Today’s mood',
  'symptoms': 'Today’s symptoms',
  'pain': 'Today’s pain',
  'fertile': 'Fertile-window estimate',
  'ovulation': 'Ovulation estimate',
  'pms': 'PMS-window estimate',
  'support_tip': 'Care suggestions',
  'note': 'My written note',
};

class PartnerLiveOwnerScreen extends ConsumerWidget {
  const PartnerLiveOwnerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(partnerLiveProvider);
    final state = async.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('My partner connections')),
      body: state == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'You choose the access',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pair once, then share only the fields and pages you enable. Updates send while CycleCare is open. You can stop future access at any time.',
                ),
                if (state.uploadsPaused)
                  const InfoBanner(
                    icon: Icons.pause_circle_outline,
                    title: 'Updates paused on this phone',
                    message:
                        'A previous deletion request paused automatic uploads. Save permissions or create a new invitation to explicitly resume updates.',
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: InfoBanner(
                      icon: Icons.error_outline,
                      title: 'Action needs attention',
                      message: state.error!,
                    ),
                  ),
                const SizedBox(height: 16),
                if (!state.configured || !state.signedIn)
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PartnerServerSetupScreen(),
                      ),
                    ),
                    child: const Text('Set up partner sync'),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: state.busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PartnerConsentScreen(),
                            ),
                          ),
                    icon: const Icon(Icons.add_link),
                    label: const Text('Invite my partner'),
                  ),
                  TextButton.icon(
                    onPressed: state.busy
                        ? null
                        : () =>
                              ref.read(partnerLiveProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check connections'),
                  ),
                  for (final link in state.links.where(
                    (l) => l.ownerId == state.userId,
                  ))
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            link.revoked
                                ? 'Access revoked'
                                : link.partnerId == null
                                ? 'Invitation pending'
                                : 'Partner connected',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Updated ${DateFormat('d MMM, HH:mm').format(link.updatedAt.toLocal())}',
                          ),
                          Text(
                            '${link.consent.fields.length} fields · ${link.consent.automaticUpdates ? 'automatic updates on' : 'updates paused'}',
                          ),
                          if (!link.revoked)
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => PartnerConsentScreen(
                                        connection: link,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Permissions & preview'),
                                ),
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () async {
                                          if (await confirmAction(
                                            context,
                                            title: 'Revoke partner access?',
                                            message:
                                                'Future server access stops and the server’s shared snapshot is deleted. Previously copied data and offline copies cannot be recalled.',
                                            confirmLabel: 'Revoke',
                                            destructive: true,
                                          ))
                                            await ref
                                                .read(
                                                  partnerLiveProvider.notifier,
                                                )
                                                .revoke(link.id);
                                        },
                                  child: const Text('Revoke access'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                const ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Privacy & timing'),
                  children: [
                    Text(
                      'Unselected fields never enter an update. The partner cannot edit your records. Revocation takes effect on the server immediately; a phone that is offline may retain its last received copy until it reconnects or that update expires. Previously exported copies cannot be remotely erased. Connections expire after 90 days; invitations expire after 24 hours and can be accepted once.',
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class PartnerConsentScreen extends ConsumerStatefulWidget {
  const PartnerConsentScreen({super.key, this.connection});
  final PartnerConnection? connection;
  @override
  ConsumerState<PartnerConsentScreen> createState() =>
      _PartnerConsentScreenState();
}

class _PartnerConsentScreenState extends ConsumerState<PartnerConsentScreen> {
  late Set<String> _fields = {...?widget.connection?.consent.fields};
  late bool _home = widget.connection?.consent.home ?? false;
  late bool _calendar = widget.connection?.consent.calendar ?? false;
  late bool _automatic = widget.connection?.consent.automaticUpdates ?? false;
  PartnerConsent get _consent => PartnerConsent(
    fields: _fields.toList(),
    home: _home,
    calendar: _calendar,
    automaticUpdates: _automatic,
  );
  Future<void> _preview() async {
    final data = ref.read(cycleTrackerControllerProvider).valueOrNull;
    if (data == null) return;
    final snapshot = partnerSnapshotForConsent(
      data,
      _automatic ? _consent : const PartnerConsent(),
      ref.read(partnerSharingProvider).note,
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              _automatic
                  ? 'Exact shared preview'
                  : 'Updates paused · no data sent',
            ),
          ),
          body: PartnerDashboard(snapshot: snapshot),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final notifier = ref.read(partnerLiveProvider.notifier);
    if (widget.connection != null) {
      if (await notifier.publish(widget.connection!, _consent) && mounted)
        Navigator.pop(context);
      return;
    }
    final invite = await notifier.invite(_consent);
    if (invite == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send this invitation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(invite.code),
              const SizedBox(height: 12),
              const Text(
                'Valid for 24 hours. Your partner opens their dashboard and chooses Connect with invitation. This code pairs one device; it does not contain health records.',
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: invite.code));
                  if (context.mounted)
                    showAppToast(context, message: 'Invitation copied');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy invitation'),
              ),
            ],
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
    if (mounted) Navigator.pop(context);
    // The coordinator also sends later record changes under this saved consent.
    await notifier.synchronizeOwner();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(partnerLiveProvider).valueOrNull ?? const PartnerLiveState();
    return Scaffold(
      appBar: AppBar(title: const Text('Partner permissions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Every switch starts private. Your partner sees only what you enable.',
          ),
          const SizedBox(height: 12),
          for (final field in partnerFieldLabels.entries)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(field.value),
              value: _fields.contains(field.key),
              onChanged: (value) => setState(
                () =>
                    value ? _fields.add(field.key) : _fields.remove(field.key),
              ),
            ),
          const Divider(),
          Text(
            'Pages they can open',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Partner Home'),
            value: _home,
            onChanged: (v) => setState(() => _home = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Partner Calendar'),
            value: _calendar,
            onChanged: (v) => setState(() => _calendar = v),
          ),
          const Text(
            'With Calendar only, shared updates contain only selected period and window estimates. Enable Home to share selected mood, pain, symptoms, name or notes.',
          ),
          const Text('Their own connection settings always remain accessible.'),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Send ongoing updates for these selected fields'),
            subtitle: const Text(
              'Updates go to the partner server when this app is open. This consent remains until changed or revoked.',
            ),
            value: _automatic,
            onChanged: (v) => setState(() => _automatic = v ?? false),
          ),
          TextButton.icon(
            onPressed: _preview,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview selected data'),
          ),
          if (state.error != null)
            InfoBanner(
              icon: Icons.error_outline,
              title: 'Could not save',
              message: state.error!,
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.busy ? null : _save,
            child: Text(
              state.busy
                  ? 'Saving…'
                  : widget.connection == null
                  ? 'Create invitation'
                  : 'Save permissions',
            ),
          ),
        ],
      ),
    );
  }
}
