import 'package:cyclecare/features/education/article_sources.dart';
import 'package:cyclecare/features/education/education_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('article ids are unique', () {
    final ids = kArticles.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('the six new articles are in the list', () {
    final ids = kArticles.map((a) => a.id).toSet();
    for (final id in [
      'real-world-cycles',
      'irregular-periods',
      'heavy-periods',
      'perimenopause',
      'contraception-basics',
      'fertility-awareness',
    ]) {
      expect(ids, contains(id));
    }
    expect(kArticles.length, 26);
  });

  test('every source list belongs to a real article', () {
    final ids = kArticles.map((a) => a.id).toSet();
    for (final key in kArticleSources.keys) {
      expect(ids, contains(key), reason: 'sources for unknown article $key');
    }
  });

  test('every new article has at least one source', () {
    for (final id in [
      'real-world-cycles',
      'irregular-periods',
      'heavy-periods',
      'perimenopause',
      'contraception-basics',
      'fertility-awareness',
    ]) {
      expect(kArticleSources[id], isNotEmpty, reason: id);
    }
  });

  test('links are https, and PDFs only come from PubMed Central', () {
    for (final sources in kArticleSources.values) {
      for (final s in sources) {
        expect(Uri.parse(s.url).scheme, 'https', reason: s.url);
        if (s.pdfUrl != null) {
          final pdf = Uri.parse(s.pdfUrl!);
          expect(pdf.scheme, 'https');
          expect(pdf.host, 'pmc.ncbi.nlm.nih.gov', reason: s.pdfUrl);
          expect(pdf.path, endsWith('.pdf'));
        }
      }
    }
  });

  test('papers carry a year; guidance pages do not invent one', () {
    for (final sources in kArticleSources.values) {
      for (final s in sources) {
        if (s.isPaper) {
          expect(s.year, isNotNull, reason: s.title);
        } else {
          expect(s.year, isNull, reason: s.title);
        }
      }
    }
  });
}
