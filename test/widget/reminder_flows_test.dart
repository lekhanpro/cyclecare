import 'package:cyclecare/core/services/notification_access.dart';
import 'package:cyclecare/core/services/notification_service.dart';
import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/reminders/application/reminders_controller.dart';
import 'package:cyclecare/features/reminders/reminders_screen.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../unit/reminder_scheduling_test.dart' show FakeNotificationGateway;

class _FailingSaveService extends NotificationService {
  _FailingSaveService(FakeNotificationGateway gateway)
    : super(gateway: gateway);
  bool failNext = true;
  @override
  Future<ReminderScheduleReport> saveReminders(
    List<Reminder> reminders, {
    CyclePrediction? prediction,
  }) async {
    if (failNext) {
      failNext = false;
      throw StateError('disk unavailable');
    }
    return super.saveReminders(reminders, prediction: prediction);
  }
}

Widget _app(NotificationService service, {double scale = 1}) => ProviderScope(
  overrides: [notificationServiceProvider.overrideWithValue(service)],
  child: MaterialApp(
    theme: AppTheme.light(const Color(0xff79516a)),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: const RemindersScreen(),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'permission recovery is contextual and fits narrow large-text screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final gateway = FakeNotificationGateway()..enabled = false;
      await tester.pumpWidget(
        _app(NotificationService(gateway: gateway), scale: 2),
      );
      await tester.pumpAndSettle();
      expect(gateway.permissionRequests, 0);
      await tester.scrollUntilVisible(
        find.text('Allow notifications'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Allow notifications'));
      await tester.pumpAndSettle();
      expect(gateway.permissionRequests, 1);
      expect(find.text('Notifications are blocked'), findsOneWidget);
      expect(find.text('Open system settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed toggle preserves state and offers retry', (tester) async {
    tester.view.physicalSize = const Size(700, 2500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _FailingSaveService(FakeNotificationGateway());
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(find.text('Change not saved'), findsOneWidget);
    await tester.tap(find.text('Retry change'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    expect(find.text('Change not saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled custom reminder can be edited and deleted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = NotificationService(gateway: FakeNotificationGateway());
    await service.saveReminders([
      const Reminder(
        id: 'custom',
        type: ReminderType.customReminder,
        title: 'Original',
        body: 'Original message',
        hour: 9,
        minute: 0,
        enabled: false,
      ),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit reminder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Updated name');
    await tester.enterText(find.byType(TextField).last, 'Updated message');
    await tester.tap(find.text('Save reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Updated name'), findsOneWidget);
    expect((await service.loadReminders()).single.enabled, isFalse);
    expect((await service.loadReminders()).single.body, 'Updated message');
    await tester.tap(find.text('Delete reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this reminder?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('test feedback reports system acceptance', (tester) async {
    final gateway = FakeNotificationGateway();
    await tester.pumpWidget(_app(NotificationService(gateway: gateway)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Send a test notification'));
    await tester.pump();
    expect(
      find.text('Test accepted by the system. Check whether it appears.'),
      findsOneWidget,
    );
    expect(gateway.testRequests, 1);
    expect(tester.takeException(), isNull);
  });
}
