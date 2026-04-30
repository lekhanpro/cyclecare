import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare_flutter/core/services/ai_service.dart';
import 'package:cyclecare_flutter/data/database/app_database.dart';
import 'package:cyclecare_flutter/domain/engines/cycle_prediction_engine.dart';

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

    test('buildUserContext omits intimacy when includeIntimacy is false', () {
      final logs = [
        DailyLogRecord(
          id: 1, date: DateTime.now(),
          flow: 'Light', mood: 'Calm', symptoms: '[]',
          cervicalMucus: '', cervicalPosition: '', cervicalFirmness: '', cervicalOpening: '',
          temperature: 0, sexualActivity: 'Protected', waterIntake: 0, sleepHours: 0,
          exercise: '', notes: '',
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
      expect(userMsg, isNot(contains('sexual activity')));
    });

    test('buildUserContext includes intimacy when enabled', () {
      final logs = [
        DailyLogRecord(
          id: 1, date: DateTime.now(),
          flow: 'Light', mood: 'Calm', symptoms: '[]',
          cervicalMucus: '', cervicalPosition: '', cervicalFirmness: '', cervicalOpening: '',
          temperature: 0, sexualActivity: 'Protected', waterIntake: 0, sleepHours: 0,
          exercise: '', notes: '',
        ),
      ];
      final context = builder.buildUserContext(
        periods: [],
        recentLogs: logs,
        prediction: null,
        includeIntimacy: true,
      );
      final userMsg = context.first['content']!;
      expect(userMsg, contains('sexual activity'));
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
