import 'package:flutter/foundation.dart';

import '../article_sources.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Article body structure
//
// An article body used to be one string that the reading view re-parsed on
// every build. That worked while the only constructs were a heading and a
// bullet, but it put the content format inside a widget: the layout had to know
// that `## ` means a heading, and anything the design wanted to style
// differently — a pull quote, a note, a list as a unit rather than a run of
// rows — had no way to exist.
//
// So the body is a list of typed blocks. Authors still write the light markup
// below, because it is the only format in which 26 existing articles already
// exist and the cheapest one to proofread, but [parseArticleBody] turns it into
// blocks once and the reading view styles blocks. The parser is the only thing
// that knows the syntax.
//
// Authoring syntax, line by line. Blank lines separate blocks and are dropped:
//
//   ## Heading          a section heading
//   - item              one list item; consecutive items become one list
//   > text              a quiet note the reader can skip
//   >! text             something worth stopping for
//   >> text             a pull quote
//   anything else       a paragraph
//
// `**text**` marks emphasis inside any of them.
// ─────────────────────────────────────────────────────────────────────────────

/// One run of body text, emphasised or not.
///
/// Inline emphasis is parsed here rather than in the reading view for the same
/// reason as the blocks: the view should be handed something to style, not a
/// string to interpret.
@immutable
class ArticleSpan {
  const ArticleSpan(this.text, {this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  bool operator ==(Object other) =>
      other is ArticleSpan && other.text == text && other.emphasis == emphasis;

  @override
  int get hashCode => Object.hash(text, emphasis);

  @override
  String toString() => emphasis ? '**$text**' : text;
}

/// Splits [text] on `**` and alternates between plain and emphasised runs.
///
/// Odd segments are the emphasised ones, so an unclosed marker degrades to an
/// emphasised tail rather than throwing. Empty segments are dropped, which is
/// what makes `**bold**` at the start of a line produce one span and not three.
List<ArticleSpan> parseInlineSpans(String text) {
  final parts = text.split('**');
  final spans = <ArticleSpan>[];
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    spans.add(ArticleSpan(parts[i], emphasis: i.isOdd));
  }
  return List.unmodifiable(spans);
}

/// A block of an article body.
///
/// Sealed so the reading view's switch over block types is exhaustive: adding a
/// block kind here is a compile error at every layout that renders bodies,
/// rather than a block that silently renders as nothing.
@immutable
sealed class ArticleBlock {
  const ArticleBlock();

  /// Every word this block contributes to the article, for search and for the
  /// migration test that checks no content was lost.
  String get plainText;

  /// The authoring markup this block came from, so a parsed body can be turned
  /// back into its source and compared with it.
  String get markup;
}

/// A section heading.
class ArticleHeading extends ArticleBlock {
  const ArticleHeading(this.text);

  final String text;

  List<ArticleSpan> get spans => parseInlineSpans(text);

  @override
  String get plainText => text;

  @override
  String get markup => '## $text';

  @override
  bool operator ==(Object other) =>
      other is ArticleHeading && other.text == text;

  @override
  int get hashCode => Object.hash('heading', text);
}

/// A paragraph of body copy.
class ArticleParagraph extends ArticleBlock {
  const ArticleParagraph(this.text);

  final String text;

  List<ArticleSpan> get spans => parseInlineSpans(text);

  @override
  String get plainText => text;

  @override
  String get markup => text;

  @override
  bool operator ==(Object other) =>
      other is ArticleParagraph && other.text == text;

  @override
  int get hashCode => Object.hash('paragraph', text);
}

/// A bulleted list, as one block rather than a run of rows.
///
/// Grouping matters to the layout: a list is spaced as a unit, and a list that
/// ends a section needs different trailing space than a paragraph does.
class ArticleList extends ArticleBlock {
  const ArticleList(this.items);

  final List<String> items;

  List<List<ArticleSpan>> get itemSpans =>
      List.unmodifiable(items.map(parseInlineSpans));

  @override
  String get plainText => items.join(' ');

