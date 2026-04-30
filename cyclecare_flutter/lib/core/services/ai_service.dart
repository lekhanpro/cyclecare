import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/database/app_database.dart';
import '../../domain/engines/cycle_prediction_engine.dart';

abstract class AIClient {
  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  });
}

class OpenAICompatibleClient implements AIClient {
  OpenAICompatibleClient({
    required this.apiKey,
    required this.baseUrl,
    this.model = 'gpt-4o-mini',
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  @override
  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw AIException('API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw AIException('No response from AI');
    }
    final message = choices.first['message'] as Map<String, dynamic>;
    return message['content'] as String;
  }
}

class AIException implements Exception {
  AIException(this.message);
  final String message;
  @override
  String toString() => 'AIException: $message';
}

class AIContextBuilder {
  const AIContextBuilder();

  String buildSystemPrompt({
    required bool allowPersonalData,
    required String trackingMode,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('You are CycleCare AI, a friendly, knowledgeable health-education assistant specialized in menstrual health, hormonal cycles, fertility awareness, and general wellness. You are NOT a medical doctor. You never diagnose conditions or prescribe treatments. You always encourage users to consult qualified healthcare professionals for medical concerns.');
    buffer.writeln();
    if (allowPersonalData) {
      buffer.writeln('You have access to the user\'s own cycle tracking data (periods, symptoms, moods, and predictions). Use this data to personalize explanations and highlight patterns when relevant. Do NOT mention specific intimate details unless the user explicitly asks about them. Keep summaries high-level and educational.');
    } else {
      buffer.writeln('You do NOT have access to the user\'s personal tracking data. Provide general, evidence-based educational information only.');
    }
    buffer.writeln();
    buffer.writeln('Tracking mode: $trackingMode');
    buffer.writeln();
    buffer.writeln('Guidelines:');
    buffer.writeln('- Always include a brief disclaimer that this is educational, not medical advice.');
    buffer.writeln('- Keep responses concise, warm, and easy to understand.');
    buffer.writeln('- Avoid explicit sexual instructions beyond general health and relationship context.');
    buffer.writeln('- If the user reports severe symptoms, gently suggest seeking medical care.');
    buffer.writeln('- Use inclusive language where possible.');
    return buffer.toString();
  }

  List<Map<String, String>> buildUserContext({
    required List<PeriodRecord> periods,
    required List<DailyLogRecord> recentLogs,
    required CyclePrediction? prediction,
    required bool includeIntimacy,
  }) {
    final context = <Map<String, String>>[];
    final summary = StringBuffer();

    if (periods.isNotEmpty) {
      final sorted = List<PeriodRecord>.from(periods)
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      summary.writeln('Recent periods:');
      for (final p in sorted.take(3)) {
        summary.writeln('- ${p.startDate.toIso8601String().split("T").first}');
      }
    }

    if (prediction != null) {
      summary.writeln();
      summary.writeln('Current prediction:');
      summary.writeln('- Cycle day: ${prediction.cycleDay}');
      summary.writeln('- Days until next period: ${prediction.daysUntilPeriod}');
      summary.writeln('- Phase: ${prediction.currentPhase}');
      summary.writeln('- Fertile window: ${prediction.fertileWindowStart.toIso8601String().split("T").first} to ${prediction.fertileWindowEnd.toIso8601String().split("T").first}');
    }

    if (recentLogs.isNotEmpty) {
      summary.writeln();
      summary.writeln('Recent daily logs (last 7 days):');
      for (final log in recentLogs.take(7)) {
        final parts = <String>[
          if (log.flow.isNotEmpty) 'flow: ${log.flow}',
          if (log.mood.isNotEmpty) 'mood: ${log.mood}',
          if (log.symptoms != '[]') 'symptoms: ${log.symptoms}',
          if (includeIntimacy && log.sexualActivity.isNotEmpty) 'sexual activity: ${log.sexualActivity}',
        ];
        if (parts.isNotEmpty) {
          summary.writeln('- ${log.date.toIso8601String().split("T").first}: ${parts.join(", ")}');
        }
      }
    }

    if (summary.isNotEmpty) {
      context.add({
        'role': 'user',
        'content': 'Here is my current cycle context:\n$summary',
      });
      context.add({
        'role': 'assistant',
        'content': 'Thank you for sharing. I\'ll keep this context in mind for our conversation.',
      });
    }

    return context;
  }
}

class AIService {
  AIService({
    required this.client,
    required this.contextBuilder,
  });

  final AIClient client;
  final AIContextBuilder contextBuilder;

  Future<String> ask({
    required String question,
    required bool allowPersonalData,
    required String trackingMode,
    required List<PeriodRecord> periods,
    required List<DailyLogRecord> recentLogs,
    required CyclePrediction? prediction,
    required bool includeIntimacy,
  }) async {
    final systemPrompt = contextBuilder.buildSystemPrompt(
      allowPersonalData: allowPersonalData,
      trackingMode: trackingMode,
    );

    final messages = <Map<String, String>>[
      if (allowPersonalData)
        ...contextBuilder.buildUserContext(
          periods: periods,
          recentLogs: recentLogs,
          prediction: prediction,
          includeIntimacy: includeIntimacy,
        ),
      {'role': 'user', 'content': question},
    ];

    final response = await client.sendMessage(
      systemPrompt: systemPrompt,
      messages: messages,
    );

    return '$response\n\n_Disclaimer: This is educational information, not medical advice. Please consult a healthcare professional for diagnosis or treatment._';
  }
}
