import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/partner_sync_models.dart';
import '../data/partner_sync_repository.dart';
import '../domain/partner_share_code.dart';
import '../domain/partner_snapshot_builder.dart';
import '../../tracking/application/cycle_tracker_controller.dart';
import 'partner_sharing_controller.dart';

final partnerSyncRepositoryProvider = Provider<PartnerSyncRepository>((ref) {
  final repository = PartnerSyncRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

class PartnerLiveState {
  const PartnerLiveState({
    this.configured = false,
    this.signedIn = false,
    this.userId,
    this.links = const [],
    this.busy = false,
    this.error,
    this.lastChecked,
    this.uploadsPaused = false,
  });
  final bool configured, signedIn, busy, uploadsPaused;
  final String? userId, error;
  final List<PartnerConnection> links;
  final DateTime? lastChecked;
}

class PartnerLiveController extends AsyncNotifier<PartnerLiveState> {
  static const uploadPauseKey = 'cc.partner.uploads_paused.v1';
  PartnerSyncRepository get _repository =>
      ref.read(partnerSyncRepositoryProvider);
  final _publishedHashes = <String, String>{};
  bool _uploadsPaused = true;
  bool _preparingDeletion = false;
  Completer<void>? _pendingOperation;
  PartnerLiveState get current => state.valueOrNull ?? const PartnerLiveState();
  @override
  Future<PartnerLiveState> build() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _uploadsPaused = preferences.getBool(uploadPauseKey) ?? false;
      await _repository.load();
      return PartnerLiveState(
        configured: _repository.configured,
        signedIn: _repository.signedIn,
        userId: _repository.userId,
        links: await _repository.cachedConnections(),
        uploadsPaused: _uploadsPaused,
      );
    } catch (_) {
      _uploadsPaused = true;
      return const PartnerLiveState(
        uploadsPaused: true,
        error:
            'Could not read partner settings. Reopen or configure the connection again.',
      );
    }
  }

  void _set({
    bool? busy,
    String? error,
    List<PartnerConnection>? links,
    DateTime? checked,
  }) {
    state = AsyncData(
      PartnerLiveState(
        configured: _repository.configured,
        signedIn: _repository.signedIn,
        userId: _repository.userId,
        links: links ?? current.links,
        busy: busy ?? (_pendingOperation != null),
        error: error,
        lastChecked: checked ?? current.lastChecked,
        uploadsPaused: _uploadsPaused,
      ),
    );
  }

  Future<T?> _run<T>(
    Future<T> Function() action, {
    bool duringDeletion = false,
  }) async {
    if (_pendingOperation != null || (_preparingDeletion && !duringDeletion)) {
      return null;
    }
    final pending = Completer<void>();
    _pendingOperation = pending;
    _set(busy: true);
    try {
      final result = await action();
      _set(busy: false);
      return result;
    } catch (error) {
      _set(
        busy: false,
        error: error is PartnerSyncException
            ? error.message
            : 'Could not save the partner connection. Please retry.',
      );
      return null;
    } finally {
      if (identical(_pendingOperation, pending)) _pendingOperation = null;
      pending.complete();
    }
  }

  /// Stops future uploads before deleting tracking data. A prior publish is
  /// allowed to finish, then every current owner link is revoked on the server.
  /// Failure is closed: credentials and tracking records remain for retry.
  Future<bool> prepareForTrackingDeletion() async {
    if (_preparingDeletion) return false;
    _preparingDeletion = true;
    var pausePersisted = false;
    try {
      await future;
      final readError = current.error;
      _uploadsPaused = true;
      _set(busy: current.busy);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(uploadPauseKey, true)) {
        // SharedPreferences may optimistically change its in-memory cache even
        // when the platform write fails; don't later mistake that for safety.
        try {
          await prefs.reload();
        } catch (_) {
          // The current process remains paused and deletion remains blocked.
        }
        throw StateError('Could not save the sharing pause');
      }
      pausePersisted = true;
      await _pendingOperation?.future;
      if (readError != null && !_repository.configured) {
        throw StateError('Could not read partner connection settings');
      }
      if (!_repository.configured) return true;
      if (!_repository.signedIn || _repository.userId == null) {
        throw StateError('Partner identity is unavailable');
      }
      final revoked = await _run(() async {
        final links = await _repository.fetchConnections();
        for (final link in links) {
          if (link.ownerId == _repository.userId && !link.revoked) {
            await _repository.revoke(link.id);
          }
        }
        final remaining = await _repository.fetchConnections();
        if (remaining.any(
          (l) => l.ownerId == _repository.userId && !l.revoked,
        )) {
          throw StateError('Some owner connections are still active');
        }
        _publishedHashes.clear();
        _set(links: remaining, checked: DateTime.now());
        return true;
      }, duringDeletion: true);
      if (revoked != true) throw StateError('Could not revoke partner access');
      return true;
    } catch (_) {
      _uploadsPaused = true;
      _set(
        error: pausePersisted
            ? 'Sharing is paused on this phone. Connect to the internet and retry so active partner access can be revoked before deleting tracking records.'
            : 'Could not save the sharing pause. Tracking records were kept. Stop sharing in partner settings and retry.',
      );
      return false;
    } finally {
      _preparingDeletion = false;
    }
  }

  Future<void> _resumeAfterExplicitConsent() async {
    if (!_uploadsPaused) return;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(uploadPauseKey, false)) {
      throw StateError('Could not save the sharing preference');
    }
    _uploadsPaused = false;
  }

  Future<bool> connect(PartnerServerConfig config) async =>
      await _run(() async {
        await _repository.configure(config);
        await _repository.authenticate(forceRefresh: true);
        _set(
          links: await _repository.fetchConnections(),
          checked: DateTime.now(),
        );
        return true;
      }) ??
      false;
  Future<bool> refresh() async {
    if (!current.configured || !current.signedIn) return false;
    return await _run(() async {
          _set(
            links: await _repository.fetchConnections(),
            checked: DateTime.now(),
          );
          return true;
        }) ??
        false;
  }

  Future<PartnerInvite?> invite(PartnerConsent consent) => _run(() async {
    final invite = await _repository.createInvite(consent);
    if (consent.automaticUpdates) await _resumeAfterExplicitConsent();
    _set(links: await _repository.fetchConnections(), checked: DateTime.now());
    return invite;
  });
  Future<bool> accept(String code) async =>
      await _run(() async {
        await _repository.acceptInvite(code);
        _set(
          links: await _repository.fetchConnections(),
          checked: DateTime.now(),
        );
        return true;
      }) ??
      false;
  Future<bool> publish(PartnerConnection link, PartnerConsent consent) async =>
      await _run(() async {
        final tracker = await ref.read(cycleTrackerControllerProvider.future);
        final snapshot = partnerSnapshotForConsent(
          tracker,
          consent,
          ref.read(partnerSharingProvider).note,
        );
        await _repository.publish(link.id, snapshot, consent);
        if (consent.automaticUpdates) await _resumeAfterExplicitConsent();
        _publishedHashes.remove(link.id);
        _set(
          links: await _repository.fetchConnections(),
          checked: DateTime.now(),
        );
        return true;
      }) ??
      false;
  Future<bool> revoke(String id) async =>
      await _run(() async {
        await _repository.revoke(id);
        _set(
          links: await _repository.fetchConnections(),
          checked: DateTime.now(),
        );
        return true;
      }) ??
      false;
  Future<bool> disconnect(String id) async =>
      await _run(() async {
        await _repository.disconnect(id);
        _set(
          links: await _repository.fetchConnections(),
          checked: DateTime.now(),
        );
        return true;
      }) ??
      false;
  Future<void> synchronizeOwner() async {
    if (_uploadsPaused ||
        !current.configured ||
        !current.signedIn ||
        current.busy)
      return;
    final tracker = ref.read(cycleTrackerControllerProvider).valueOrNull;
    if (tracker == null) return;
    await _run(() async {
      final links = await _repository.fetchConnections();
      for (final link in links.where(
        (l) =>
            l.ownerId == _repository.userId &&
            !l.revoked &&
            !l.expiredAt(DateTime.now()) &&
            l.consent.automaticUpdates,
      )) {
        if (_uploadsPaused) break;
        final snapshot = partnerSnapshotForConsent(
          tracker,
          link.consent,
          ref.read(partnerSharingProvider).note,
        );
        final body = snapshot.toJson()
          ..remove('c')
          ..remove('x');
        final today = DateTime.now();
        final hash =
            '${today.year}-${today.month}-${today.day}:${jsonEncode(body)}';
        if (_publishedHashes[link.id] == hash) continue;
        await _repository.publish(link.id, snapshot, link.consent);
        _publishedHashes[link.id] = hash;
      }
      _set(
        links: await _repository.fetchConnections(),
        checked: DateTime.now(),
      );
      return true;
    });
  }
}

