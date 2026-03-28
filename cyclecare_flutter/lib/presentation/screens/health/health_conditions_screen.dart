import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';

class HealthConditionsScreen extends ConsumerStatefulWidget {
  const HealthConditionsScreen({super.key});
  @override
  ConsumerState<HealthConditionsScreen> createState() => _HealthConditionsScreenState();
}

class _HealthConditionsScreenState extends ConsumerState<HealthConditionsScreen> {
  final Map<String, bool> _activeConditions = {};
  final Map<String, List<Map<String, dynamic>>> _logs = {};

  static const _conditionInfo = {
    'PCOS': {
      'icon': Icons.bubble_chart,
      'color': 0xFF9C27B0,
      'description': 'Polycystic Ovary Syndrome - track irregular cycles, androgen symptoms, insulin resistance',
      'symptoms': ['Irregular periods', 'Acne', 'Hair growth', 'Weight gain', 'Hair thinning', 'Insulin resistance'],
    },
    'Endometriosis': {
      'icon': Icons.healing,
      'color': 0xFFE91E63,
      'description': 'Track pain patterns, flare severity, and locations',
      'symptoms': ['Pelvic pain', 'Heavy periods', 'Pain during sex', 'Fatigue', 'Bloating', 'Nausea', 'Back pain'],
    },
    'PMDD': {
      'icon': Icons.psychology,
      'color': 0xFF2196F3,
      'description': 'Premenstrual Dysphoric Disorder - mood patterns and luteal phase tracking',
      'symptoms': ['Severe mood swings', 'Depression', 'Anxiety', 'Irritability', 'Insomnia', 'Fatigue', 'Difficulty concentrating'],
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Health Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Select conditions you want to track:', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          ..._conditionInfo.entries.map((entry) {
            final name = entry.key;
            final info = entry.value;
            final isActive = _activeConditions[name] ?? false;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isActive ? BorderSide(color: Color(info['color'] as int), width: 2) : BorderSide.none,
              ),
              child: ExpansionTile(
                leading: Icon(info['icon'] as IconData, color: Color(info['color'] as int)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(info['description'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                trailing: Switch(
                  value: isActive,
                  onChanged: (v) => setState(() => _activeConditions[name] = v),
                ),
                children: [
                  if (isActive) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Track these symptoms:', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (info['symptoms'] as List<String>).map((s) =>
                              Chip(
                                label: Text(s, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Color(info['color'] as int).withOpacity(0.1),
                              ),
                            ).toList(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showLogDialog(name, info),
                              icon: const Icon(Icons.add),
                              label: const Text('Log Today'),
                            ),
                          ),
                          if ((_logs[name] ?? []).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Recent Logs', style: theme.textTheme.titleSmall),
                            ...(_logs[name] ?? []).take(3).map((log) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(info['color'] as int).withOpacity(0.2),
                                child: Text('${log['severity']}', style: TextStyle(fontSize: 12, color: Color(info['color'] as int))),
                              ),
                              title: Text('Severity: ${log['severity']}/10'),
                              subtitle: Text('${(log['symptoms'] as List).join(', ')}'),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          // Pain mapping link
          Card(
            child: ListTile(
              leading: const Icon(Icons.body_chart, color: Colors.orange),
              title: const Text('Pain Mapping'),
              subtitle: const Text('Track pain locations on body map'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/health/pain-mapping'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDialog(String condition, Map<String, dynamic> info) {
    int severity = 5;
    final selectedSymptoms = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Log $condition'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Severity (1-10):'),
                Slider(
                  value: severity.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$severity',
                  onChanged: (v) => setDialogState(() => severity = v.round()),
                ),
                const SizedBox(height: 8),
                const Text('Symptoms:'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (info['symptoms'] as List<String>).map((s) =>
                    FilterChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      selected: selectedSymptoms.contains(s),
                      onSelected: (v) => setDialogState(() => v ? selectedSymptoms.add(s) : selectedSymptoms.remove(s)),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _logs.putIfAbsent(condition, () => []);
                  _logs[condition]!.insert(0, {
                    'date': DateTime.now(),
                    'severity': severity,
                    'symptoms': selectedSymptoms.toList(),
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
