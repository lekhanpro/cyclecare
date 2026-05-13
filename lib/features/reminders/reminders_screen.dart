import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';

final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  return NotificationService().loadReminders();
});

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (reminders) => reminders.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text('No reminders yet',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Set up reminders in Settings.',
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: reminders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final r = reminders[i];
                  return SoftCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_rounded,
                          color: r.enabled
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  style: AppTextStyles.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              Text(
                                '${r.hour}:${r.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: r.enabled,
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
