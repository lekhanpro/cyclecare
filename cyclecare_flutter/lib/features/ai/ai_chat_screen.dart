import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../data/database/app_database.dart';
import '../../domain/engines/cycle_prediction_engine.dart';

final aiChatMessagesProvider = StateProvider<List<AIChatMessage>>((ref) => []);
final aiLoadingProvider = StateProvider<bool>((ref) => false);

class AIChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  AIChatMessage({required this.text, required this.isUser, required this.timestamp});
}

final aiServiceProvider = Provider<AIService>((ref) {
  // In production, load API key from secure config or env
  const apiKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');
  const baseUrl = String.fromEnvironment('AI_BASE_URL', defaultValue: 'https://api.openai.com');
  final client = OpenAICompatibleClient(
    apiKey: apiKey.isNotEmpty ? apiKey : 'demo-key',
    baseUrl: baseUrl,
  );
  return AIService(client: client, contextBuilder: const AIContextBuilder());
});

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final _quickPrompts = [
    'When is my next period?',
    'When am I most likely to be fertile?',
    'Why do I feel low before my period?',
    'What foods help with PMS?',
    'Explain my cycle phases',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final allowPersonal = ref.read(aiUsePersonalDataProvider);
    final aiEnabled = ref.read(aiEnabledProvider);

    if (!aiEnabled) {
      _addMessage('AI is currently disabled. Enable it in Settings > AI Assistant.', false);
      return;
    }

    _controller.clear();
    setState(() {
      ref.read(aiChatMessagesProvider.notifier).update((state) => [
        ...state,
        AIChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      ]);
    });
    ref.read(aiLoadingProvider.notifier).state = true;
    _scrollToBottom();

    try {
      final db = ref.read(databaseProvider);
      final periods = await db.getAllPeriods();
      final logs = await db.getAllDailyLogs();
      final predictionAsync = ref.read(cyclePredictionProvider);
      final prediction = predictionAsync.valueOrNull;

      final service = ref.read(aiServiceProvider);
      final response = await service.ask(
        question: text,
        allowPersonalData: allowPersonal,
        trackingMode: ref.read(userModeProvider),
        periods: periods,
        recentLogs: logs,
        prediction: prediction,
        includeIntimacy: false,
      );

      setState(() {
        ref.read(aiChatMessagesProvider.notifier).update((state) => [
          ...state,
          AIChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        ]);
      });
    } on AIException catch (e) {
      setState(() {
        ref.read(aiChatMessagesProvider.notifier).update((state) => [
          ...state,
          AIChatMessage(
            text: 'I\'m having trouble connecting right now. ${_suggestOffline(allowPersonal)}\n\n(Error: ${e.message})',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ]);
      });
    } catch (e) {
      setState(() {
        ref.read(aiChatMessagesProvider.notifier).update((state) => [
          ...state,
          AIChatMessage(
            text: 'Something went wrong. Please check your connection and try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ]);
      });
    } finally {
      ref.read(aiLoadingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  String _suggestOffline(bool hasData) {
    if (hasData) {
      return 'You can still view your cycle data in the Calendar and Insights tabs.';
    }
    return 'Try asking a general question without personal data enabled.';
  }

  void _addMessage(String text, bool isUser) {
    ref.read(aiChatMessagesProvider.notifier).update((state) => [
      ...state,
      AIChatMessage(text: text, isUser: isUser, timestamp: DateTime.now()),
    ]);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatMessagesProvider);
    final isLoading = ref.watch(aiLoadingProvider);
    final aiEnabled = ref.watch(aiEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CycleCare AI'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!aiEnabled)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI is disabled. Enable it in Settings to get personalized answers.',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('CycleCare AI is thinking...', style: TextStyle(color: CycleCareColors.muted)),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 64, color: CycleCareColors.rose.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              'Ask CycleCare AI',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get educational answers about cycles, PMS, fertility, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CycleCareColors.muted),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts.map((prompt) {
                return ActionChip(
                  label: Text(prompt),
                  backgroundColor: CycleCareColors.rose.withOpacity(0.1),
                  side: BorderSide.none,
                  onPressed: () => _sendMessage(prompt),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? CycleCareColors.rose : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? Colors.white : CycleCareColors.ink,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text),
                decoration: InputDecoration(
                  hintText: 'Ask about cycles, PMS, fertility...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: CycleCareColors.rose,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About CycleCare AI'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CycleCare AI provides educational information about menstrual health, hormones, fertility, and wellness.',
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Important:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '- This is NOT a substitute for professional medical advice.\n'
                '- Never diagnose or treat based on AI responses alone.\n'
                '- Always consult a healthcare provider for medical concerns.',
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Data usage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'When enabled, AI may use your cycle summaries (not raw intimate details) to personalize answers. You can disable this in Settings.',
                style: TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
