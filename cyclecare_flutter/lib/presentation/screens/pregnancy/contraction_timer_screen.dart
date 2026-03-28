import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class ContractionTimerScreen extends ConsumerStatefulWidget {
  const ContractionTimerScreen({super.key});
  @override
  ConsumerState<ContractionTimerScreen> createState() => _ContractionTimerScreenState();
}

class _ContractionTimerScreenState extends ConsumerState<ContractionTimerScreen> {
  bool _isContracting = false;
  Timer? _timer;
  int _currentSeconds = 0;
  final List<Map<String, dynamic>> _contractions = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleContraction() {
    if (_isContracting) {
      _timer?.cancel();
      _contractions.insert(0, {
        'duration': _currentSeconds,
        'time': DateTime.now(),
        'interval': _contractions.isNotEmpty
            ? DateTime.now().difference(_contractions.first['time'] as DateTime).inSeconds
            : null,
        'intensity': 5,
      });
      setState(() {
        _isContracting = false;
        _currentSeconds = 0;
      });
    } else {
      setState(() => _isContracting = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _currentSeconds++);
      });
    }
  }

  String _formatSeconds(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Contraction Timer')),
      body: Column(
        children: [
          const SizedBox(height: 32),
          // Timer display
          Text(_formatSeconds(_currentSeconds),
              style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Start/stop button
          GestureDetector(
            onTap: _toggleContraction,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isContracting ? Colors.red : theme.colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  _isContracting ? 'STOP' : 'START',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_isContracting ? 'Tap when contraction ends' : 'Tap when contraction starts',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          const Divider(),

          // Summary
          if (_contractions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Count', '${_contractions.length}'),
                  _summaryItem('Avg Duration', _formatSeconds(
                    _contractions.map((c) => c['duration'] as int).reduce((a, b) => a + b) ~/ _contractions.length,
                  )),
                  if (_contractions.length > 1)
                    _summaryItem('Avg Interval', _formatSeconds(
                      _contractions.where((c) => c['interval'] != null).map((c) => c['interval'] as int).reduce((a, b) => a + b) ~/ (_contractions.length - 1),
                    )),
                ],
              ),
            ),
            const Divider(),
          ],

          // History list
          Expanded(
            child: ListView.builder(
              itemCount: _contractions.length,
              itemBuilder: (_, i) {
                final c = _contractions[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.red)),
                  ),
                  title: Text('Duration: ${_formatSeconds(c['duration'] as int)}'),
                  subtitle: c['interval'] != null
                      ? Text('Interval: ${_formatSeconds(c['interval'] as int)}')
                      : null,
                  trailing: Text(
                    '${(c['time'] as DateTime).hour}:${(c['time'] as DateTime).minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
