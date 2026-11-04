import 'package:cyclecare/core/router/app_router.dart';
import 'package:cyclecare/features/tracking/application/cycle_tracker_controller.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('completing onboarding refreshes into the mode introduction and tour offer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container=ProviderContainer();addTearDown(container.dispose);
    await container.read(cycleTrackerControllerProvider.future);
    final router=container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container:container,child:MaterialApp.router(routerConfig:router)));
    await tester.pumpAndSettle();
    router.go('/onboarding');await tester.pumpAndSettle();
    await container.read(cycleTrackerControllerProvider.notifier).completeOnboarding(
      lastPeriodStart:null,cycleLength:28,periodLength:5,goal:TrackingGoal.trackPeriods,profileName:'');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,'/mode-introduction');
    expect(router.routeInformationProvider.value.uri.queryParameters['tour'],'1');
    expect(find.text('Your tracking mode'),findsOneWidget);
  });
  testWidgets('new user can enter the separate partner dashboard without onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container=ProviderContainer();addTearDown(container.dispose);
    await container.read(cycleTrackerControllerProvider.future);
    final router=container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container:container,child:MaterialApp.router(routerConfig:router)));
    await tester.pumpAndSettle();
    expect(find.text('I’m here as a partner'),findsOneWidget);
    await tester.ensureVisible(find.text('I’m here as a partner'));
    await tester.tap(find.text('I’m here as a partner'));
    await tester.pumpAndSettle();
    expect(find.text('Partner dashboard'),findsOneWidget);
    expect(find.text('Home'),findsWidgets);
  });
  testWidgets('partner start preference restores the partner dashboard after restart', (tester) async {
    SharedPreferences.setMockInitialValues({'cc.partner.start_as_partner':true});
    final container=ProviderContainer();addTearDown(container.dispose);
    await container.read(cycleTrackerControllerProvider.future);
    final router=container.read(appRouterProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container:container,child:MaterialApp.router(routerConfig:router)));
    await tester.pumpAndSettle();
    expect(find.text('Partner dashboard'),findsOneWidget);
    expect(find.text('I’m here as a partner'),findsNothing);
  });
}
