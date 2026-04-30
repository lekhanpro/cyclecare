import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

enum ReminderType {
  periodReminder,
  ovulationReminder,
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
  }) =>
      Reminder(
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

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _remindersKey = 'cyclecare.reminders.v1';

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<List<Reminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_remindersKey);
    if (raw == null) return _defaultReminders();
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Reminder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _remindersKey,
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    );
    await _rescheduleAll(reminders);
  }

  Future<void> _rescheduleAll(List<Reminder> reminders) async {
    await _plugin.cancelAll();
    for (final reminder in reminders) {
      if (reminder.enabled) {
        await _scheduleReminder(reminder);
      }
    }
  }

  Future<void> _scheduleReminder(Reminder reminder) async {
    final androidDetails = AndroidNotificationDetails(
      'cyclecare_${reminder.type.name}',
      _channelName(reminder.type),
      channelDescription: _channelDescription(reminder.type),
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, reminder.hour, reminder.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      reminder.id.hashCode,
      reminder.title,
      reminder.body,
      tz.TZDateTime.from(scheduled, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final androidDetails = const AndroidNotificationDetails(
      'cyclecare_custom',
      'Custom Reminders',
      channelDescription: 'One-time and custom reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String id) async {
    await _plugin.cancel(id.hashCode);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
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
      ReminderType.pillReminder => 'Birth Control',
      ReminderType.customReminder => 'Custom Reminders',
    };
  }

  String _channelDescription(ReminderType type) {
    return switch (type) {
      ReminderType.periodReminder => 'Reminders for upcoming periods',
      ReminderType.ovulationReminder => 'Fertile window and ovulation alerts',
      ReminderType.pillReminder => 'Daily birth control pill reminders',
      ReminderType.customReminder => 'User-created custom reminders',
    };
  }
}
