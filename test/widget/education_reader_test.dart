import 'package:cyclecare/features/education/application/education_controller.dart';
import 'package:cyclecare/features/education/education_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shots/shot_harness.dart';

void main() {
  testWidgets(
    'offline reader preserves sources, bookmark and opened progress',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final article = kArticles.firstWhere(
        (a) => a.id == 'fertility-awareness',
      );
      await pumpShotScreen(
        tester,
        ArticleReaderScreen(article: article),
        width: 320,
        height: 1600,
        textScale: 2,
      );
      expect(find.text(article.title), findsOneWidget);
      await tester.tap(find.byTooltip('Save article'));
      await settleShot(tester);
      expect(find.byTooltip('Remove bookmark'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 4));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(educationBookmarksProvider);
      container.read(educationProgressProvider);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      expect(container.read(educationBookmarksProvider), contains(article.id));
      expect(container.read(educationProgressProvider), contains(article.id));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'structured lists and callouts render at 200 percent in dark mode',
    (tester) async {
      final article = Article(
        id: 'reader-test',
        title: 'Reading your own records',
        category: ArticleCategory.basics,
        icon: Icons.article,
        readMinutes: 2,
        standfirst: 'Offline education',
        body:
            '## Your notes\n- Recorded\n- Estimated\n> Context\n>! Seek support\n>> Your choice',
      );
      await pumpShotScreen(
        tester,
        ArticleReaderScreen(article: article),
        dark: true,
        width: 320,
        height: 2400,
        textScale: 2,
      );
      for (final label in [
        'Your notes',
        'Recorded',
        'Estimated',
        'Note',
        'Worth knowing',
        'Remember',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 4));
    },
  );
}
