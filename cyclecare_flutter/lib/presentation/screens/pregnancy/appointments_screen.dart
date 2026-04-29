import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  final List<Map<String, dynamic>> _appointments = [
    {'title': 'First Prenatal Visit', 'doctor': 'Dr. Smith', 'date': DateTime.now().add(const Duration(days: 7)), 'completed': false},
    {'title': 'Ultrasound', 'doctor': 'Dr. Johnson', 'date': DateTime.now().add(const Duration(days: 21)), 'completed': false},
    {'title': 'Blood Work', 'doctor': 'Lab', 'date': DateTime.now().subtract(const Duration(days: 14)), 'completed': true},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcoming = _appointments.where((a) => !(a['completed'] as bool)).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    final past = _appointments.where((a) => a['completed'] as bool).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (upcoming.isNotEmpty) ...[
            Text('Upcoming', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...upcoming.map((a) => _appointmentCard(a, theme)),
          ],
          if (past.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Completed', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...past.map((a) => _appointmentCard(a, theme)),
          ],
          if (_appointments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.calendar_month, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No appointments yet', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> apt, ThemeData theme) {
    final completed = apt['completed'] as bool;
    return Card(
      child: ListTile(
        leading: Icon(
          completed ? Icons.check_circle : Icons.event,
          color: completed ? Colors.green : theme.colorScheme.primary,
        ),
        title: Text(apt['title'] as String,
            style: TextStyle(decoration: completed ? TextDecoration.lineThrough : null)),
        subtitle: Text('${apt['doctor']} - ${AppDateUtils.formatDate(apt['date'] as DateTime)}'),
        trailing: completed
            ? null
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => setState(() => apt['completed'] = true),
              ),
      ),
    );
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: doctorCtrl, decoration: const InputDecoration(labelText: 'Doctor')),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(AppDateUtils.formatDate(selectedDate)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  setState(() {
                    _appointments.add({
                      'title': titleCtrl.text,
                      'doctor': doctorCtrl.text,
                      'date': selectedDate,
                      'completed': false,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
