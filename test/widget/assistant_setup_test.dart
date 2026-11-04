import 'package:cyclecare/features/ai/ai_connection.dart';
import 'package:cyclecare/features/ai/ai_connection_screen.dart';
import 'package:cyclecare/features/ai/ai_chat_screen.dart';
import 'package:cyclecare/core/theme/cyclecare_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets(
    'assistant connection wraps at compact 200 percent and removes its key',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(aiConnectionProvider.future);
      await container
          .read(aiConnectionProvider.notifier)
          .save(
            const AIConnection(
              provider: AssistantProvider.gemini,
              key: 'dummy-only',
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark(const Color(0xff76415d)),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const AIConnectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Your Gemini API key'), 220,
        scrollable: find.byType(Scrollable).first);
      expect(find.text('Your Gemini API key'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Remove connection & key'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Remove connection & key'));
      await tester.pumpAndSettle();
      expect(
        container.read(aiConnectionProvider).requireValue.provider,
        AssistantProvider.library,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'offline helper works without a remote provider and states its limits',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AIChatScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Learning helper'), findsOneWidget);
      expect(find.textContaining('not generative AI'), findsOneWidget);
      await tester.tap(find.text('Can stress change my cycle?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline library excerpts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
