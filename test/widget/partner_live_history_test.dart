import 'package:cyclecare/features/partner/application/partner_live_controller.dart';
import 'package:cyclecare/features/partner/data/partner_sync_models.dart';
import 'package:cyclecare/features/partner/data/partner_sync_repository.dart';
import 'package:cyclecare/features/partner/domain/partner_share_code.dart';
import 'package:cyclecare/features/partner/partner_receiver_screen.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends PartnerSyncRepository {
  final links = <PartnerConnection>[];
  @override
  bool get configured => true;
  @override
  bool get signedIn => true;
  @override
  String? get userId => 'recipient';
  @override
  Future<void> load() async {}
  @override
  Future<List<PartnerConnection>> cachedConnections() async => List.of(links);
  @override
  Future<List<PartnerConnection>> fetchConnections() async => List.of(links);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('consent projection strips every unselected observation', () {
    final now = DateTime.now();
    final raw = PartnerSnapshot(
      createdAt: now,
      expiresAt: now.add(const Duration(days: 1)),
      ownerName: 'Private name',
      mood: 'Calm',
      symptoms: ['Cramps'],
      painLevel: 8,
      note: 'Private note',
      fertileStart: now,
      fertileEnd: now.add(const Duration(days: 2)),
    );
    final shared = const PartnerConsent(
      fields: ['mood'],
      home: true,
      automaticUpdates: true,
    ).filter(raw);
    expect(shared.mood, 'Calm');
    expect(shared.ownerName, isNull);
    expect(shared.symptoms, isNull);
    expect(shared.painLevel, isNull);
    expect(shared.note, isNull);
    expect(shared.fertileStart, isNull);
  });

  test('calendar-only and paused consent never transmit home observations', () {
    final now = DateTime.now();
    final raw = PartnerSnapshot(
      createdAt: now,
      expiresAt: now.add(const Duration(days: 1)),
      ownerName: 'Name',
      mood: 'Calm',
      symptoms: ['Cramps'],
      painLevel: 8,
      note: 'Note',
      nextPeriod: now.add(const Duration(days: 3)),
    );
    final calendar = const PartnerConsent(
      fields: ['name', 'mood', 'symptoms', 'pain', 'note', 'next_period'],
      calendar: true,
      automaticUpdates: true,
    ).filter(raw);
    expect(calendar.nextPeriod, isNotNull);
    expect(calendar.ownerName, isNull);
    expect(calendar.mood, isNull);
    expect(calendar.symptoms, isNull);
    expect(calendar.painLevel, isNull);
    expect(calendar.note, isNull);
    final paused = const PartnerConsent(
      fields: ['mood', 'next_period'],
      home: true,
      calendar: true,
      automaticUpdates: false,
    ).filter(raw);
    expect(paused.mood, isNull);
    expect(paused.nextPeriod, isNull);
  });

  testWidgets('open history withdraws selected fields and access on refresh', (
    tester,
  ) async {
    final now = DateTime.now();
    final snapshot = PartnerSnapshot(
      createdAt: now,
      expiresAt: now.add(const Duration(days: 1)),
      mood: 'Calm',
      symptoms: ['Cramps'],
    );
    PartnerConnection link(PartnerConsent consent, {bool revoked = false}) =>
        PartnerConnection(
          id: 'link',
          ownerId: 'owner',
          partnerId: 'recipient',
          createdAt: now,
          updatedAt: now,
          expiresAt: now.add(const Duration(days: 2)),
          snapshot: snapshot,
          consent: consent,
          revoked: revoked,
        );
    final repo = _Repo()
      ..links.add(
        link(
          const PartnerConsent(
            fields: ['mood', 'symptoms'],
            home: true,
            automaticUpdates: true,
          ),
        ),
      );
    final container = ProviderContainer(
      overrides: [partnerSyncRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(partnerLiveProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(const Color(0xff76415d)),
          home: PartnerHistoryScreen(snapshot: snapshot, linkId: 'link'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('Cramps'), findsOneWidget);
    repo.links[0] = link(
      const PartnerConsent(
        fields: ['mood'],
        home: true,
        automaticUpdates: true,
      ),
    );
    await container.read(partnerLiveProvider.notifier).refresh();
    await tester.pump();
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('Cramps'), findsNothing);
    repo.links[0] = link(
      const PartnerConsent(
        fields: ['mood'],
        home: true,
        automaticUpdates: true,
      ),
      revoked: true,
    );
    await container.read(partnerLiveProvider.notifier).refresh();
    await tester.pump();
    expect(find.text('Calm'), findsNothing);
    expect(find.text('This update is no longer available'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
