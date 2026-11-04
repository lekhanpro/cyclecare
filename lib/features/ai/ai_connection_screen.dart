import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_connection.dart';

class AIConnectionScreen extends ConsumerStatefulWidget {
  const AIConnectionScreen({super.key});
  @override
  ConsumerState<AIConnectionScreen> createState() => _AIConnectionScreenState();
}

class _AIConnectionScreenState extends ConsumerState<AIConnectionScreen> {
  final _key = TextEditingController(),
      _endpoint = TextEditingController(),
      _model = TextEditingController();
  AssistantProvider _provider = AssistantProvider.library;
  bool _seeded = false, _busy = false;
  String? _status;
  AIConnection get _connection => AIConnection(
    provider: _provider,
    key: _key.text.trim(),
    endpoint: _endpoint.text.trim(),
    model: _model.text.trim(),
  );
  @override
  void dispose() {
    _key.dispose();
    _endpoint.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _apply({bool test = false, bool clear = false}) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      if (clear) {
        await ref.read(aiConnectionProvider.notifier).clear();
        _key.clear();
        _provider = AssistantProvider.library;
      } else if (test) {
        _connection.validate();
        await ConnectedAIClient(_connection).sendMessage(
          systemPrompt:
              'Reply with a short greeting. No health data is attached.',
          messages: [
            {'role': 'user', 'content': 'Hello'},
          ],
        );
      } else {
        await ref.read(aiConnectionProvider.notifier).save(_connection);
      }
      if (mounted)
        setState(
          () => _status = test
              ? 'Provider responded. No health records were sent.'
              : clear
              ? 'Connection removed. Offline learning is available.'
              : 'Saved on this device.',
        );
    } catch (e) {
      if (mounted)
        setState(
          () => _status = e is FormatException
              ? e.message
              : 'Could not complete this action. Check your connection settings and try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(aiConnectionProvider);
    final value = saved.valueOrNull;
    if (!_seeded && value != null) {
      _seeded = true;
      _provider = value.provider;
      _key.text = value.key;
      _endpoint.text = value.endpoint;
      _model.text = value.model;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant connection')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Choose how to learn',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The offline helper searches sourced articles. Connected models generate answers and can make mistakes; they do not diagnose or prescribe.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AssistantProvider>(
                  key: ValueKey(_provider),
                  initialValue: _provider,
                  isExpanded: true,
                  itemHeight: null,
                  decoration: const InputDecoration(labelText: 'Provider'),
                  items: const [
                    DropdownMenuItem(
                      value: AssistantProvider.library,
                      child: Text('Offline article helper'),
                    ),
                    DropdownMenuItem(
                      value: AssistantProvider.gemini,
                      child: Text('Gemini · your API key'),
                    ),
                    DropdownMenuItem(
                      value: AssistantProvider.compatible,
                      child: Text('Hosted open model · your server'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (p) => setState(() {
                          if (_provider != p) _key.clear();
                          _provider = p!;
                          _status = null;
                          if (p == AssistantProvider.gemini)
                            _model.text = 'gemini-3.8-flash';
                        }),
                ),
                if (_provider != AssistantProvider.library) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'Model ID'),
                    autocorrect: false,
                  ),
                  if (_provider == AssistantProvider.compatible) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _endpoint,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'HTTPS server URL',
                        helperText:
                            'OpenAI-compatible server, with optional /v1',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A model on GitHub or Hugging Face is not a running API. Your hosted model needs a server. MenstLLaMA is a menstrual-education research candidate; hosting and validation are still required.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _key,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: _provider == AssistantProvider.gemini
                          ? 'Your Gemini API key'
                          : 'Server key (if required)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Stored in device secure storage, excluded from tracking backups. Questions go to this provider only when you send them. Personal-record sharing starts off on every chat visit. Provider retention and billing terms apply.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _apply(test: true),
                    child: const Text('Test with a generic greeting'),
                  ),
                ],
                if (saved.hasError)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Saved connection could not be read. Retry or save new settings.',
                    ),
                  ),
                if (_status != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(liveRegion: true, child: Text(_status!)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : () => _apply(),
                  child: Text(_busy ? 'Working…' : 'Save connection'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _apply(clear: true),
                  child: const Text('Remove connection & key'),
                ),
                if (saved.hasError)
                  TextButton(
                    onPressed: () => ref.invalidate(aiConnectionProvider),
                    child: const Text('Retry reading connection'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
