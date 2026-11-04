import 'dart:async';

import 'package:cyclecare/features/partner/application/partner_live_controller.dart';
import 'package:cyclecare/features/partner/data/partner_sync_models.dart';
import 'package:cyclecare/features/partner/data/partner_sync_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class FailingPauseStore extends InMemorySharedPreferencesStore {
  FailingPauseStore() : super.withData({});
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.${PartnerLiveController.uploadPauseKey}') return false;
    return super.setValue(valueType, key, value);
  }
}

class FakePartnerRepository extends PartnerSyncRepository {
  bool readFails = false;
  bool offline = false;
  bool hasConfig = true;
  bool hasSession = true;
  int fetchCount = 0;
  int publishCount = 0;
  int inviteCount = 0;
  final revoked = <String>[];
  final links = <PartnerConnection>[];
  Completer<void>? blockNextFetch;

  @override
  bool get configured => hasConfig;
  @override
  bool get signedIn => hasSession;
  @override
  String? get userId => hasSession ? 'owner' : null;
  @override
  Future<void> load() async {
    if (readFails) throw StateError('unreadable secure storage');
  }

  @override
  Future<List<PartnerConnection>> cachedConnections() async => List.of(links);
  @override
  Future<List<PartnerConnection>> fetchConnections() async {
    fetchCount++;
    final blocker = blockNextFetch;
    blockNextFetch = null;
    if (blocker != null) await blocker.future;
    if (offline) throw const PartnerSyncException('Offline');
    return List.of(links);
  }

  @override
  Future<void> revoke(String id) async {
    if (offline) throw const PartnerSyncException('Offline');
    revoked.add(id);
    links.removeWhere((link) => link.id == id);
  }

  @override
  Future<PartnerInvite> createInvite(PartnerConsent consent) async {
    inviteCount++;
    throw StateError('Unexpected invite');
  }
}

PartnerConnection connection(String id, String owner) {
  final now = DateTime.now();
  return PartnerConnection(
    id: id,
    ownerId: owner,
    createdAt: now,
    updatedAt: now,
    expiresAt: now.add(const Duration(days: 20)),
    consent: const PartnerConsent(
      fields: ['mood'],
      home: true,
      automaticUpdates: true,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer containerFor(FakePartnerRepository repo) =>
      ProviderContainer(
        overrides: [partnerSyncRepositoryProvider.overrideWithValue(repo)],
      );

  test(
    'a failed pause write blocks deletion without pretending it persisted',
    () async {
      SharedPreferencesStorePlatform.instance = FailingPauseStore();
      final repo = FakePartnerRepository()..hasConfig = false;
      final container = containerFor(repo);
      addTearDown(container.dispose);
      await container.read(partnerLiveProvider.future);
      expect(
        await container
            .read(partnerLiveProvider.notifier)
            .prepareForTrackingDeletion(),
        isFalse,
      );
      expect(
        container.read(partnerLiveProvider).requireValue.error,
        contains('Could not save the sharing pause'),
      );
      expect(
        (await SharedPreferences.getInstance()).getBool(
          PartnerLiveController.uploadPauseKey,
        ),
        isNull,
      );
    },
  );

  test(
    'unreadable partner settings fail closed before tracking deletion',
    () async {
      final repo = FakePartnerRepository()
        ..readFails = true
        ..hasConfig = false;
      final container = containerFor(repo);
      addTearDown(container.dispose);
      expect(
        (await container.read(partnerLiveProvider.future)).error,
        isNotNull,
      );
      expect(
        await container
            .read(partnerLiveProvider.notifier)
            .prepareForTrackingDeletion(),
        isFalse,
      );
      expect(
        (await SharedPreferences.getInstance()).getBool(
          PartnerLiveController.uploadPauseKey,
        ),
        isTrue,
      );
      expect(
        container.read(partnerLiveProvider).requireValue.error,
        contains('Sharing is paused'),
      );
    },
  );

  test(
    'offline revocation retains records and persists pause across restart',
    () async {
      SharedPreferences.setMockInitialValues({
        'tracking-test-record': 'retained',
      });
      final repo = FakePartnerRepository()
        ..offline = true
        ..links.add(connection('first', 'owner'));
      final first = containerFor(repo);
      await first.read(partnerLiveProvider.future);
      expect(
        await first
            .read(partnerLiveProvider.notifier)
            .prepareForTrackingDeletion(),
        isFalse,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'tracking-test-record',
        ),
        'retained',
      );
      expect(repo.revoked, isEmpty);
      first.dispose();
      final secondRepo = FakePartnerRepository()
        ..links.add(connection('first', 'owner'));
      final second = containerFor(secondRepo);
      addTearDown(second.dispose);
      expect(
        (await second.read(partnerLiveProvider.future)).uploadsPaused,
        isTrue,
      );
      await second.read(partnerLiveProvider.notifier).synchronizeOwner();
      expect(secondRepo.fetchCount, 0);
    },
  );

  test(
    'waits for an in-flight request, blocks new ones, revokes owned links',
    () async {
      final gate = Completer<void>();
      final repo = FakePartnerRepository()
        ..links.addAll([
          connection('mine', 'owner'),
          connection('received', 'other'),
        ])
        ..blockNextFetch = gate;
      final container = containerFor(repo);
      addTearDown(container.dispose);
      await container.read(partnerLiveProvider.future);
      final notifier = container.read(partnerLiveProvider.notifier);
      final inflight = notifier.refresh();
      await Future<void>.delayed(Duration.zero);
      final deleting = notifier.prepareForTrackingDeletion();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.revoked, isEmpty);
      expect(await notifier.invite(const PartnerConsent()), isNull);
      expect(repo.inviteCount, 0);
      gate.complete();
      await inflight;
      expect(await deleting, isTrue);
      expect(repo.revoked, ['mine']);
      expect(repo.links.single.id, 'received');
      expect(
        container.read(partnerLiveProvider).requireValue.uploadsPaused,
        isTrue,
      );
    },
  );
}
