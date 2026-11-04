import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'application/partner_live_controller.dart';
import 'data/partner_sync_repository.dart';
import 'partner_screen.dart';
import 'partner_receiver_screen.dart';
import 'partner_live_owner_screen.dart';

class PartnerHubScreen extends StatelessWidget {
  const PartnerHubScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Together')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'A space for support',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(AppIcons.partnerPair, size: 40),
              const SizedBox(height: 16),
              Text(
                'I’m supporting someone',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your own read-only dashboard for the updates they choose to share.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PartnerReceiverScreen(),
                  ),
                ),
                child: const Text('Open partner dashboard'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'I’m sharing my updates',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose fields and pages. Connect two phones or send a one-off update.',
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PartnerLiveOwnerScreen(),
                  ),
                ),
                child: const Text('Manage partner connection'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PartnerScreen(),
                  ),
                ),
                child: const Text('Send a one-off snapshot'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PartnerServerSetupScreen extends ConsumerStatefulWidget {
  const PartnerServerSetupScreen({super.key});
  @override
  ConsumerState<PartnerServerSetupScreen> createState() =>
      _PartnerServerSetupScreenState();
}

class _PartnerServerSetupScreenState
    extends ConsumerState<PartnerServerSetupScreen> {
  final _url = TextEditingController(
    text: 'https://wjulenqvpfectkuguwny.supabase.co',
  );
  final _key = TextEditingController();
  bool _agreed = false;
  bool _seeded = false;
  @override
  void initState() {
    super.initState();
    final config = ref.read(partnerSyncRepositoryProvider).configuration;
    if (config != null) {
      _url.text = config.url;
      _key.text = config.publicKey;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ok = await ref
        .read(partnerLiveProvider.notifier)
        .connect(PartnerServerConfig(_url.text.trim(), _key.text.trim()));
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(partnerLiveProvider).valueOrNull ?? const PartnerLiveState();
    if (!_seeded && state.configured) {
      final configuration = ref
          .read(partnerSyncRepositoryProvider)
          .configuration;
      if (configuration != null) {
        _url.text = configuration.url;
        _key.text = configuration.publicKey;
        _seeded = true;
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Connect this device')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'A paired connection uses an authenticated device session. Your tracking stays offline until you separately enable sharing.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Partner server URL'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _key,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Publishable / anon key',
              helperText:
                  'Public key only. Never enter a secret or service-role key.',
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            title: const Text('Create a device session on this partner server'),
            subtitle: const Text(
              'The server receives your connection and network address. Pairing and health-field consent are separate steps.',
            ),
          ),
          if (state.error != null)
            InfoBanner(
              icon: Icons.error_outline,
              title: 'Connection not ready',
              message: state.error!,
            ),
          if (state.error != null && state.signedIn)
            TextButton(
              onPressed: state.busy || !_agreed
                  ? null
                  : () async {
                      final confirmed = await confirmAction(
                        context,
                        title: 'Create a new device identity?',
                        message:
                            'This forgets the current session. Existing connections belong to the old identity and may no longer be manageable from this phone. Their server permissions are not revoked by forgetting the session. Keep this identity if you still need to revoke access, or ask your server administrator to help.',
                        confirmLabel: 'Forget identity',
                        destructive: true,
                      );
                      if (!confirmed || !mounted) return;
                      await ref
                          .read(partnerSyncRepositoryProvider)
                          .forgetLocalSession();
                      await _connect();
                    },
              child: const Text('Reauthorize with a new device identity'),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.busy || !_agreed ? null : _connect,
            child: Text(state.busy ? 'Connecting…' : 'Connect device'),
          ),
          const SizedBox(height: 16),
          const ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Connection details'),
            children: [
              Text(
                'The server must have CycleCare’s partner migration and anonymous sign-in enabled. Session tokens stay in secure device storage. Uninstalling can lose this anonymous identity; keep access to this device if you need to revoke a connection. No service-role credential belongs in the app.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> setPartnerStartRole(bool partner) async {
  final prefs = await SharedPreferences.getInstance();
  if (!await prefs.setBool('cc.partner.start_as_partner', partner))
    throw StateError('Could not save start preference');
}