final partnerLiveProvider =
    AsyncNotifierProvider<PartnerLiveController, PartnerLiveState>(
      PartnerLiveController.new,
    );

PartnerSnapshot partnerSnapshotForConsent(
  CycleTrackerState data,
  PartnerConsent consent,
  String note,
) {
  bool has(String field) => consent.fields.contains(field);
  final snapshot = buildPartnerSnapshot(
    prediction: data.prediction,
    todayLog: data.logFor(DateTime.now()),
    options: PartnerSharingOptions(
      sharePhase: has('phase'),
      shareNextPeriod: has('next_period'),
      shareMood: has('mood'),
      shareSymptoms: has('symptoms'),
      sharePain: has('pain'),
      shareFertileWindow: has('fertile'),
      shareOvulation: has('ovulation'),
      sharePms: has('pms'),
      shareSupportTip: has('support_tip'),
      note: has('note') ? note : '',
    ),
    ownerName: has('name') ? data.preferences.profileName : '',
    now: DateTime.now(),
  );
  return consent.filter(snapshot);
}

/// Mount once above the app's routed content. Publishes only an explicitly
/// enabled server link, while this app is foregrounded. No background service.
class PartnerSyncBoundary extends ConsumerStatefulWidget {
  const PartnerSyncBoundary({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<PartnerSyncBoundary> createState() =>
      _PartnerSyncBoundaryState();
}

class _PartnerSyncBoundaryState extends ConsumerState<PartnerSyncBoundary>
    with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _debounce;
  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _sync());
  }

  void _sync() {
    if (_foreground)
      unawaited(ref.read(partnerLiveProvider.notifier).synchronizeOwner());
  }

  void _queue() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _sync);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _queue();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(partnerLiveProvider);
    ref.listen(cycleTrackerControllerProvider, (_, __) => _queue());
    ref.listen(partnerSharingProvider, (_, __) => _queue());
    return widget.child;
  }
}
