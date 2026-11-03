import 'package:flutter/material.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../article_sources.dart';
import 'article_block.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The article model
//
// Lifted out of education_screen.dart, which held the model, the content and
// the layout in one 1,600-line file. The reading view needs the body as typed
// blocks rather than a string, and a string body can only be parsed inside a
// build method — so the parse happens once here, at construction, and the
// layout is handed structure.
//
// Articles are therefore `final` rather than `const`. The cost is one parse of
// 40-odd short bodies at first use of the catalogue; the gain is that search
// has a prepared haystack instead of lowercasing every body on every keystroke,
// and the reading view has blocks instead of a parser.
// ─────────────────────────────────────────────────────────────────────────────

enum ArticleCategory {
  basics('Cycle basics', AppIcons.basics),
  fertility('Fertility', AppIcons.fertile),
  symptoms('Symptoms', AppIcons.symptoms),
  nutrition('Nutrition', AppIcons.nutrition),
  conditions('Conditions', AppIcons.conditions),
  wellbeing('Wellbeing', AppIcons.wellbeing);

  const ArticleCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// A distinct hue per category so the list is scannable without reading.
  ///
  /// Deliberately not the palette accent: forty cards in one colour give the
  /// eye nothing to sort by. The semantic cycle hues are reused because they
  /// are already learned elsewhere in the app.
  Color get seed => switch (this) {
    ArticleCategory.basics => AppColors.period,
    ArticleCategory.fertility => AppColors.fertile,
    ArticleCategory.symptoms => AppColors.ovulation,
    ArticleCategory.nutrition => AppColors.success,
    ArticleCategory.conditions => AppColors.info,
    ArticleCategory.wellbeing => AppColors.luteal,
  };

  /// [seed], lifted for legibility on a near-black surface. The raw hues are
  /// tuned for cream and go muddy in dark mode.
  ///
  /// This is the *wash* role: fills, borders, icon plates. For anything set as
  /// type on top of one of those washes, use [inkTone].
  Color tone(BuildContext context) {
    if (!context.isDark) return seed;
    final hsl = HSLColor.fromColor(seed);
    return hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
  }

  /// [seed] pushed to body-text contrast.
  ///
  /// Four of the six hues are pastels — luteal peach and mint sit above 70%
  /// lightness — so a category label painted in the raw seed on its own pale
  /// wash lands near 2:1 and is unreadable at label size. Darkening toward the
  /// app ink keeps the hue recognisable while clearing AA; dark mode needs the
  /// opposite move and so keeps the lifted [tone].
  Color inkTone(BuildContext context) =>
      context.isDark ? tone(context) : Color.lerp(seed, AppColors.ink, 0.55)!;
}

@immutable
class Article {
  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.readMinutes,
    required this.standfirst,
    required this.body,
  }) : blocks = parseArticleBody(body),
       _haystack = [
         title,
         standfirst,
         category.label,
         body,
       ].join('\n').toLowerCase();

  final String id;
  final String title;
  final ArticleCategory category;

  /// The article's own glyph, distinct from its category's. Two articles in one
  /// category are told apart by this before the title is read, which is what
  /// keeps a filtered list from reading as four identical rows.
  final IconData icon;

  /// Rounded reading-time estimate. Set by hand rather than computed from word
  /// count — some of these are dense and read slower than their length says.
  final int readMinutes;

  /// One sentence under the title, in the reading view and on the row.
  ///
  /// Named for the thing it is in the design rather than "summary": it leads
  /// the reader in, and is not a précis of what follows.
  final String standfirst;

  String get summary => standfirst;

  /// The authored markup, kept beside [blocks].
  ///
  /// Two readers: search, which wants one flat string, and the migration test,
  /// which parses it and serialises the blocks back to compare. Nothing in the
  /// UI should read this — the UI reads [blocks].
  final String body;

  /// [body], parsed once. See `article_block.dart` for the syntax.
  final List<ArticleBlock> blocks;

  final String _haystack;

  /// The sources attached to this article, or an empty list if none are.
  ///
  /// Read from `kArticleSources` rather than stored on the article, so a
  /// citation can only ever come from the verified table.
  List<ArticleSource> get sources =>
      kArticleSources[id] ?? const <ArticleSource>[];

  /// [blocks] with the sources appended as a final block, for a reading layout
  /// that wants one list to walk.
  List<ArticleBlock> get blocksWithSources => [
    ...blocks,
    if (sources.isNotEmpty) ArticleSourceList(sources),
  ];

  /// "Wellbeing · 3 min read", the meta line the row and reading view share.
  String get meta => '${category.label} · $readMinutes min read';

  /// Whether this article matches an already-lowercased query.
  ///
  /// The haystack is built once at construction, so a query costs one substring
  /// search per article rather than lowercasing every body again.
  bool matches(String lowercaseQuery) =>
      lowercaseQuery.isEmpty || _haystack.contains(lowercaseQuery);
}
