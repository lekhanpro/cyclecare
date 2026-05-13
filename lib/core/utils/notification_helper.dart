import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../constants/app_constants.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createChannels();
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
  }

  static Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.periodReminderChannel,
      'Period Reminders',
      description: 'Notifications about upcoming periods',
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.pillReminderChannel,
      'Pill Reminders',
      description: 'Daily pill reminders',
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.healthReminderChannel,
      'Health Reminders',
      description: 'Health and wellness reminders',
      importance: Importance.defaultImportance,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.appointmentChannel,
      'Appointment Reminders',
      description: 'Upcoming appointment reminders',
      importance: Importance.high,
    ));
  }

  static Future<void> schedulePeriodReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.periodReminderChannel,
          'Period Reminders',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            const AndroidNotificationAction('snooze', 'Snooze'),
            const AndroidNotificationAction('dismiss', 'Dismiss'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  static Future<void> schedulePillReminder({
    required int id,
    required String pillName,
    required DateTime time,
  }) async {
    await _plugin.zonedSchedule(
      id,
      'Time to take your pill',
      pillName,
      tz.TZDateTime.from(time, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.pillReminderChannel,
          'Pill Reminders',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            const AndroidNotificationAction('taken', 'Mark as Taken'),
            const AndroidNotificationAction('snooze', 'Snooze 15min'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleAppointmentReminder({
    required int id,
    required String title,
    required String details,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      details,
      tz.TZDateTime.from(
        scheduledDate.subtract(const Duration(hours: 1)),
        tz.local,
      ),
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.appointmentChannel,
          'Appointment Reminders',
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String channel = AppConstants.healthReminderChannel,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(channel, 'Notifications'),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelNotification(int id) => _plugin.cancel(id);
  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }
}
