import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare_flutter/core/services/ai_service.dart';
import 'package:cyclecare_flutter/features/tracking/domain/cycle_models.dart';

class FakeAIClient implements AIClient {
  final String Function(String systemPrompt, List<Map<String, String>> messages)? onSend;
  FakeAIClient({this.onSend});

  @override
  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    if (onSend != null) return onSend!(systemPrompt, messages);
    return 'Fake response';
  }
}

void main() {
  group('AIContextBuilder', () {
    const builder = AIContextBuilder();

    test('buildSystemPrompt includes disclaimer and mode', () {
      final prompt = builder.buildSystemPrompt(
        allowPersonalData: true,
        trackingMode: 'track_periods',
      );
      expect(prompt, contains('CycleCare AI'));
      expect(prompt, contains('educational'));
      expect(prompt, contains('NOT a medical doctor'));
      expect(prompt, contains('track_periods'));
    });

    test('buildSystemPrompt excludes personal data context when disabled', () {
      final prompt = builder.buildSystemPrompt(
        allowPersonalData: false,
        trackingMode: 'track_periods',
      );
      expect(prompt, contains('do NOT have access'));
    });

    test('buildUserContext includes log mood and symptoms', () {
      final logs = [
        DailyLog(
          date: DateTime.now(),
          flow: FlowIntensity.light,
          mood: 'Calm',
          symptoms: const ['Cramps'],
        ),
      ];
      final context = builder.buildUserContext(
        periods: [],
        recentLogs: logs,
        prediction: null,
        includeIntimacy: false,
      );
      expect(context.length, 2);
      final userMsg = context.first['content']!;
      expect(userMsg, contains('mood: Calm'));
      expect(userMsg, contains('symptoms: Cramps'));
    });

    test('buildUserContext returns empty list when no data', () {
      final context = builder.buildUserContext(
        periods: [],
        recentLogs: [],
        prediction: null,
        includeIntimacy: false,
      );
      expect(context, isEmpty);
    });
  });

  group('AIService.ask', () {
    test('returns response with disclaimer appended', () async {
      final client = FakeAIClient(onSend: (_, __) => 'Take it easy today.');
      final service = AIService(client: client, contextBuilder: const AIContextBuilder());

      final response = await service.ask(
        question: 'What should I do?',
        allowPersonalData: false,
        trackingMode: 'track_periods',
        periods: [],
        recentLogs: [],
        prediction: null,
        includeIntimacy: false,
      );

      expect(response, contains('Take it easy today.'));
      expect(response, contains('Disclaimer'));
      expect(response, contains('educational information'));
    });

    test('throws AIException when client fails', () async {
      final client = FakeAIClient(
        onSend: (_, __) => throw AIException('Network timeout'),
      );
      final service = AIService(client: client, contextBuilder: const AIContextBuilder());

      expect(
        () => service.ask(
          question: 'Hello',
          allowPersonalData: false,
          trackingMode: 'track_periods',
          periods: [],
          recentLogs: [],
          prediction: null,
          includeIntimacy: false,
        ),
        throwsA(isA<AIException>()),
      );
    });
  });
}
