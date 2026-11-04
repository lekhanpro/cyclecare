import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'application/partner_live_controller.dart';
import 'data/partner_inbox_repository.dart';
import 'data/partner_sync_models.dart';
import 'domain/partner_share_code.dart';
import 'partner_calendar.dart';
import 'partner_hub_screen.dart';
import 'partner_view.dart';

/// A recipient's own read-only space. It never reads the owner's tracker provider.
class PartnerReceiverScreen extends ConsumerStatefulWidget {
  const PartnerReceiverScreen({super.key});
  @override
  ConsumerState<PartnerReceiverScreen> createState() =>
      _PartnerReceiverScreenState();
}

class _PartnerReceiverScreenState extends ConsumerState<PartnerReceiverScreen>
    with WidgetsBindingObserver {
  final _inbox = PartnerInboxRepository();
  List<LocalPartnerUpdate> _manual = [];
  String? _selected;
  String? _error;
  int _tab = 0;
  bool _working = false;
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      unawaited(ref.read(partnerLiveProvider.notifier).refresh());
    }
  }

  Future<void> _load() async {
    try {
      final items = await _inbox.load();
      if (mounted) setState(() => _manual = items);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not read saved updates. Please retry.');
    }
  }

  Future<String?> _paste(String title) async => showDialog<String>(
    context: context,
    builder: (_) => _CodeDialog(title: title),
  );
  Future<void> _connect() async {
    final state =
        ref.read(partnerLiveProvider).valueOrNull ?? const PartnerLiveState();
    if (!state.configured || !state.signedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const PartnerServerSetupScreen(),
        ),
      );
      if (!mounted) return;
    }
    final ready = ref.read(partnerLiveProvider).valueOrNull;
    if (ready?.signedIn != true) return;
    final code = await _paste('Connect with invitation');
    if (code == null || !mounted) return;
    final success = await ref.read(partnerLiveProvider.notifier).accept(code);
    if (success && mounted)
      setState(() {
        _selected = null;
        _tab = 0;
      });
  }

  Future<void> _import({String? replaceId}) async {
    final code = await _paste(
      replaceId == null ? 'Open one-off update' : 'Replace with a newer update',
    );
    if (code == null || !mounted) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final id = await _inbox.receive(code, replaceId: replaceId);
      await _load();
      if (mounted)
        setState(() {
          _selected = 'local:$id';
          _tab = 0;
        });
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is ShareCodeException
              ? error.message
              : error is FormatException
              ? error.message
              : 'Could not keep this update. Please retry.',
        );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete(LocalPartnerUpdate update) async {
    if (!await confirmAction(
      context,
      title: 'Delete saved dashboard?',
      message:
          'All received snapshots in this local dashboard will be removed from this device.',
      confirmLabel: 'Delete',
      destructive: true,
    ))
      return;
    try {
      await _inbox.remove(update.id);
      await _load();
      if (mounted) setState(() => _selected = null);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Could not delete the saved dashboard. Please retry.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(partnerLiveProvider);
    final state = async.valueOrNull ?? const PartnerLiveState();
    final remote = state.links
        .where((l) => l.partnerId == state.userId && state.userId != null)
        .toList();
    final ids = [
      ...remote.map((l) => 'remote:${l.id}'),
      ..._manual.map((m) => 'local:${m.id}'),
    ];
    final selected = ids.contains(_selected) ? _selected : ids.firstOrNull;
    final connection = remote
        .where((l) => 'remote:${l.id}' == selected)
        .firstOrNull;
    final local = _manual.where((l) => 'local:${l.id}' == selected).firstOrNull;
    final snapshot = connection?.snapshot ?? local?.latest;
    final expired =
        (connection?.expiredAt(DateTime.now()) ?? false) ||
        (snapshot?.isExpiredAt(DateTime.now()) ?? false);
    final revoked = connection?.revoked ?? false;
    final canHome = local != null || (connection?.consent.home ?? false);
    final canCalendar =
        local != null || (connection?.consent.calendar ?? false);
    Widget body;
    if (_tab == 2) {
      body = _settings(state, connection, local);
    } else if (selected == null) {
      body = _empty();
    } else if (revoked || expired) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: AppIcons.privacy,
            title: revoked ? 'Access was withdrawn' : 'This update has expired',
            message:
                'Ask your partner for a new connection or update. Your connection settings remain available.',
          ),
        ),
      );
    } else if ((_tab == 0 && !canHome) || (_tab == 1 && !canCalendar)) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: AppIcons.privacy,
            title: 'This page is not shared',
            message:
                'Your partner chooses which pages are available. You can still manage your own connection in Settings.',
          ),
        ),
      );
    } else if (snapshot == null) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: AppIcons.partnerPair,
            title: 'Waiting for a shared update',
            message:
                'The connection is ready. Only fields explicitly enabled by your partner will appear here.',
          ),
        ),
      );
    } else if (_tab == 1) {
      body = PartnerCalendar(snapshot: snapshot);
    } else {
      body = PartnerDashboard(
        snapshot: snapshot,
        banner: _freshness(state, connection, local, snapshot),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner dashboard'),
        actions: [
          IconButton(
            tooltip: 'Check for updates',
            onPressed: state.busy
                ? null
                : () async {
                    await ref.read(partnerLiveProvider.notifier).refresh();
                    await _load();
                  },
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'Connect or import',
            onSelected: (value) => value == 'live' ? _connect() : _import(),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'live',
                child: Text('Connect with invitation'),
              ),
              const PopupMenuItem(
                value: 'local',
                child: Text('Open one-off update'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (ids.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Shared with me'),
                items: [
                  for (final link in remote)
                    DropdownMenuItem(
                      value: 'remote:${link.id}',
                      child: Text(
                        link.snapshot?.ownerName ?? 'Partner connection',
                      ),
                    ),
                  for (final update in _manual)
                    DropdownMenuItem(
                      value: 'local:${update.id}',
                      child: Text(update.latest.ownerName ?? 'One-off update'),
                    ),
                ],
                onChanged: (value) => setState(() => _selected = value),
              ),
            ),
          if (_error != null || state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: InfoBanner(
                icon: Icons.error_outline,
                title: 'Update needs attention',
                message: _error ?? state.error!,
              ),
            ),
          if (_working || state.busy)
            const LinearProgressIndicator(
              semanticsLabel: 'Updating partner dashboard',
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(AppIcons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(AppIcons.calendar),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _empty() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(AppIcons.partnerPair, size: 56),
      const SizedBox(height: 20),
      Text(
        'Support starts here',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      const Text(
        'See the cycle updates, feelings and care suggestions your partner chooses to share. Your dashboard cannot edit their records.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: _connect,
        icon: const Icon(Icons.link),
        label: const Text('Connect with invitation'),
      ),
      TextButton(
        onPressed: () => _import(),
        child: const Text('Open a one-off update instead'),
      ),
    ],
  );
  Widget _freshness(
    PartnerLiveState state,
    PartnerConnection? connection,
    LocalPartnerUpdate? local,
    PartnerSnapshot snapshot,
  ) {
    final age = DateTime.now().difference(snapshot.createdAt);
    final old = age >= const Duration(days: 1);
    final when = DateFormat(
      'EEE d MMM, HH:mm',
    ).format(snapshot.createdAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          connection == null
              ? 'One-off update · $when'
              : 'Shared update · $when',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        if (connection != null)
          Text(
            state.lastChecked == null
                ? 'Saved on this phone · connection not checked this session'
                : 'Connection checked ${DateFormat('HH:mm').format(state.lastChecked!.toLocal())}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (old)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'This update is over a day old. Feelings and plans may have changed.',
            ),
          ),
        if (local != null)
          TextButton(
            onPressed: () => _import(replaceId: local.id),
            child: const Text('Open a newer update'),
          ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Received update history'),
          children: [
            if (local != null)
              ..._historyRows(local.snapshots)
            else if (connection != null)
              FutureBuilder<List<PartnerSnapshot>>(
                future: ref
                    .read(partnerSyncRepositoryProvider)
                    .cachedHistory(connection.id),
                builder: (context, result) => Column(
                  children: _historyRows(
                    result.data ?? [],
                    linkId: connection.id,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _historyRows(
    List<PartnerSnapshot> history, {
    String? linkId,
  }) => [
    for (final snapshot in history)
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          DateFormat('d MMM, HH:mm').format(snapshot.createdAt.toLocal()),
        ),
        subtitle: Text(
          snapshot.isExpiredAt(DateTime.now())
              ? 'Expired'
              : snapshot.mood ?? snapshot.phase ?? 'Shared update',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: snapshot.isExpiredAt(DateTime.now())
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PartnerHistoryScreen(snapshot: snapshot, linkId: linkId),
                ),
              ),
      ),
  ];
  Widget _settings(
    PartnerLiveState state,
    PartnerConnection? link,
    LocalPartnerUpdate? local,
  ) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Your connection', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      if (link != null) ...[
        Text(
          link.revoked
              ? 'Access revoked'
              : link.expiredAt(DateTime.now())
              ? 'Connection expired'
              : 'Paired partner connection',
        ),
        Text(
          'Expires ${DateFormat('d MMM yyyy').format(link.expiresAt.toLocal())}',
        ),
        const SizedBox(height: 12),
        Text(
          'Home: ${link.consent.home ? 'shared' : 'not shared'} · Calendar: ${link.consent.calendar ? 'shared' : 'not shared'}',
        ),
        FilledButton.tonal(
          onPressed: state.busy
              ? null
              : () async {
                  if (await confirmAction(
                    context,
                    title: 'Disconnect?',
                    message:
                        'Future updates to this connection stop. Saved server data for this connection is removed.',
                    confirmLabel: 'Disconnect',
                    destructive: true,
                  )) {
                    await ref
                        .read(partnerLiveProvider.notifier)
                        .disconnect(link.id);
                  }
                },
          child: const Text('Disconnect'),
        ),
      ],
      if (local != null) ...[
        const Text(
          'One-off snapshots stay on this device and do not sync. They are not encrypted or authenticated messages; only open updates from someone you trust.',
        ),
        TextButton(
          onPressed: () => _import(replaceId: local.id),
          child: const Text('Open a newer update'),
        ),
        TextButton(
          onPressed: () => _delete(local),
          child: const Text('Delete saved dashboard'),
        ),
      ],
      const SizedBox(height: 16),
      FilledButton.tonal(
        onPressed: _connect,
        child: const Text('Connect another invitation'),
      ),
      TextButton(
        onPressed: () => _import(),
        child: const Text('Import one-off update'),
      ),
      TextButton(
        onPressed: () async {
          try {
            await setPartnerStartRole(true);
            if (mounted)
              showAppToast(
                context,
                message: 'Partner dashboard set as your start page',
              );
          } catch (_) {
            if (mounted)
              setState(() => _error = 'Could not save your start preference.');
          }
        },
        child: const Text('Use partner dashboard as my start page'),
      ),
      TextButton(
        onPressed: () async {
          try {
            await setPartnerStartRole(false);
            if (mounted)
              showAppToast(context, message: 'Tracking set as your start page');
          } catch (_) {
            if (mounted)
              setState(() => _error = 'Could not save your start preference.');
          }
        },
        child: const Text('Use tracking as my start page'),
      ),
      const SizedBox(height: 16),
      const ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('About partner access'),
        children: [
          Text(
            'You receive a read-only copy of the fields your partner selected. The calendar does not fill in unshared periods or predict new cycles. Feelings are observations from the update date, not a description of how someone must feel today. Revocation blocks server reads immediately; an offline copy cannot learn about revocation until it reconnects and may remain until its expiry. Exported copies cannot be recalled.',
          ),
        ],
      ),
    ],
  );
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog({required this.title});
  final String title;
  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _text = TextEditingController();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('partner-receiver-code'),
      controller: _text,
      minLines: 3,
      maxLines: 6,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        labelText: 'Paste invitation or update code',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _text.text),
        child: const Text('Open'),
      ),
    ],
  );
}

