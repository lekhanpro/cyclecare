import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show immutable, kIsWeb;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as system;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _timeZonesInitialized = false;

/// Android can return legacy IANA names such as Asia/Calcutta. The compact
/// database omits some aliases, so scheduling must use the complete database.
tz.Location notificationTimeZone(String identifier) {
  if (!_timeZonesInitialized) {
    tzdata.initializeTimeZones();
    _timeZonesInitialized = true;
  }
  return tz.getLocation(identifier);
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification access and delivery honesty
//
// CycleCare schedules reminders on the device through flutter_local_notifications.
// There is no server and no push. That means the app can say exactly one true
// thing about a reminder: whether the operating system accepted the schedule.
// Whether anything ever appears is decided later, by the OS, and depends on the
// per-app notification switch, battery optimisation and — on Android 12+ — the
// exact-alarm permission.
//
// So nothing in this file returns a bare `void` or a bare `bool` named
// "success". Every call that crosses into the platform comes back with what was
// asked, what the OS accepted, and what failed with the reason. The UI is then
// able to report "handed to Android" rather than "delivered", which is the only
// claim the app can actually support.
//
// The platform calls sit behind [NotificationGateway] so the reminder flows can
// be tested against a denied permission or a refusing scheduler without a
// device. [PluginNotificationGateway] is the real one.
// ─────────────────────────────────────────────────────────────────────────────

/// What the operating system has told us about posting notifications.
///
/// [notRequested] and [denied] are deliberately separate. Android reports both
/// as "notifications are not enabled", but they need opposite interfaces: one
/// asks for permission, the other has already been refused and can only be
/// fixed in system settings. Collapsing them is why apps show a permission
/// prompt that can no longer appear.
enum NotificationAccess {
  /// The app has never asked. A prompt is still possible.
  notRequested,

  /// The OS says CycleCare may post notifications.
  granted,

  /// Asked and refused, or switched off later in system settings. Only the
  /// system settings screen can change this.
  denied,

  /// The platform exposes no per-app switch we can read, so the app must not
  /// claim to know either way.
  unsupported,
}

/// Everything known about whether a scheduled reminder can actually arrive.
@immutable
class NotificationEnvironment {
  const NotificationEnvironment({
    required this.access,
    required this.exactAlarms,
    required this.canOpenSystemSettings,
  });

  /// Before the platform has been asked. Not a claim that anything is wrong.
  const NotificationEnvironment.unknown()
    : access = NotificationAccess.unsupported,
      exactAlarms = true,
      canOpenSystemSettings = false;

  final NotificationAccess access;

  /// Whether the OS will honour a to-the-minute alarm. When false, Android
  /// batches the notification into a maintenance window, so a reminder set for
  /// 8:00 may arrive meaningfully later. The schedule still succeeds.
  final bool exactAlarms;

  /// Whether this platform can deep-link to the app's own notification
  /// settings. False means the recovery copy has to describe the path instead
  /// of offering a button that would do nothing.
  final bool canOpenSystemSettings;

  /// The OS has refused. A reminder switched on now will be scheduled and will
  /// not appear.
  bool get blocked => access == NotificationAccess.denied;

  /// A prompt is still available.
  bool get canRequest => access == NotificationAccess.notRequested;

  /// Known to be allowed. Still not a promise of delivery — battery
  /// optimisation and exact-alarm limits apply on top of this.
  bool get allowed => access == NotificationAccess.granted;

  NotificationEnvironment copyWith({
    NotificationAccess? access,
    bool? exactAlarms,
    bool? canOpenSystemSettings,
  }) => NotificationEnvironment(
    access: access ?? this.access,
    exactAlarms: exactAlarms ?? this.exactAlarms,
    canOpenSystemSettings: canOpenSystemSettings ?? this.canOpenSystemSettings,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationEnvironment &&
      other.access == access &&
      other.exactAlarms == exactAlarms &&
      other.canOpenSystemSettings == canOpenSystemSettings;

  @override
  int get hashCode => Object.hash(access, exactAlarms, canOpenSystemSettings);
}

/// One reminder the OS would not take, and why.
@immutable
class ScheduleFailure {
  const ScheduleFailure({
    required this.reminderId,
    required this.reminderTitle,
    required this.reason,
  });

  final String reminderId;
  final String reminderTitle;

  /// Written for the person, not for a log. It appears in the interface.
  final String reason;
}

/// A reminder that was intentionally not scheduled, with the reason stated.
///
/// Separate from [ScheduleFailure]: nothing went wrong, there is simply nothing
/// to schedule yet — a period heads-up with no recorded period has no date to
/// count back from. Saying so is what stops the row claiming it is armed.
@immutable
class ScheduleSkip {
  const ScheduleSkip({
    required this.reminderId,
    required this.reminderTitle,
    required this.reason,
  });

  final String reminderId;
  final String reminderTitle;
  final String reason;
}

/// The result of persisting reminders and asking the OS to schedule them.
@immutable
class ReminderScheduleReport {
  const ReminderScheduleReport({
    required this.environment,
    required this.requested,
    required this.accepted,
    required this.failures,
    required this.skipped,
  });

  const ReminderScheduleReport.none()
    : environment = const NotificationEnvironment.unknown(),
      requested = 0,
      accepted = 0,
      failures = const [],
      skipped = const [];

  final NotificationEnvironment environment;

  /// Reminders that were switched on, and so had a schedule attempted.
  final int requested;

  /// Reminders the OS accepted. "Accepted", never "delivered".
  final int accepted;

  final List<ScheduleFailure> failures;
  final List<ScheduleSkip> skipped;

  bool get hasFailures => failures.isNotEmpty;
  bool get hasSkips => skipped.isNotEmpty;

  /// Everything switched on was taken by the OS. Says nothing about arrival.
  bool get fullyAccepted => failures.isEmpty && skipped.isEmpty;

  /// Timing may drift because exact alarms are unavailable.
  bool get approximate => accepted > 0 && !environment.exactAlarms;
}

/// The result of an immediate test notification.
///
/// [handedToSystem] is the honest ceiling: the OS took the request without
/// error. It is not evidence that a notification appeared, which is why the
/// interface pairs it with "if nothing appears, access is off".
@immutable
class TestNotificationReport {
  const TestNotificationReport({
    required this.handedToSystem,
    required this.environment,
    this.failureReason,
  });

  final bool handedToSystem;
  final NotificationEnvironment environment;

  /// Set when the platform call threw, or when access is known to be refused
  /// so there was no point asking.
  final String? failureReason;

  /// The OS took it and is known to be allowed to show it. Still not delivery.
  bool get plausiblyVisible => handedToSystem && !environment.blocked;
}

/// One scheduling request, resolved by the service and executed by a gateway.
@immutable
class ScheduleRequest {
  const ScheduleRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.repeatDaily,
  });

  final int id;
  final String title;
  final String body;
  final DateTime when;
  final String channelId;
  final String channelName;
  final String channelDescription;

  /// Daily reminders repeat at the same clock time. A reminder anchored to a
  /// predicted date is a one-shot: it is rescheduled when the estimate moves.
  final bool repeatDaily;
}