  @override
  String get markup => items.map((item) => '- $item').join('\n');

  @override
  bool operator ==(Object other) =>
      other is ArticleList && listEquals(other.items, items);

  @override
  int get hashCode => Object.hashAll(['list', ...items]);
}

/// What a callout is for. The three are styled differently and carry different
/// icons, so the kind is part of the content rather than a layout choice.
enum ArticleCalloutKind {
  /// Context the reader can skip without losing the thread.
  note('>'),

  /// Something worth stopping for: a limit of what the article can tell them,
  /// or a symptom that should not wait.
  caution('>!'),

  /// A line lifted out of the body for emphasis.
  pullQuote('>>');

  const ArticleCalloutKind(this.marker);

  /// The line prefix that authors this kind.
  final String marker;
}

/// A block set apart from the body copy.
class ArticleCallout extends ArticleBlock {
  const ArticleCallout(this.text, {this.kind = ArticleCalloutKind.note});

  final String text;
  final ArticleCalloutKind kind;

  List<ArticleSpan> get spans => parseInlineSpans(text);

  @override
  String get plainText => text;

  @override
  String get markup => '${kind.marker} $text';

  @override
  bool operator ==(Object other) =>
      other is ArticleCallout && other.text == text && other.kind == kind;

  @override
  int get hashCode => Object.hash('callout', text, kind);
}

/// The article's sources, as a block the reading layout can place.
///
/// Never produced by the parser: sources are attached per article in
/// `article_sources.dart` and appended by `Article.blocksWithSources`, so a
/// citation can never be typed into an article body by hand.
class ArticleSourceList extends ArticleBlock {
  const ArticleSourceList(this.sources);

  final List<ArticleSource> sources;

  @override
  String get plainText =>
      sources.map((source) => '${source.title} ${source.publisher}').join(' ');

  @override
  String get markup => '';

  @override
  bool operator ==(Object other) =>
      other is ArticleSourceList && listEquals(other.sources, sources);

  @override
  int get hashCode => Object.hashAll(['sources', ...sources.map((s) => s.url)]);
}

/// Parses the authoring markup described at the top of this file.
///
/// Blank lines are dropped rather than preserved as empty paragraphs, which is
/// what the previous renderer did and what keeps the existing bodies — written
/// with a blank line between every paragraph — from gaining 40 empty blocks.
List<ArticleBlock> parseArticleBody(String source) {
  final blocks = <ArticleBlock>[];
  var items = <String>[];

  void flushList() {
    if (items.isEmpty) return;
    blocks.add(ArticleList(List.unmodifiable(items)));
    items = <String>[];
  }

  for (final raw in source.trim().split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    // A list item extends the list being collected; anything else ends it.
    if (line.startsWith('- ')) {
      items.add(line.substring(2).trim());
      continue;
    }
    flushList();

    if (line.startsWith('## ')) {
      blocks.add(ArticleHeading(line.substring(3).trim()));
    } else if (line.startsWith('>> ')) {
      blocks.add(
        ArticleCallout(
          line.substring(3).trim(),
          kind: ArticleCalloutKind.pullQuote,
        ),
      );
    } else if (line.startsWith('>! ')) {
      blocks.add(
        ArticleCallout(
          line.substring(3).trim(),
          kind: ArticleCalloutKind.caution,
        ),
      );
    } else if (line.startsWith('> ')) {
      blocks.add(ArticleCallout(line.substring(2).trim()));
    } else {
      blocks.add(ArticleParagraph(line));
    }
  }
  flushList();

  return List.unmodifiable(blocks);
}

/// Turns parsed blocks back into authoring markup.
///
/// Only the migration test needs this, and that is the point: parsing a body,
/// serialising it and comparing with the source is how we know the parser did
/// not quietly drop a line.
String articleBlocksToMarkup(List<ArticleBlock> blocks) => blocks
    .where((block) => block.markup.isNotEmpty)
    .map((block) => block.markup)
    .join('\n\n');