/// An archive route rechecks current permissions for every provider update.
/// Historical snapshots never freeze access grants or bypass their expiry.
class PartnerHistoryScreen extends ConsumerStatefulWidget {
  const PartnerHistoryScreen({super.key, required this.snapshot, this.linkId});
  final PartnerSnapshot snapshot;
  final String? linkId;
  @override
  ConsumerState<PartnerHistoryScreen> createState() =>
      _PartnerHistoryScreenState();
}

class _PartnerHistoryScreenState extends ConsumerState<PartnerHistoryScreen>
    with WidgetsBindingObserver {
  Timer? _expiry;
  DateTime? _scheduledExpiry;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiry?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  void _schedule(DateTime expires) {
    if (_scheduledExpiry == expires) return;
    _scheduledExpiry = expires;
    _expiry?.cancel();
    final wait = expires.difference(DateTime.now());
    if (wait > Duration.zero)
      _expiry = Timer(wait, () {
        if (mounted) setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnerLiveProvider).valueOrNull;
    final link = state?.links.where((l) => l.id == widget.linkId).firstOrNull;
    var expires = widget.snapshot.expiresAt;
    if (link != null && link.expiresAt.isBefore(expires))
      expires = link.expiresAt;
    _schedule(expires);
    final blocked =
        widget.snapshot.isExpiredAt(DateTime.now()) ||
        (widget.linkId != null &&
            (link == null ||
                link.revoked ||
                link.expiredAt(DateTime.now()) ||
                !link.consent.home ||
                !link.consent.automaticUpdates ||
                state?.userId == null ||
                link.partnerId != state?.userId));
    final selected = widget.linkId == null
        ? widget.snapshot
        : link?.consent.filter(widget.snapshot);
    return Scaffold(
      appBar: AppBar(title: const Text('Earlier shared update')),
      body: blocked || selected == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  icon: AppIcons.privacy,
                  title: 'This update is no longer available',
                  message:
                      'It has expired or your partner changed access. Return to your dashboard for current connection settings.',
                ),
              ),
            )
          : PartnerDashboard(snapshot: selected),
    );
  }
}
