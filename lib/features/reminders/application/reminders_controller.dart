import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/notification_access.dart';
import '../../tracking/application/cycle_tracker_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reminders state
//
// The reminders screen previously rendered a list with a `Switch` whose
// `onChanged` was an empty closure — the control moved and nothing happened.
// That is the worst failure mode in an interface: it reports success and does
// not act, so the user finds out only when the notification never arrives.
//
// Everything here routes through NotificationService, which owns both
// persistence and OS scheduling. Saving reschedules; there is no path that
// writes state without also updating what the system will actually fire.
// ─────────────────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class RemindersController extends AsyncNotifier<List<Reminder>> {
  NotificationService get _service => ref.read(notificationServiceProvider);

  Future<void> _pending = Future.value();
  Future<void> Function()? _failedOperation;

  @override
  Future<List<Reminder>> build() async {
    final tracker = await ref.read(cycleTrackerControllerProvider.future);
    final reminders = await _service.loadReminders(
      preferences: tracker.preferences,
    );
    final report = await _service.reschedule(
      reminders,
      prediction: tracker.prediction,
    );
    ref.read(reminderScheduleReportProvider.notifier).state = report;
    ref.listen(cycleTrackerControllerProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data == null ||
          identical(previous?.valueOrNull?.prediction, data.prediction) &&
              identical(previous?.valueOrNull?.preferences, data.preferences)) {
        return;
      }
      refreshSchedule().catchError((Object _) {});
    });
    return reminders;
  }

  /// Edits are serialized so rapid toggles never overwrite another change.
  Future<void> _serialize(Future<void> Function() operation) {
    final task = _pending.then((_) async {
      try {
        await operation();
        _failedOperation = null;
        ref.read(reminderSaveErrorProvider.notifier).state = null;
      } catch (_) {
        _failedOperation = operation;
        ref.read(reminderSaveErrorProvider.notifier).state =
            'Could not save that change. Your previous reminders are still shown.';
        rethrow;
      }
    });
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  Future<void> _commit(List<Reminder> reminders) async {
    final tracker = await ref.read(cycleTrackerControllerProvider.future);
    final report = await _service.saveReminders(
      reminders,
      prediction: tracker.prediction,
    );
    state = AsyncData(reminders);
    ref.read(reminderScheduleReportProvider.notifier).state = report;
  }

  Future<void> refreshSchedule() => _serialize(() async {
    final tracker = await ref.read(cycleTrackerControllerProvider.future);
    final reminders = await _service.loadReminders(
      preferences: tracker.preferences,
    );
    final report = await _service.reschedule(
      reminders,
      prediction: tracker.prediction,
    );
    state = AsyncData(reminders);
    ref.read(reminderScheduleReportProvider.notifier).state = report;
  });

  Future<void> retryLastEdit() async {
    final operation = _failedOperation;
    if (operation != null) await _serialize(operation);
  }

  Future<void> requestPermission() async {
    await _service.requestPermission();
    await refreshSchedule();
  }

  Future<bool> openSystemSettings() => _service.openSystemSettings();

  Future<void> setEnabled(String id, bool enabled) => _serialize(() async {
    final current = await future;
    await _commit([
      for (final reminder in current)
        if (reminder.id == id)
          reminder.copyWith(enabled: enabled)
        else
          reminder,
    ]);
  });

  Future<void> setTime(String id, int hour, int minute) => _serialize(() async {
    final current = await future;
    await _commit([
      for (final reminder in current)
        if (reminder.id == id)
          reminder.copyWith(hour: hour, minute: minute)
        else
          reminder,
    ]);
  });

  Future<void> setDaysBefore(String id, int daysBefore) => _serialize(() async {
    final current = await future;
    await _commit([
      for (final reminder in current)
        if (reminder.id == id)
          reminder.copyWith(daysBefore: daysBefore)
        else
          reminder,
    ]);
  });

  Future<void> updateReminder(Reminder reminder) => _serialize(() async {
    final current = await future;
    await _commit([
      for (final existing in current)
        if (existing.id == reminder.id) reminder else existing,
    ]);
  });

  Future<void> addCustom({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) => _serialize(() async {
    final current = await future;
    final reminder = Reminder(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      type: ReminderType.customReminder,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      createdAt: DateTime.now(),
    );
    await _commit([...current, reminder]);
  });

  Future<void> remove(String id) => _serialize(() async {
    final current = await future;
    await _commit(current.where((reminder) => reminder.id != id).toList());
  });

  Future<TestNotificationReport> sendTestNotification() => _service.sendTest();
}

final remindersControllerProvider =
    AsyncNotifierProvider<RemindersController, List<Reminder>>(
      RemindersController.new,
    );

final reminderScheduleReportProvider = StateProvider<ReminderScheduleReport>(
  (ref) => const ReminderScheduleReport.none(),
);

final reminderSaveErrorProvider = StateProvider<String?>((ref) => null);
