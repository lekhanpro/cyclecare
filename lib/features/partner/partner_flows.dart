import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import 'application/partner_sharing_controller.dart';
import 'domain/partner_share_code.dart';
import 'domain/partner_snapshot_builder.dart';
import 'partner_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Partner flows: preview, share a code, open a code.
//
// Pushed with Navigator rather than new router entries, because they are
// steps inside the partner screen rather than places in the app.
// ─────────────────────────────────────────────────────────────────────────────

/// The owner's current snapshot, rebuilt whenever their data or switches
/// change. Watching this is what makes the preview live.
final ownerSnapshotProvider = Provider.autoDispose<PartnerSnapshot?>((ref) {
  final data = ref.watch(cycleTrackerControllerProvider).valueOrNull;
  if (data == null) return null;
  return buildPartnerSnapshot(
    prediction: data.prediction,
    todayLog: data.logFor(DateTime.now()),
    options: ref.watch(partnerSharingProvider),
    ownerName: data.preferences.profileName,
    now: DateTime.now(),
  );
});

/// "Preview as your partner": the real dashboard, fed by the live snapshot.
class PartnerPreviewScreen extends ConsumerWidget {
  const PartnerPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(ownerSnapshotProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Partner preview')),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : PartnerDashboard(
              snapshot: snapshot,
              banner: const InfoBanner(
                icon: Icons.visibility_rounded,
                title: 'This is what your partner sees',
                message: 'Change a switch on the previous screen and this '
                    'updates straight away.',
              ),
            ),
    );
  }
}

/// Shows the code for the current snapshot, with Copy and Share.
class PartnerShareCodeScreen extends ConsumerWidget {
  const PartnerShareCodeScreen({super.key});

  /// Groups of six, so a person reading it aloud or comparing it can keep
  /// their place. Decoding strips the spaces again.
  static String group(String code) {
    final b = StringBuffer();
    for (var i = 0; i < code.length; i += 6) {
      if (i > 0) b.write(' ');
      b.write(code.substring(i, (i + 6).clamp(0, code.length)));
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(ownerSnapshotProvider);
    final text = Theme.of(context).textTheme;
    if (snapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final code = encodeShareCode(snapshot);
    final message = 'Open CycleCare, go to Share with partner > I have a code, '
        'and paste this:\n\n$code';

    return Scaffold(
      appBar: AppBar(title: const Text('Your share code')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppCard(
            emphasis: CardEmphasis.floating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Send this to your partner',
                    style: text.titleMedium?.copyWith(
                      color: context.inkColor,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: AppSpacing.md),
                SelectableText(
                  group(code),
                  style: text.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.6,
                    color: context.inkColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Valid until '
                  '${DateFormat('EEE d MMM').format(snapshot.expiresAt)}',
                  style: text.labelSmall?.copyWith(color: context.mutedColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Share code',
            icon: Icons.ios_share_rounded,
            onPressed: () => Share.share(message, subject: 'CycleCare code'),
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Copy code',
            icon: Icons.copy_rounded,
            outlined: true,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                showAppToast(context, message: 'Code copied');
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const InfoBanner(
            icon: AppIcons.privacy,
            title: 'What this code is',
            message: 'It contains only the things you switched on, and your '
                'partner needs no account to open it. It is a snapshot: it '
                'will not update when your data changes, so send a new code '
                'when you want them to see something new.',
          ),
        ],
      ),
    );
  }
}

/// Codes the partner chose to keep, stored on their device only.
class SavedPartnerCodes {
  static const _key = 'cyclecare.partner.saved_codes';

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  /// Newest first, with no duplicates.
  static Future<void> keep(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(_key) ?? []).where((c) => c != code);
    await prefs.setStringList(_key, [code, ...list]);
  }

  static Future<void> remove(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    await prefs.setStringList(_key, list.where((c) => c != code).toList());
  }
}

/// The partner's side: paste a code, see the dashboard.
class PartnerOpenCodeScreen extends StatefulWidget {
  const PartnerOpenCodeScreen({super.key});

  @override
  State<PartnerOpenCodeScreen> createState() => _PartnerOpenCodeScreenState();
}

class _PartnerOpenCodeScreenState extends State<PartnerOpenCodeScreen> {
  final _controller = TextEditingController();
  String? _error;
  List<String> _saved = const [];

  @override
  void initState() {
    super.initState();
    _refreshSaved();
  }

  Future<void> _refreshSaved() async {
    final saved = await SavedPartnerCodes.load();
    if (mounted) setState(() => _saved = saved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(String code, {required bool alreadyKept}) {
    try {
      final snapshot = decodeShareCode(code);
      setState(() => _error = null);
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => _OpenedCodeScreen(
          code: code.replaceAll(RegExp(r'\s'), ''),
          snapshot: snapshot,
          alreadyKept: alreadyKept,
          onChanged: _refreshSaved,
        ),
      ));
    } on ShareCodeException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('I have a code')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('Paste the code you were sent',
              style: text.titleMedium?.copyWith(
                color: context.inkColor,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('partner-code-field'),
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: 'CC1-…',
              errorText: _error,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                tooltip: 'Paste',
                icon: const Icon(Icons.content_paste_rounded),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) _controller.text = data!.text!;
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Open',
            icon: Icons.lock_open_rounded,
            onPressed: () => _open(_controller.text, alreadyKept: false),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nothing is saved unless you choose to keep it.',
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: context.mutedColor),
          ),
          if (_saved.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(title: 'Kept on this device'),
            for (final code in _saved) _SavedRow(code: code, onOpen: _open),
          ],
        ],
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.code, required this.onOpen});

  final String code;
  final void Function(String, {required bool alreadyKept}) onOpen;

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    try {
      final s = decodeShareCode(code);
      title = s.ownerName ?? 'Cycle update';
      subtitle =
          'Shared ${DateFormat('d MMM').format(s.createdAt)}';
    } on ShareCodeException catch (e) {
      title = 'Saved code';
      subtitle = e.error == ShareCodeError.expired ? 'Expired' : 'Unreadable';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ActionTile(
        icon: AppIcons.partnerPair,
        title: title,
        subtitle: subtitle,
        onTap: () => onOpen(code, alreadyKept: true),
      ),
    );
  }
}

class _OpenedCodeScreen extends StatefulWidget {
  const _OpenedCodeScreen({
    required this.code,
    required this.snapshot,
    required this.alreadyKept,
    required this.onChanged,
  });

  final String code;
  final PartnerSnapshot snapshot;
  final bool alreadyKept;
  final VoidCallback onChanged;

  @override
  State<_OpenedCodeScreen> createState() => _OpenedCodeScreenState();
}

class _OpenedCodeScreenState extends State<_OpenedCodeScreen> {
  late bool _kept = widget.alreadyKept;

  Future<void> _toggle() async {
    if (_kept) {
      await SavedPartnerCodes.remove(widget.code);
    } else {
      await SavedPartnerCodes.keep(widget.code);
    }
    widget.onChanged();
    if (!mounted) return;
    setState(() => _kept = !_kept);
    showAppToast(context,
        message: _kept ? 'Kept on this device' : 'Removed from this device');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.snapshot.ownerName ?? 'Cycle update'),
        actions: [
          TextButton.icon(
            onPressed: _toggle,
            icon: Icon(_kept
                ? Icons.bookmark_remove_rounded
                : Icons.bookmark_add_rounded),
            label: Text(_kept ? 'Remove' : 'Keep'),
          ),
        ],
      ),
      body: PartnerDashboard(snapshot: widget.snapshot),
    );
  }
}
