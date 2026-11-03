import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/logging_catalog.dart';
import '../domain/tracking_options.dart';

enum CustomTagAddResult {
  added,
  empty,
  catalogueDuplicate,
  existing,
  limitReached,
  persistenceFailed,
}

/// User-defined symptom tags.
///
/// Stored separately from logs so a tag survives deleting the entry that
/// introduced it and remains available for future logs. Catalogue labels are
/// reserved, including planned options, so custom tags cannot expose a
/// built-in option before its production control is ready.
class CustomTagsNotifier extends Notifier<List<String>> {
  static const _key = 'cyclecare.custom_tags.v1';
  static const _maxTags = 40;

  SharedPreferences? _prefs;
  Future<void>? _loading;

  @override
  List<String> build() {
    // Returning an empty list keeps the logger buildable on the first frame.
    // Mutations await this load so an early add cannot overwrite stored tags.
    _loading = _load();
    return const [];
  }

  /// Whether [tag] is already a catalogue option or recognised legacy alias.
  /// Matching is intentionally case-insensitive. Planned labels are reserved
  /// too; a custom tag must not become a back door to an unavailable option.
  static bool conflictsWithCatalogue(String tag) {
    final candidate = tag.trim().toLowerCase();
    if (candidate.isEmpty) return false;

    for (final field in LoggingCatalog.fields) {
      for (final option in field.options) {
        if (option.label.toLowerCase() == candidate) return true;
      }
    }
    for (final aliases in catalogueAliases.values) {
      for (final entry in aliases.entries) {
        if (entry.key.toLowerCase() == candidate ||
            entry.value.toLowerCase() == candidate) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs?.getStringList(_key) ?? const [];
  }

  /// Adds [tag] only after durable persistence succeeds.
  ///
  /// The result lets the logger keep the sheet open with useful feedback and
  /// prevents it from selecting or reporting a tag that was rejected.
  Future<CustomTagAddResult> add(String tag) async {
    await _loading;
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return CustomTagAddResult.empty;
    if (conflictsWithCatalogue(trimmed)) {
      return CustomTagAddResult.catalogueDuplicate;
    }

    final exists = state.any(
      (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return CustomTagAddResult.existing;
    if (state.length >= _maxTags) return CustomTagAddResult.limitReached;

    final next = [...state, trimmed]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    try {
      if (!await _persist(next)) {
        return CustomTagAddResult.persistenceFailed;
      }
    } catch (_) {
      return CustomTagAddResult.persistenceFailed;
    }
    state = next;
    return CustomTagAddResult.added;
  }

  Future<bool> remove(String tag) async {
    await _loading;
    final next = state.where((existing) => existing != tag).toList();
    if (next.length == state.length) return true;
    try {
      if (!await _persist(next)) return false;
    } catch (_) {
      return false;
    }
    state = next;
    return true;
  }

  Future<bool> _persist(List<String> tags) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs.setStringList(_key, tags);
  }
}

final customTagsProvider =
    NotifierProvider<CustomTagsNotifier, List<String>>(CustomTagsNotifier.new);
