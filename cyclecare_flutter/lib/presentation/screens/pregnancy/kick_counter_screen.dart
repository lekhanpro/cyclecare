import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class KickCounterScreen extends ConsumerStatefulWidget {
  const KickCounterScreen({super.key});
  @override
  ConsumerState<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends ConsumerState<KickCounterScreen> {
  int _count = 0;
  int _targetCount = 10;
  bool _isActive = false;
  DateTime? _sessionStart;
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isActive = true;
      _count = 0;
      _sessionStart = DateTime.now();
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _recordKick() {
    if (!_isActive) return;
    setState(() => _count++);
    if (_count >= _targetCount) {
      _timer?.cancel();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Goal Reached!'),
          content: Text('$_targetCount kicks recorded in ${_formatDuration(_elapsedSeconds)}'),
          actions: [
            ElevatedButton(onPressed: () {
              Navigator.pop(ctx);
              _resetSession();
            }, child: const Text('Done')),
          ],
        ),
      );
    }
  }

  void _resetSession() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _count = 0;
      _elapsedSeconds = 0;
      _sessionStart = null;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kick Counter'),
        actions: [
          if (_isActive)
            IconButton(icon: const Icon(Icons.stop), onPressed: _resetSession),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_formatDuration(_elapsedSeconds),
                style: theme.textTheme.displaySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            Text('$_count', style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 80,
            )),
            Text('of $_targetCount kicks', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _count / _targetCount,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 48),
            if (!_isActive)
              ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Session'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              )
            else
              GestureDetector(
                onTap: _recordKick,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                    boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: const Center(
                    child: Icon(Icons.touch_app, color: Colors.white, size: 48),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_isActive)
              TextButton(onPressed: _resetSession, child: const Text('Reset')),
          ],
        ),
      ),
    );
  }
}
