import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';

class BirthControlScreen extends ConsumerStatefulWidget {
  const BirthControlScreen({super.key});
  @override
  ConsumerState<BirthControlScreen> createState() => _BirthControlScreenState();
}

class _BirthControlScreenState extends ConsumerState<BirthControlScreen> {
  String _selectedType = 'Combination pill';
  TimeOfDay _pillTime = const TimeOfDay(hour: 9, minute: 0);
  int _streak = 0;
  final List<Map<String, dynamic>> _history = [];
  String _todayStatus = ''; // taken, missed, skipped

  @override
  void initState() {
    super.initState();
    // Generate mock history for last 30 days
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      _history.add({'date': date, 'status': i > 0 ? 'taken' : ''});
    }
    _streak = 15; // mock streak
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Birth Control')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active method card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medication, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Current Method', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: _showChangeMethodDialog,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_selectedType, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Pill time: ${_pillTime.format(context)}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Streak card
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                  const SizedBox(width: 8),
                  Text('$_streak day streak!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Today's check-off
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Status", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statusButton('Taken', Icons.check_circle, Colors.green),
                      _statusButton('Missed', Icons.cancel, Colors.red),
                      _statusButton('Skipped', Icons.skip_next, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // History
          Text('History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...List.generate(
            _history.length > 14 ? 14 : _history.length,
            (i) {
              final entry = _history[_history.length - 1 - i];
              final date = entry['date'] as DateTime;
              final status = i == 0 ? _todayStatus : (entry['status'] as String);
              return ListTile(
                dense: true,
                leading: Icon(
                  status == 'taken' ? Icons.check_circle : status == 'missed' ? Icons.cancel : status == 'skipped' ? Icons.skip_next : Icons.circle_outlined,
                  color: status == 'taken' ? Colors.green : status == 'missed' ? Colors.red : status == 'skipped' ? Colors.orange : Colors.grey,
                ),
                title: Text('${date.month}/${date.day}/${date.year}'),
                trailing: Text(status.isEmpty ? '-' : status, style: TextStyle(
                  color: status == 'taken' ? Colors.green : status == 'missed' ? Colors.red : Colors.orange,
                )),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String label, IconData icon, Color color) {
    final isSelected = _todayStatus == label.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _todayStatus = label.toLowerCase()),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? color : Colors.grey)),
        ],
      ),
    );
  }

  void _showChangeMethodDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Method'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.birthControlTypes.length,
            itemBuilder: (_, i) {
              final type = AppConstants.birthControlTypes[i];
              return ListTile(
                title: Text(type),
                leading: Radio<String>(
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (v) {
                    setState(() => _selectedType = v!);
                    Navigator.pop(ctx);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
