import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/services/ai_service.dart';
import '../education/domain/article.dart';
import '../education/domain/core_articles.dart';

enum AssistantProvider { library, gemini, compatible }

class AIConnection {
  const AIConnection({
    this.provider = AssistantProvider.library,
    this.key = '',
    this.endpoint = '',
    this.model = 'gemini-3.8-flash',
  });
  final AssistantProvider provider;
  final String key, endpoint, model;
  String get label => switch (provider) {
    AssistantProvider.library => 'Offline learning helper',
    AssistantProvider.gemini => 'Gemini · $model',
    AssistantProvider.compatible => 'Hosted model · $model',
  };
  void validate() {
    if (provider == AssistantProvider.library) return;
    if (model.trim().isEmpty || model.length > 160)
      throw const FormatException('Enter a model name.');
    if (provider == AssistantProvider.gemini && key.trim().isEmpty) {
      throw const FormatException('Enter your Gemini API key.');
    }
    if (provider == AssistantProvider.compatible) {
      final uri = Uri.tryParse(endpoint.trim());
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment) {
        throw const FormatException(
          'Use an HTTPS server URL without credentials or query parameters.',
        );
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'provider': provider.name,
    'key': key,
    'endpoint': endpoint,
    'model': model,
  };
  factory AIConnection.fromJson(Map<String, dynamic> json) => AIConnection(
    provider: AssistantProvider.values.firstWhere(
      (p) => p.name == json['provider'],
      orElse: () => AssistantProvider.library,
    ),
    key: json['key'] as String? ?? '',
    endpoint: json['endpoint'] as String? ?? '',
    model: json['model'] as String? ?? 'gemini-3.8-flash',
  );
}

final aiSecureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final aiConnectionProvider =
    AsyncNotifierProvider<AIConnectionNotifier, AIConnection>(
      AIConnectionNotifier.new,
    );

class AIConnectionNotifier extends AsyncNotifier<AIConnection> {
  static const storageKey = 'cc.assistant.connection.v1';
  @override
  Future<AIConnection> build() async {
    final raw = await ref.read(aiSecureStorageProvider).read(key: storageKey);
    if (raw == null) return const AIConnection();
    final connection = AIConnection.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    connection.validate();
    return connection;
  }

  Future<void> save(AIConnection connection) async {
    connection.validate();
    await ref
        .read(aiSecureStorageProvider)
        .write(key: storageKey, value: jsonEncode(connection.toJson()));
    state = AsyncData(connection);
  }

  Future<void> clear() async {
    await ref.read(aiSecureStorageProvider).delete(key: storageKey);
    state = const AsyncData(AIConnection());
  }
}

/// Retrieval over bundled, sourced articles. This is explicitly not an LLM.
List<Article> findLearningArticles(String question) {
  const stop = {
    'what',
    'when',
    'where',
    'which',
    'that',
    'this',
    'with',
    'have',
    'does',
    'about',
    'your',
    'from',
    'right',
    'really',
    'please',
  };
  final terms = RegExp(r'[a-z]{3,}')
      .allMatches(question.toLowerCase())
      .map((m) => m.group(0)!)
      .where((w) => !stop.contains(w))
      .toSet();
  final scored = [
    for (final a in kCoreArticles)
      (
        a,
        terms.fold<int>(
          0,
          (v, t) =>
              v +
              (a.title.toLowerCase().contains(t) ? 5 : 0) +
              (a.matches(t) ? 1 : 0),
        ),
      ),
  ];
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return scored.where((s) => s.$2 > 0).take(3).map((s) => s.$1).toList();
}

String learningExcerpt(Article a) {
  final paragraphs = a.body
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && !s.startsWith('#'))
      .take(2)
      .join('\n\n');
  return '${a.title}\n${a.summary}\n\n$paragraphs';
}

class LibraryAIClient implements AIClient {
  const LibraryAIClient();
  @override
  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    final matches = findLearningArticles(messages.last['content'] ?? '');
    if (matches.isEmpty)
      return 'Offline library search · not an AI-generated answer.\n\nI could not find a relevant article. Try a topic such as period pain, sleep, fertility or stress, or open Learn. For a personal health concern, speak with a qualified clinician.';
    return 'Offline library excerpts · not an AI-generated or personalised answer.\n\n${matches.map((a) => '${learningExcerpt(a)}\n\nSources:\n${a.sources.map((s) => '${s.publisher}: ${s.url}').join('\n')}').join('\n\n——\n\n')}\n\nOpen Learn to read the complete articles.';
  }
}

/// Both providers use the user's own connection, never an APK-embedded key.
class ConnectedAIClient implements AIClient {
  ConnectedAIClient(this.connection, {http.Client? client}) : _client = client;
  final AIConnection connection;
  final http.Client? _client;
  @override
  Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    connection.validate();
    final articles = findLearningArticles(messages.last['content'] ?? '');
    final grounding = articles
        .map(
          (a) =>
              '${learningExcerpt(a)}\n${a.sources.map((s) => s.url).join('\n')}',
        )
        .join('\n\n');
    final prompt =
        '$systemPrompt\nDo not diagnose, prescribe, confirm ovulation or invent source citations. Distinguish recorded observations from estimates. If the source excerpts do not answer a question, say so.\nBundled educational reference excerpts:\n$grounding';
    final gemini = connection.provider == AssistantProvider.gemini;
    final uri = gemini
        ? Uri.https('generativelanguage.googleapis.com', '/v1beta/interactions')
        : Uri.parse(
            '${connection.endpoint.trim().replaceAll(RegExp(r'/+$'), '')}${connection.endpoint.trim().replaceAll(RegExp(r'/+$'), '').endsWith('/v1') ? '' : '/v1'}/chat/completions',
          );
    final body = gemini
        ? {
            'model': connection.model,
            'store': false,
            'system_instruction': prompt,
            'input': messages.map((m) => m['content'] ?? '').join('\n\n'),
            'generation_config': {'max_output_tokens': 1200},
          }
        : {
            'model': connection.model,
            'messages': [
              {'role': 'system', 'content': prompt},
              ...messages,
            ],
            'max_tokens': 1200,
          };
    final client = _client ?? http.Client();
    try {
      final request = http.Request('POST', uri)
        ..followRedirects = false
        ..headers.addAll({
          'Content-Type': 'application/json',
          if (gemini) 'x-goog-api-key': connection.key,
          if (gemini) 'Api-Revision': '2026-05-20',
          if (!gemini && connection.key.isNotEmpty)
            'Authorization': 'Bearer ${connection.key}',
        })
        ..body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 35)),
      ).timeout(const Duration(seconds: 35));
      if (response.statusCode < 200 || response.statusCode >= 300)
        throw AIException(
          'Provider request failed (${response.statusCode}). Check the model, key and quota.',
        );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final text = gemini
          ? ((json['steps'] as List<dynamic>? ?? [])
                .whereType<Map>()
                .where((o) => o['type'] == 'model_output')
                .expand(
                  (o) =>
                      (o['content'] as List<dynamic>? ?? []).whereType<Map>(),
                )
                .where((o) => o['type'] == 'text')
                .map((o) => o['text'])
                .whereType<String>()
                .join('\n'))
          : (((json['choices'] as List<dynamic>?)?.firstOrNull
                        as Map?)?['message']
                    as Map?)?['content']
                as String?;
      if (text == null || text.trim().isEmpty)
        throw AIException(
          'The provider returned no text. Try a different question or model.',
        );
      return text;
    } on AIException {
      rethrow;
    } catch (_) {
      throw AIException(
        'Could not contact the provider. Check your connection and try again.',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
