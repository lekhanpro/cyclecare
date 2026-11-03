// Compatibility export for the six existing additions; content is now typed.
import 'domain/core_articles.dart';

final kNewArticles = kCoreArticles.skip(20).toList(growable: false);
