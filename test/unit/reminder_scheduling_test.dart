import 'package:cyclecare/core/services/notification_access.dart';
import 'package:cyclecare/core/services/notification_service.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cyclecare/features/reminders/application/reminders_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotificationGateway implements NotificationGateway {
  bool enabled = true;
  bool exact = true;
  bool rejectSchedule = false;
  bool rejectTest = false;
  int permissionRequests = 0;
  int testRequests = 0;
  final scheduled = <ScheduleRequest>[];
  final cancelled = <int>[];
  final exactModes = <bool>[];
  @override
  bool get canOpenSystemSettings => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool?> notificationsEnabled() async => enabled;
  @override
  Future<bool?> exactAlarmsAllowed() async => exact;
  @override
  Future<bool?> requestNotificationPermission() async {
    permissionRequests++;
    return enabled;
  }

  @override
  Future<bool> openSystemSettings() async => true;
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> schedule(ScheduleRequest request, {required bool exact}) async {
    if (rejectSchedule) throw StateError('scheduler refused');
    scheduled.add(request);
    exactModes.add(exact);
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    if (rejectTest) throw StateError('posting refused');
    testRequests++;
  }
}

const daily = Reminder(
  id: 'daily',
  type: ReminderType.dailyLogReminder,
  title: 'Daily',
  body: 'Check in',
  hour: 20,
  minute: 15,
);
const period = Reminder(
  id: 'period',
  type: ReminderType.periodReminder,
  title: 'Period',
  body: 'Estimated period',
  hour: 8,
  minute: 30,
  daysBefore: 3,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 11, 2, 10);
  late FakeNotificationGateway gateway;
  late NotificationService service;
  late CyclePrediction prediction;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gateway = FakeNotificationGateway();
    service = NotificationService(gateway: gateway, clock: () => now);
    prediction = const CyclePredictionService().buildPrediction(
      periods: [CycleEvent(id: 'p', startDate: DateTime(2026, 10, 20))],
      preferences: const CyclePreferences(),
      referenceDate: now,
    )!;
  });

  test(
    'cycle dates use their own anchor and notice, without daily repetition',
    () async {
      final reminders = [
        period,
        period.copyWith(
          id: 'ovulation',
          type: ReminderType.ovulationReminder,
          daysBefore: 2,
        ),
        period.copyWith(
          id: 'fertile',
          type: ReminderType.fertileWindowReminder,
          daysBefore: 1,
        ),
      ];
      final earlier = NotificationService(
        gateway: gateway,
        clock: () => DateTime(2026, 10, 21),
      );
      final report = await earlier.saveReminders(
        reminders,
        prediction: prediction,
      );
      expect(report.accepted, 3);
      expect(gateway.scheduled.every((r) => !r.repeatDaily), isTrue);
      final anchors = [
        prediction.nextPeriodStart,
        prediction.ovulationDate,
        prediction.fertileWindowStart,
      ];
      for (var i = 0; i < reminders.length; i++) {
        final anchor = anchors[i];
        expect(
          gateway.scheduled[i].when,
          DateTime(
            anchor.year,
            anchor.month,
            anchor.day - reminders[i].daysBefore!,
            8,
            30,
          ),
        );
      }
    },
  );

  test(
    'daily clock reminders repeat; elapsed clock rolls to tomorrow',
    () async {
      await service.saveReminders([
        daily,
        daily.copyWith(id: 'morning', hour: 8),
      ]);
      expect(gateway.scheduled[0].when, DateTime(2026, 11, 2, 20, 15));
      expect(gateway.scheduled[1].when, DateTime(2026, 11, 3, 8, 15));
      expect(gateway.scheduled.every((r) => r.repeatDaily), isTrue);
    },
  );

  test(
    'missing history and elapsed cycle notice are skipped instead of repeating daily',
    () async {
      expect((await service.saveReminders([period])).skipped, hasLength(1));
      final lateService = NotificationService(
        gateway: gateway,
        clock: () => DateTime(2027, 1, 1),
      );
      expect(
        (await lateService.saveReminders([
          period,
        ], prediction: prediction)).skipped,
        hasLength(1),
      );
      expect(gateway.scheduled, isEmpty);
    },
  );

  test(
    'permission is contextual and denied state is distinct from not requested',
    () async {
      gateway.enabled = false;
      await service.initialize();
      expect(gateway.permissionRequests, 0);
      expect(
        (await service.environment()).access,
        NotificationAccess.notRequested,
      );
      await service.requestPermission();
      expect(gateway.permissionRequests, 1);
      expect((await service.environment()).access, NotificationAccess.denied);
      final report = await service.saveReminders([daily]);
      expect(report.accepted, 0);
      expect(report.skipped, hasLength(1));
      expect(gateway.scheduled, isEmpty);
      expect((await service.loadReminders()).single.enabled, isTrue);
    },
  );

  test(
    'no exact alarm permission uses approximate scheduling and reports it',
    () async {
      gateway.exact = false;
      final report = await service.saveReminders([daily]);
      expect(report.accepted, 1);
      expect(report.approximate, isTrue);
      expect(gateway.exactModes, [false]);
    },
  );

  test(
    'scheduler failure preserves saved choices and supports retry',
    () async {
      gateway.rejectSchedule = true;
      final report = await service.saveReminders([daily]);
      expect(report.accepted, 0);
      expect(report.failures, hasLength(1));
      expect((await service.loadReminders()).single.id, 'daily');
      gateway.rejectSchedule = false;
      expect(
        (await service.reschedule(await service.loadReminders())).accepted,
        1,
      );
    },
  );

  test(
    'deleting cancels previous owned IDs and preserves unrelated notifications',
    () async {
      await service.saveReminders([daily]);
      gateway.cancelled.clear();
      await service.saveReminders([]);
      expect(gateway.cancelled, [NotificationService.notificationId('daily')]);
      expect(gateway.cancelled, isNot(contains(12345)));
    },
  );

  test('IDs are positive and remain the same across service instances', () {
    expect(NotificationService.notificationId('daily'), 47788555);
    expect(
      NotificationService.notificationId('daily'),
      inInclusiveRange(0, 0x7fffffff),
    );
    expect(
      NotificationService.notificationId('daily'),
      NotificationService.notificationId('daily'),
    );
    expect(
      NotificationService.notificationId('daily'),
      isNot(NotificationService.notificationId('pill')),
    );
  });

  test(
    'test reports system acceptance or denial without claiming delivery',
    () async {
      expect((await service.sendTest()).handedToSystem, isTrue);
      expect(gateway.testRequests, 1);
      gateway.rejectTest = true;
      expect((await service.sendTest()).failureReason, isNotNull);
      gateway.enabled = false;
      await service.requestPermission();
      expect((await service.sendTest()).handedToSystem, isFalse);
    },
  );

  test('first sync retires legacy reminder alarms once', () async {
    await service.reschedule([daily]);
    expect(gateway.cancelled, contains('daily'.hashCode));
    gateway.cancelled.clear();
    await service.reschedule([daily]);
    expect(gateway.cancelled, [NotificationService.notificationId('daily')]);
  });

  test('invalid times are rejected before replacing saved reminders', () async {
    await service.saveReminders([daily]);
    await expectLater(
      service.saveReminders([daily.copyWith(hour: 25)]),
      throwsArgumentError,
    );
    expect((await service.loadReminders()).single.hour, 20);
  });

  test('rapid concurrent edits preserve both changes', () async {
    await service.saveReminders([daily.copyWith(enabled: false)]);
    final container = ProviderContainer(
      overrides: [notificationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(remindersControllerProvider.future);
    final controller = container.read(remindersControllerProvider.notifier);
    await Future.wait([
      controller.setEnabled('daily', true),
      controller.setTime('daily', 6, 45),
    ]);
    final saved = (await service.loadReminders()).single;
    expect(saved.enabled, isTrue);
    expect(saved.hour, 6);
    expect(saved.minute, 45);
  });

  test('first-run defaults honor onboarding reminder choices', () async {
    final reminders = await service.loadReminders(
      preferences: const CyclePreferences(
        periodReminderEnabled: false,
        dailyLogReminderEnabled: true,
      ),
    );
    expect(
      reminders
          .firstWhere((r) => r.type == ReminderType.periodReminder)
          .enabled,
      isFalse,
    );
    expect(
      reminders
          .firstWhere((r) => r.type == ReminderType.dailyLogReminder)
          .enabled,
      isTrue,
    );
  });
}
