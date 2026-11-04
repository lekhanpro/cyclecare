import 'dart:convert';
import 'package:cyclecare/features/ai/ai_connection.dart';
import 'package:cyclecare/core/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const question = [
    {'role': 'user', 'content': 'Can stress change my cycle?'},
  ];
  test(
    'Gemini uses current steps schema, header auth and no stored interaction',
    () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/interactions',
        );
        expect(request.url.queryParameters, isEmpty);
        expect(request.headers['x-goog-api-key'], 'test-not-a-real-key');
        expect(request.headers['Api-Revision'], '2026-05-20');
        expect(request.followRedirects, isFalse);
        final json = jsonDecode(request.body) as Map;
        expect(json['store'], isFalse);
        expect(json['model'], 'gemini-3.8-flash');
        expect(
          json['system_instruction'],
          contains('Bundled educational reference excerpts'),
        );
        return http.Response(
          jsonEncode({
            'steps': [
              {
                'type': 'thought',
                'content': [
                  {'type': 'text', 'text': 'internal'},
                ],
              },
              {
                'type': 'model_output',
                'content': [
                  {'type': 'text', 'text': 'Educational answer'},
                ],
              },
            ],
          }),
          200,
        );
      });
      final result = await ConnectedAIClient(
        const AIConnection(
          provider: AssistantProvider.gemini,
          key: 'test-not-a-real-key',
        ),
        client: client,
      ).sendMessage(systemPrompt: 'Education only', messages: question);
      expect(result, 'Educational answer');
    },
  );
  test(
    'hosted model uses configured model and optional /v1 only once',
    () async {
      for (final url in [
        'https://models.example',
        'https://models.example/v1/',
      ]) {
        final client = MockClient((request) async {
          expect(request.url.path, '/v1/chat/completions');
          expect(request.headers['Authorization'], 'Bearer dummy');
          expect(
            (jsonDecode(request.body) as Map)['model'],
            'proadhikary/Menstrual-LLaMA-8B',
          );
          return http.Response(
            '{"choices":[{"message":{"content":"Hosted reply"}}]}',
            200,
          );
        });
        final result = await ConnectedAIClient(
          AIConnection(
            provider: AssistantProvider.compatible,
            key: 'dummy',
            endpoint: url,
            model: 'proadhikary/Menstrual-LLaMA-8B',
          ),
          client: client,
        ).sendMessage(systemPrompt: 'Education', messages: question);
        expect(result, 'Hosted reply');
      }
    },
  );
  test(
    'credentials and server error bodies never appear in surfaced errors',
    () async {
      final client = MockClient(
        (_) async => http.Response('secret-key user-health-data', 401),
      );
      try {
        await ConnectedAIClient(
          const AIConnection(
            provider: AssistantProvider.gemini,
            key: 'secret-key',
          ),
          client: client,
        ).sendMessage(systemPrompt: 'Education', messages: question);
        fail('Should fail');
      } on AIException catch (e) {
        expect(e.message, contains('401'));
        expect(e.message, isNot(contains('secret-key')));
        expect(e.message, isNot(contains('user-health-data')));
      }
    },
  );
  test(
    'rejects insecure or credential-bearing server URLs before any request',
    () {
      for (final url in [
        'http://models.example',
        'https://u:p@models.example',
        'https://models.example?key=secret',
        'https://models.example#fragment',
      ]) {
        expect(
          () => AIConnection(
            provider: AssistantProvider.compatible,
            endpoint: url,
            model: 'model',
          ).validate(),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'offline retrieval labels itself and supplies real bundled source URLs',
    () async {
      final result = await const LibraryAIClient().sendMessage(
        systemPrompt: '',
        messages: question,
      );
      expect(result, contains('not an AI-generated'));
      expect(result, contains('Sources:'));
      expect(result, contains('https://'));
      final unknown = await const LibraryAIClient().sendMessage(
        systemPrompt: '',
        messages: [
          {'role': 'user', 'content': 'xylophonexyz'},
        ],
      );
      expect(unknown, contains('could not find'));
      expect(unknown, isNot(contains('diagnosis is')));
    },
  );
  test(
    'connection and key survive provider reload and explicit removal',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final first = ProviderContainer();
      await first.read(aiConnectionProvider.future);
      await first
          .read(aiConnectionProvider.notifier)
          .save(
            const AIConnection(
              provider: AssistantProvider.gemini,
              key: 'dummy-secret',
            ),
          );
      first.dispose();
      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(
        (await second.read(aiConnectionProvider.future)).key,
        'dummy-secret',
      );
      await second.read(aiConnectionProvider.notifier).clear();
      expect(
        second.read(aiConnectionProvider).requireValue.provider,
        AssistantProvider.library,
      );
      expect(
        await const FlutterSecureStorage().read(
          key: AIConnectionNotifier.storageKey,
        ),
        isNull,
      );
    },
  );
}
