import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetsConfigScreen extends ConsumerWidget {
  const WidgetsConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen Widgets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.widgets, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add CycleCare widgets to your home screen for quick access to cycle info.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _widgetPreview(
            theme,
            'Cycle Day',
            'Small - Shows current cycle day and phase icon',
            Icons.circle,
            'Day 14 - Ovulation',
          ),
          const SizedBox(height: 12),
          _widgetPreview(
            theme,
            'Period Countdown',
            'Medium - Days until next period with quick log button',
            Icons.timer,
            '5 days until period',
          ),
          const SizedBox(height: 12),
          _widgetPreview(
            theme,
            'Mini Calendar',
            'Large - Calendar with period and fertile markers',
            Icons.calendar_view_month,
            'Full month view',
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Long press your home screen to add widgets',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _widgetPreview(ThemeData theme, String name, String desc, IconData icon, String preview) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(height: 2),
                  Text(preview, style: const TextStyle(fontSize: 6), textAlign: TextAlign.center, maxLines: 2),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
