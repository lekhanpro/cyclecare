import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';

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

  @override
  Future<List<Reminder>> build() async {
    // Initialising here rather than in main() means the permission prompt lands
    // when the user opens reminders — a moment where the request has obvious
    // context — instead of during a cold start.
    await _service.initialize();
    return _service.loadReminders();
  }

  /// Persists [reminders] and reschedules every OS notification to match.
  Future<void> _commit(List<Reminder> reminders) async {
    state = AsyncData(reminders);
    await _service.saveReminders(reminders);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final current = state.valueOrNull ?? const [];
    await _commit([
      for (final reminder in current)
        if (reminder.id == id) reminder.copyWith(enabled: enabled) else reminder,
    ]);
  }

  Future<void> setTime(String id, int hour, int minute) async {
    final current = state.valueOrNull ?? const [];
    await _commit([
      for (final reminder in current)
        if (reminder.id == id)
          reminder.copyWith(hour: hour, minute: minute)
        else
          reminder,
    ]);
  }

  Future<void> setDaysBefore(String id, int daysBefore) async {
    final current = state.valueOrNull ?? const [];
    await _commit([
      for (final reminder in current)
        if (reminder.id == id)
          reminder.copyWith(daysBefore: daysBefore)
        else
          reminder,
    ]);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final current = state.valueOrNull ?? const [];
    await _commit([
      for (final existing in current)
        if (existing.id == reminder.id) reminder else existing,
    ]);
  }

  Future<void> addCustom({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final current = state.valueOrNull ?? const [];
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
  }

  Future<void> remove(String id) async {
    final current = state.valueOrNull ?? const [];
    // Cancelling explicitly as well as rescheduling: `saveReminders` cancels
    // everything before re-adding the enabled ones, but being explicit here
    // means a failure partway through still leaves the deleted one silent.
    await _service.cancelReminder(id);
    await _commit(current.where((reminder) => reminder.id != id).toList());
  }

  /// Fires a notification immediately so the user can confirm the OS is
  /// actually allowed to show them. Silent permission denial is the most common
  /// reason a reminder "does not work".
  Future<void> sendTestNotification() async {
    await _service.showInstantNotification(
      title: 'CycleCare reminders are working',
      body: 'This is what your reminders will look like.',
    );
  }
}

final remindersControllerProvider =
    AsyncNotifierProvider<RemindersController, List<Reminder>>(
  RemindersController.new,
);
