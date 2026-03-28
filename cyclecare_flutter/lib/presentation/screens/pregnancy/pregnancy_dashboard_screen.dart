import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';

class PregnancyDashboardScreen extends ConsumerStatefulWidget {
  const PregnancyDashboardScreen({super.key});
  @override
  ConsumerState<PregnancyDashboardScreen> createState() => _PregnancyDashboardScreenState();
}

class _PregnancyDashboardScreenState extends ConsumerState<PregnancyDashboardScreen> {
  DateTime _lmpDate = DateTime.now().subtract(const Duration(days: 84)); // ~12 weeks

  int get _gestationalWeeks => AppDateUtils.gestationalAgeInWeeks(_lmpDate);
  int get _gestationalDays => AppDateUtils.gestationalAgeInDays(_lmpDate) % 7;
  DateTime get _dueDate => AppDateUtils.estimatedDueDate(_lmpDate);
  int get _daysRemaining => _dueDate.difference(DateTime.now()).inDays;
  double get _progress => AppDateUtils.gestationalAgeInDays(_lmpDate) / 280.0;

  static const _weeklyInfo = <int, Map<String, String>>{
    4: {'size': 'Poppy seed', 'dev': 'Implantation occurring'},
    8: {'size': 'Raspberry', 'dev': 'Heart is beating, limbs forming'},
    12: {'size': 'Lime', 'dev': 'Fingers and toes formed, can move'},
    16: {'size': 'Avocado', 'dev': 'Can hear sounds, gender visible'},
    20: {'size': 'Banana', 'dev': 'Halfway! Movement felt (quickening)'},
    24: {'size': 'Corn', 'dev': 'Lungs developing, viable with care'},
    28: {'size': 'Eggplant', 'dev': 'Eyes can open, brain developing rapidly'},
    32: {'size': 'Squash', 'dev': 'Bones hardening, practicing breathing'},
    36: {'size': 'Honeydew', 'dev': 'Head may engage, gaining fat'},
    40: {'size': 'Watermelon', 'dev': 'Full term! Ready for birth'},
  };

  Map<String, String> get _currentInfo {
    final week = _gestationalWeeks;
    final key = _weeklyInfo.keys.where((k) => k <= week).isEmpty
        ? _weeklyInfo.keys.first
        : _weeklyInfo.keys.where((k) => k <= week).last;
    return _weeklyInfo[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _lmpDate,
                firstDate: DateTime.now().subtract(const Duration(days: 300)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _lmpDate = picked);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Week progress card
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Week $_gestationalWeeks, Day $_gestationalDays',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress.clamp(0, 1),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text('Due: ${AppDateUtils.formatDate(_dueDate)} ($_daysRemaining days remaining)',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Baby info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.child_care, color: Colors.pink),
                      const SizedBox(width: 8),
                      Text('Baby This Week', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Size: ${_currentInfo['size']}', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(_currentInfo['dev']!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions grid
          Row(
            children: [
              Expanded(child: _actionCard(context, 'Kick Counter', Icons.touch_app, Colors.purple, () {
                Navigator.pushNamed(context, '/pregnancy/kick-counter');
              })),
              const SizedBox(width: 12),
              Expanded(child: _actionCard(context, 'Contractions', Icons.timer, Colors.red, () {
                Navigator.pushNamed(context, '/pregnancy/contraction-timer');
              })),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _actionCard(context, 'Appointments', Icons.calendar_month, Colors.blue, () {
                Navigator.pushNamed(context, '/pregnancy/appointments');
              })),
              const SizedBox(width: 12),
              Expanded(child: _actionCard(context, 'Weight Log', Icons.monitor_weight, Colors.green, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log weight in Daily Log screen')),
                );
              })),
            ],
          ),
          const SizedBox(height: 16),

          // Trimester timeline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trimester Timeline', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _trimesterRow('1st Trimester', 'Weeks 1-12', _gestationalWeeks <= 12, _gestationalWeeks >= 1 && _gestationalWeeks <= 12),
                  _trimesterRow('2nd Trimester', 'Weeks 13-26', _gestationalWeeks <= 26, _gestationalWeeks >= 13 && _gestationalWeeks <= 26),
                  _trimesterRow('3rd Trimester', 'Weeks 27-40', _gestationalWeeks <= 40, _gestationalWeeks >= 27),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trimesterRow(String title, String range, bool reached, bool current) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle : Icons.circle_outlined,
            color: current ? Colors.pink : reached ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(fontWeight: current ? FontWeight.bold : FontWeight.normal))),
          Text(range, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}
