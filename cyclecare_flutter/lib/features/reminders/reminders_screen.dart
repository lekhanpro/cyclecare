import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../presentation/providers/app_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders'), centerTitle: true),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reminders) => _buildList(context, ref, reminders),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Reminder> reminders) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No reminders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Set up reminders for periods, ovulation, pills, or custom alerts.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final r = reminders[index];
        return _ReminderTile(reminder: r);
      },
    );
  }

  void _showAdd(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController(text: 'New Reminder');
    final bodyCtrl = TextEditingController(text: 'Remember to log your cycle data');
    var hour = 9;
    var minute = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, st) => AlertDialog(
          title: const Text('New Reminder'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: bodyCtrl, decoration: const InputDecoration(labelText: 'Message')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: hour, decoration: const InputDecoration(labelText: 'Hour'),
                  items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                  onChanged: (v) => st(() => hour = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: minute, decoration: const InputDecoration(labelText: 'Minute'),
                  items: [0, 15, 30, 45].map((m) => DropdownMenuItem(value: m, child: Text('$m'))).toList(),
                  onChanged: (v) => st(() => minute = v!),
                ),
              ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final svc = ref.read(notificationServiceProvider);
                final list = await svc.loadReminders();
                final id = 'reminder_${DateTime.now().millisecondsSinceEpoch}';
                final updated = [...list, Reminder(
                  id: id, type: ReminderType.customReminder,
                  title: titleCtrl.text, body: bodyCtrl.text,
                  hour: hour, minute: minute, enabled: true,
                  createdAt: DateTime.now(),
                )];
                await svc.saveReminders(updated);
                ref.invalidate(remindersProvider);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = switch (reminder.type) {
      ReminderType.periodReminder => Colors.red.shade400,
      ReminderType.ovulationReminder => Colors.blue.shade400,
      ReminderType.pillReminder => Colors.purple.shade400,
      ReminderType.customReminder => Colors.orange.shade400,
    };
    final icon = switch (reminder.type) {
      ReminderType.periodReminder => Icons.water_drop,
      ReminderType.ovulationReminder => Icons.egg_outlined,
      ReminderType.pillReminder => Icons.medication,
      ReminderType.customReminder => Icons.notifications_active,
    };
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 20)),
        title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${_fmt(reminder.hour, reminder.minute)} - ${reminder.body}'),
        trailing: Switch(
          value: reminder.enabled,
          onChanged: (v) async {
            final svc = ref.read(notificationServiceProvider);
            final list = await svc.loadReminders();
            final updated = list.map((r) => r.id == reminder.id ? r.copyWith(enabled: v) : r).toList();
            await svc.saveReminders(updated);
            ref.invalidate(remindersProvider);
          },
        ),
        onLongPress: () async {
          final svc = ref.read(notificationServiceProvider);
          final list = await svc.loadReminders();
          final updated = list.where((r) => r.id != reminder.id).toList();
          await svc.saveReminders(updated);
          ref.invalidate(remindersProvider);
        },
      ),
    );
  }

  String _fmt(int h, int m) {
    final hr = h % 12 == 0 ? 12 : h % 12;
    final am = h < 12 ? 'AM' : 'PM';
    return '$hr:${m.toString().padLeft(2, '0')} $am';
  }
}