/// The platform calls the reminder flows depend on.
///
/// An interface rather than direct plugin use, so "permission denied" and
/// "the scheduler refused" are states a test can produce.
abstract class NotificationGateway {
  /// Prepares the plugin and timezone data. Must not request permission:
  /// the prompt belongs to a moment the person chose, not to app start.
  Future<void> initialize();

  /// The OS's current answer, or null where the platform cannot say.
  Future<bool?> notificationsEnabled();

  /// Shows the system permission prompt. Null where there is nothing to ask.
  Future<bool?> requestNotificationPermission();

  /// Whether to-the-minute alarms are permitted. Null means "not applicable",
  /// which is treated as exact.
  Future<bool?> exactAlarmsAllowed();

  /// Asks the OS to post [request] later. Throws if it refuses.
  Future<void> schedule(ScheduleRequest request, {required bool exact});

  /// Asks the OS to post a notification now. Throws if it refuses.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  });

  Future<void> cancel(int id);

  /// Opens the app's own system settings. False when the platform has none.
  Future<bool> openSystemSettings();

  /// Whether [openSystemSettings] can do anything on this platform.
  bool get canOpenSystemSettings;
}

/// The real gateway: flutter_local_notifications, plus permission_handler for
/// the one thing the notification plugin cannot do — open system settings.
class PluginNotificationGateway implements NotificationGateway {
  PluginNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  bool get canOpenSystemSettings => _isAndroid || _isIOS;

  @override
  Future<void> initialize() async {
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(notificationTimeZone(zone.identifier));
    if (_initialized) return;

    // Every `request*Permission` flag is false on purpose. The Darwin
    // initializer requests at startup when they are true, which spends the
    // one prompt iOS allows before the person has seen a single reminder.
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  @override
  Future<bool?> notificationsEnabled() async {
    if (_isAndroid) return _android?.areNotificationsEnabled();
    if (_isIOS) {
      final options = await _ios?.checkPermissions();
      return options?.isEnabled;
    }
    return null;
  }

  @override
  Future<bool?> requestNotificationPermission() async {
    if (_isAndroid) return _android?.requestNotificationsPermission();
    if (_isIOS) {
      return _ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return null;
  }

  @override
  Future<bool?> exactAlarmsAllowed() async {
    if (!_isAndroid) return null;
    return _android?.canScheduleExactNotifications();
  }

  @override
  Future<void> schedule(ScheduleRequest request, {required bool exact}) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        request.channelId,
        request.channelName,
        channelDescription: request.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      request.id,
      request.title,
      request.body,
      tz.TZDateTime.from(request.when, tz.local),
      details,
      // Falling back to inexact rather than throwing: a reminder that arrives
      // in the next maintenance window is worth far more than no reminder, and
      // the drift is reported instead of hidden.
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: request.repeatDaily
          ? DateTimeComponents.time
          : null,
    );
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<bool> openSystemSettings() async {
    if (!canOpenSystemSettings) return false;
    try {
      return await system.openAppSettings();
    } catch (_) {
      // A missing plugin or a host that refuses the intent. Reported as "could
      // not open" so the screen falls back to describing the path.
      return false;
    }
  }
}
