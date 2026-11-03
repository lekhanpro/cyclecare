import 'dart:convert';

import 'package:cyclecare/core/services/ai_service.dart';
import 'package:cyclecare/features/partner/application/partner_sharing_controller.dart';
import 'package:cyclecare/features/partner/domain/partner_share_code.dart';
import 'package:cyclecare/features/partner/domain/partner_snapshot_builder.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/domain/logging_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

// Intimacy, protection, libido and test results are private observations.
// They must never reach the partner share code (or its preview, which is
// built by the same function) or any AI request, whatever the switches say.

const _privateFieldIds = {
  'intimacy',
  'protection',
  'libido',
  'pregnancyTest',
  'ovulationTest',
  'testNote',
};

const _noteMarker = 'zq-private-test-note';

/// Distinctive values for every private field, and the field-name words a
/// leak would most likely carry.
const _privateValues = [
  'Partnered',
  'Condom',
  'Not sure',
  'Positive',
  'Unclear',
  _noteMarker,
];
const _privateWords = [
  'intimacy',
  'protection',
  'libido',
  'pregnancy test',
  'pregnancytest',
  'ovulation test',
  'ovulationtest',
  'test note',
  'testnote',
];

class _CapturingClient implements AIClient {
  String? systemPrompt;
  List<Map<String, String>> messages = const [];

  @override
  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    this.systemPrompt = systemPrompt;
    this.messages = messages;
    return 'ok';
  }
}

void main() {
  final now = DateTime(2026, 10, 3, 9);
  final lastStart = DateTime(2026, 10, 1);
  final periods = [
    for (var i = 0; i < 4; i++)
      CycleEvent(
        id: 'p$i',
        startDate: lastStart.subtract(Duration(days: 28 * i)),
        endDate: lastStart.subtract(Duration(days: 28 * i - 4)),
      ),
  ];
  final prediction = const CyclePredictionService().buildPrediction(
    periods: periods,
    preferences: const CyclePreferences(),
    referenceDate: now,
  )!;

  final log = DailyLog(
    date: DateTime(2026, 10, 3),
    flow: FlowIntensity.light,
    mood: 'Calm',
    symptoms: const ['Cramps'],
    painLevel: 4,
    sleepHours: 7,
    intimacy: 'Partnered',
    protection: 'Condom',
    libido: 'Not sure',
    pregnancyTest: 'Positive',
    ovulationTest: 'Unclear',
    testNote: _noteMarker,
  );

  void expectNoPrivateData(String text, {required String where}) {
    final lower = text.toLowerCase();
    for (final value in _privateValues) {
      expect(
        RegExp('\\b${RegExp.escape(value.toLowerCase())}\\b').hasMatch(lower),
        isFalse,
        reason: '"$value" leaked into $where',
      );
    }
    for (final word in _privateWords) {
      expect(lower.contains(word), isFalse, reason: '"$word" in $where');
    }
  }

  test('the test log sets every private catalogue field', () {
    expect(
      LoggingCatalog.fields.where((f) => f.private).map((f) => f.id).toSet(),
      _privateFieldIds,
    );
    for (final id in _privateFieldIds) {
      expect(LoggingCatalog.field(id)!.binding.isLogged(log), isTrue,
          reason: id);
    }
  });

  test('partner snapshot and share code never carry private fields', () {
    const everythingOn = PartnerSharingOptions(
      sharePhase: true,
      shareNextPeriod: true,
      shareMood: true,
      shareSymptoms: true,
      shareFertileWindow: true,
      shareSupportTip: true,
      shareOvulation: true,
      sharePms: true,
      sharePain: true,
    );
    final snapshot = buildPartnerSnapshot(
      prediction: prediction,
      todayLog: log,
      options: everythingOn,
      ownerName: 'Ava',
      now: now,
    );

    // What is shared still arrives, so the check below is not vacuous.
    expect(snapshot.mood, 'Calm');
    expect(snapshot.symptoms, ['Cramps']);
    expect(snapshot.painLevel, 4);

    final payload = jsonEncode(snapshot.toJson());
    expectNoPrivateData(payload, where: 'the share code payload');

    final decoded = decodeShareCode(encodeShareCode(snapshot), now: now);
    expectNoPrivateData(jsonEncode(decoded.toJson()),
        where: 'the decoded share code');
  });

  test('AI requests never carry private fields, even with intimacy allowed',
      () async {
    final client = _CapturingClient();
    final service = AIService(
      client: client,
      contextBuilder: const AIContextBuilder(),
    );

    await service.ask(
      question: 'What should I expect this week?',
      allowPersonalData: true,
      trackingMode: 'Track periods',
      periods: periods,
      recentLogs: [log],
      prediction: prediction,
      includeIntimacy: true,
    );

    final context = client.messages.map((m) => m['content']).join('\n');
    // The non-private parts of the log are sent, so the check is real.
    expect(context, contains('mood: Calm'));
    expect(context, contains('pain level: 4/10'));

    expectNoPrivateData(context, where: 'the AI messages');
    expectNoPrivateData(client.systemPrompt!, where: 'the AI system prompt');
  });

  test('the context builder alone never carries private fields', () {
    final messages = const AIContextBuilder().buildUserContext(
      periods: periods,
      recentLogs: [log],
      prediction: prediction,
      includeIntimacy: true,
    );
    expectNoPrivateData(messages.map((m) => m['content']).join('\n'),
        where: 'the AI user context');
  });
}
