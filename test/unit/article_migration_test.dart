import 'dart:convert';
import 'dart:io';

import 'package:cyclecare/features/education/domain/article.dart';
import 'package:cyclecare/features/education/domain/article_block.dart';
import 'package:cyclecare/features/education/domain/core_articles.dart';
import 'package:flutter_test/flutter_test.dart';

// The articles were lifted out of education_screen.dart, where the model, the
// content and the layout shared one file, and their string bodies became typed
// blocks. This is a migration, so the bar is that nothing was lost: not an
// article, not a line, not a source.
//
// test/fixtures/pre_migration_articles.json is the content as it stood before
// that move, captured by tool/dev/extract_articles.py.

/// One entry per authored line, with the markers stripped, in reading order.
List<String> _authoredLines(String body) => [
      for (final raw in body.trim().split('\n'))
        if (raw.trim().isNotEmpty) _stripMarker(raw.trim()),
    ];

String _stripMarker(String line) {
  for (final marker in const ['## ', '>> ', '>! ', '> ', '- ']) {
    if (line.startsWith(marker)) return line.substring(marker.length).trim();
  }
  return line;
}

/// The same shape, taken from the parsed blocks: a list contributes one entry
/// per item, every other block one entry.
List<String> _blockLines(List<ArticleBlock> blocks) => [
      for (final block in blocks)
        if (block is ArticleList) ...block.items else block.plainText,
    ];

void main() {
  final fixture = (jsonDecode(
    File('test/fixtures/pre_migration_articles.json').readAsStringSync(),
  ) as List)
      .cast<Map<String, dynamic>>();

  test('the fixture itself is the 26 articles, not an empty file', () {
    expect(fixture, hasLength(26));
  });

  test('every pre-migration article survives, in its original order', () {
    expect(kCoreArticles.map((a) => a.id).toList(),
        fixture.map((a) => a['id']).toList());

    for (var i = 0; i < fixture.length; i++) {
      final before = fixture[i];
      final after = kCoreArticles[i];
      final where = 'article ${before['id']}';

      expect(after.title, before['title'], reason: '$where: title');
      expect(after.category.name, before['category'],
          reason: '$where: category');
      expect(after.readMinutes, before['readMinutes'],
          reason: '$where: read time');
      expect(after.standfirst, before['standfirst'],
          reason: '$where: standfirst');
      // The body is kept verbatim beside the parsed blocks, so this is a
      // character-for-character comparison of the original copy.
      expect(after.body, before['body'], reason: '$where: body');
    }
  });

  test('no authored line is dropped when a body becomes blocks', () {
    for (final article in kCoreArticles) {
      expect(
        _blockLines(article.blocks),
        _authoredLines(article.body),
        reason: 'article ${article.id} lost or reordered a line',
      );
    }
  });

  test('blocks serialise back to markup that parses to the same blocks', () {
    for (final article in kCoreArticles) {
      final reparsed =
          parseArticleBody(articleBlocksToMarkup(article.blocks));
      expect(reparsed, article.blocks,
          reason: 'article ${article.id} does not survive a round trip');
    }
  });

  test('every category maps to a real one, and all six are used', () {
    final used = kCoreArticles.map((a) => a.category).toSet();
    expect(used, hasLength(ArticleCategory.values.length));
  });

  test('search reaches body text, not just titles', () {
    final article =
        kCoreArticles.firstWhere((a) => a.id == 'cycle-phases');
    // A phrase from the body, nowhere in the title or standfirst.
    expect(article.matches('uterine'), isTrue);
    expect(article.matches('not-in-any-article'), isFalse);
  });

  test('sources stay attached, and every citation is usable', () {
    var withSources = 0;
    for (final article in kCoreArticles) {
      if (article.sources.isEmpty) continue;
      withSources++;
      for (final source in article.sources) {
        expect(source.title, isNotEmpty, reason: article.id);
        expect(source.publisher, isNotEmpty, reason: article.id);
        expect(source.url, startsWith('https://'), reason: article.id);
      }
      // The reading layout appends them as a final block.
      expect(article.blocksWithSources.last, isA<ArticleSourceList>(),
          reason: article.id);
    }
    expect(withSources, greaterThan(0),
        reason: 'the citation table is no longer reaching the articles');
  });
}
