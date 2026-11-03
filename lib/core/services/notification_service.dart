import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/tracking/domain/cycle_models.dart';
import 'notification_access.dart';

enum ReminderType {
  periodReminder,
  ovulationReminder,
  fertileWindowReminder,
  dailyLogReminder,
  pillReminder,
  customReminder,
}

class Reminder {
  final String id;
  final ReminderType type;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final int? daysBefore; // for period/ovulation reminders
  final bool enabled;
  final DateTime? createdAt;

  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.daysBefore,
    this.enabled = true,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'hour': hour,
    'minute': minute,
    'daysBefore': daysBefore,
    'enabled': enabled,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    type: ReminderType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ReminderType.customReminder,
    ),
    title: json['title'] as String,
    body: json['body'] as String,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    daysBefore: json['daysBefore'] as int?,
    enabled: json['enabled'] as bool? ?? true,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );

  Reminder copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? body,
    int? hour,
    int? minute,
    int? daysBefore,
    bool? enabled,
    DateTime? createdAt,
  }) => Reminder(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    daysBefore: daysBefore ?? this.daysBefore,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
  );
}

/// Local preferences are the desired state; reports describe OS acceptance.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationGateway? gateway,
    DateTime Function()? clock,
  }) : _gateway = gateway ?? PluginNotificationGateway(plugin: plugin),
       _clock = clock ?? DateTime.now;

  final NotificationGateway _gateway;
  final DateTime Function() _clock;
  static const _remindersKey = 'cyclecare.reminders.v1';
  static const _askedKey = 'cyclecare.notifications.asked.v1';
  static const _stableIdsKey = 'cyclecare.notifications.stable_ids.v1';
  ReminderScheduleReport lastReport = const ReminderScheduleReport.none();

  Future<void> initialize() => _gateway.initialize();

  Future<NotificationEnvironment> environment() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final enabled = await _gateway.notificationsEnabled();
    return NotificationEnvironment(
      access: enabled == null
          ? NotificationAccess.unsupported
          : enabled
          ? NotificationAccess.granted
          : prefs.getBool(_askedKey) == true
          ? NotificationAccess.denied
          : NotificationAccess.notRequested,
      exactAlarms: await _gateway.exactAlarmsAllowed() ?? true,
      canOpenSystemSettings: _gateway.canOpenSystemSettings,
    );
  }

  Future<NotificationEnvironment> requestPermission() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(_askedKey, true)) {
      throw StateError('Could not save notification permission choice.');
    }
    await _gateway.requestNotificationPermission();
    return environment();
  }

  Future<bool> openSystemSettings() => _gateway.openSystemSettings();

  Future<List<Reminder>> loadReminders({CyclePreferences? preferences}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_remindersKey);
    if (raw == null) {
      return [
        for (final reminder in _defaultReminders())
          reminder.copyWith(
            enabled: switch (reminder.type) {
              ReminderType.periodReminder =>
                preferences?.periodReminderEnabled ?? reminder.enabled,
              ReminderType.ovulationReminder =>
                preferences?.ovulationReminderEnabled ?? reminder.enabled,
              ReminderType.dailyLogReminder =>
                preferences?.dailyLogReminderEnabled ?? reminder.enabled,
              ReminderType.pillReminder =>
                preferences?.pillReminderEnabled ?? reminder.enabled,
              _ => reminder.enabled,
            },
          ),
      ];
    }
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReminderScheduleReport> saveReminders(
    List<Reminder> reminders, {
    CyclePrediction? prediction,
  }) async {
    for (final reminder in reminders) {
      if (reminder.id.isEmpty ||
          reminder.title.trim().isEmpty ||
          reminder.hour < 0 ||
          reminder.hour > 23 ||
          reminder.minute < 0 ||
          reminder.minute > 59 ||
          (reminder.daysBefore ?? 0) < 0 ||
          (reminder.daysBefore ?? 0) > 30) {
        throw ArgumentError('Reminder name, time or notice is invalid.');
      }
    }
    final previous = await loadReminders();
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _remindersKey,
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    )) {
      throw StateError('Could not save reminders. Please try again.');
    }
    return reschedule(reminders, prediction: prediction, previous: previous);
  }

  Future<ReminderScheduleReport> reschedule(
    List<Reminder> reminders, {
    CyclePrediction? prediction,
    List<Reminder> previous = const [],
  }) async {
    NotificationEnvironment env;
    try {
      env = await environment();
    } catch (_) {
      return lastReport = ReminderScheduleReport(
        environment: const NotificationEnvironment.unknown(),
        requested: reminders.where((r) => r.enabled).length,
        accepted: 0,
        failures: const [
          ScheduleFailure(
            reminderId: 'system',
            reminderTitle: 'Reminders',
            reason:
                'Reminders are saved, but the system scheduler is unavailable. Retry.',
          ),
        ],
        skipped: const [],
      );
    }
    final failures = <ScheduleFailure>[];
    final skipped = <ScheduleSkip>[];
    var accepted = 0;
    final prefs = await SharedPreferences.getInstance();
    final clearLegacyIds = prefs.getBool(_stableIdsKey) != true;
    // Retire alarms created by the former hashCode-based scheduler once.
    // Cancel only IDs owned by reminders, never unrelated appointment alarms.
    for (final id in {
      ...previous.map((r) => r.id),
      ...reminders.map((r) => r.id),
    }) {
      try {
        await _gateway.cancel(notificationId(id));
        if (clearLegacyIds) await _gateway.cancel(id.hashCode);
      } catch (_) {
        failures.add(
          ScheduleFailure(
            reminderId: id,
            reminderTitle: 'Reminder',
            reason: 'The system could not cancel the previous schedule. Retry.',
          ),
        );
      }
    }
    if (clearLegacyIds && failures.isEmpty) {
      await prefs.setBool(_stableIdsKey, true);
    }
    for (final reminder in reminders.where((r) => r.enabled)) {
      final when = plannedTime(reminder, prediction: prediction, now: _clock());
      if (when == null) {
        skipped.add(
          ScheduleSkip(
            reminderId: reminder.id,
            reminderTitle: reminder.title,
            reason: prediction == null
                ? 'Log a period to estimate a reminder date.'
                : 'The notice date has passed. Waiting for a new period estimate.',
          ),
        );
        continue;
      }
      if (env.blocked || env.canRequest) {
        skipped.add(
          ScheduleSkip(
            reminderId: reminder.id,
            reminderTitle: reminder.title,
            reason: 'Allow notifications to schedule this reminder.',
          ),
        );
        continue;
      }
      try {
        await _gateway.schedule(
          ScheduleRequest(
            id: notificationId(reminder.id),
            title: reminder.title,
            body: reminder.body,
            when: when,
            channelId: 'cyclecare_${reminder.type.name}',
            channelName: _channelName(reminder.type),
            channelDescription: _channelDescription(reminder.type),
            repeatDaily: !isCycleReminder(reminder.type),
          ),
          exact: env.exactAlarms,
        );
        accepted++;
      } catch (_) {
        failures.add(
          ScheduleFailure(
            reminderId: reminder.id,
            reminderTitle: reminder.title,
            reason:
                'The system did not accept this schedule. Retry or check system settings.',
          ),
        );
      }
    }
    return lastReport = ReminderScheduleReport(
      environment: env,
      requested: reminders.where((r) => r.enabled).length,
      accepted: accepted,
      failures: failures,
      skipped: skipped,
    );
  }

  static bool isCycleReminder(ReminderType type) => switch (type) {
    ReminderType.periodReminder ||
    ReminderType.ovulationReminder ||
    ReminderType.fertileWindowReminder => true,
    _ => false,
  };

  /// No fabricated rollover for a late cycle: wait until its estimate changes.
  static DateTime? plannedTime(
    Reminder reminder, {
    CyclePrediction? prediction,
    required DateTime now,
  }) {
    if (!isCycleReminder(reminder.type)) {
      var time = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.hour,
        reminder.minute,
      );
      if (!time.isAfter(now)) {
        time = DateTime(
          now.year,
          now.month,
          now.day + 1,
          reminder.hour,
          reminder.minute,
        );
      }
      return time;
    }
    if (prediction == null) return null;
    final anchor = switch (reminder.type) {
      ReminderType.periodReminder => prediction.nextPeriodStart,
      ReminderType.ovulationReminder => prediction.ovulationDate,
      _ => prediction.fertileWindowStart,
    };
    final time = DateTime(
      anchor.year,
      anchor.month,
      anchor.day - (reminder.daysBefore ?? 0),
      reminder.hour,
      reminder.minute,
    );
    return time.isAfter(now) ? time : null;
  }

  /// Stable positive 31-bit FNV-1a ID, independent of Dart runtime hash seeds.
  static int notificationId(String id) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode('cyclecare.reminder.$id')) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final env = await environment();
    await _gateway.schedule(
      ScheduleRequest(
        id: id,
        title: title,
        body: body,
        when: scheduledDate,
        channelId: 'cyclecare_custom',
        channelName: 'Custom Reminders',
        channelDescription: 'One-time reminders',
        repeatDaily: false,
      ),
      exact: env.exactAlarms,
    );
  }

  Future<void> cancelReminder(String id) => _gateway.cancel(notificationId(id));
  Future<void> cancelAll() async {
    final reminders = await loadReminders();
    for (final reminder in reminders) {
      await cancelReminder(reminder.id);
    }
  }

  Future<TestNotificationReport> sendTest() async {
    final env = await environment();
    if (env.blocked || env.canRequest) {
      return TestNotificationReport(
        handedToSystem: false,
        environment: env,
        failureReason: 'Allow notifications first, then send another test.',
      );
    }
    try {
      await showInstantNotification(
        title: 'CycleCare test reminder',
        body: 'If you can read this, your test notification appeared.',
      );
      return TestNotificationReport(handedToSystem: true, environment: env);
    } catch (_) {
      return TestNotificationReport(
        handedToSystem: false,
        environment: env,
        failureReason: 'The system did not accept the test. Try again.',
      );
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    await _gateway.showNow(
      id: 2147483646,
      title: title,
      body: body,
      channelId: 'cyclecare_test',
      channelName: 'CycleCare notifications',
    );
  }

  List<Reminder> _defaultReminders() {
    return [
      const Reminder(
        id: 'period_reminder_default',
        type: ReminderType.periodReminder,
        title: 'Period Reminder',
        body: 'Your period is expected soon. Be prepared!',
        hour: 8,
        minute: 0,
        daysBefore: 3,
        enabled: true,
      ),
      const Reminder(
        id: 'ovulation_reminder_default',
        type: ReminderType.ovulationReminder,
        title: 'Fertility Window',
        body: 'Your fertile window is approaching.',
        hour: 9,
        minute: 0,
        daysBefore: 2,
        enabled: false,
      ),
      const Reminder(
        id: 'fertile_window_reminder_default',
        type: ReminderType.fertileWindowReminder,
        title: 'Fertile Window',
        body: 'Your estimated fertile window starts soon.',
        hour: 9,
        minute: 0,
        daysBefore: 1,
        enabled: false,
      ),
      const Reminder(
        id: 'daily_log_reminder_default',
        type: ReminderType.dailyLogReminder,
        title: 'Daily Check-in',
        body: 'Take a minute to log how you feel today.',
        hour: 20,
        minute: 0,
        enabled: false,
      ),
      const Reminder(
        id: 'pill_reminder_default',
        type: ReminderType.pillReminder,
        title: 'Pill Reminder',
        body: 'Time to take your pill.',
        hour: 21,
        minute: 0,
        enabled: false,
      ),
    ];
  }

  String _channelName(ReminderType type) {
    return switch (type) {
      ReminderType.periodReminder => 'Period Reminders',
      ReminderType.ovulationReminder => 'Ovulation & Fertility',
      ReminderType.fertileWindowReminder => 'Fertile Window',
      ReminderType.dailyLogReminder => 'Daily Logging',
      ReminderType.pillReminder => 'Birth Control',
      ReminderType.customReminder => 'Custom Reminders',
    };
  }

  String _channelDescription(ReminderType type) {
    return switch (type) {
      ReminderType.periodReminder => 'Reminders for upcoming periods',
      ReminderType.ovulationReminder => 'Fertile window and ovulation alerts',
      ReminderType.fertileWindowReminder => 'Fertile window alerts',
      ReminderType.dailyLogReminder => 'Daily tracking reminders',
      ReminderType.pillReminder => 'Daily birth control pill reminders',
      ReminderType.customReminder => 'User-created custom reminders',
    };
  }
}
