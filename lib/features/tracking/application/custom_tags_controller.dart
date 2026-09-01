import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-defined symptom tags.
///
/// The built-in symptom list can't cover everything — people track jaw tension,
/// specific migraine auras, flare-ups of their own conditions. Without this,
/// those go in the free-text notes field, where the analytics engine can't see
/// them and no pattern is ever found.
///
/// Stored separately from logs so a tag survives deleting the entry that
/// introduced it, and stays offered for future logs.
class CustomTagsNotifier extends Notifier<List<String>> {
  static const _key = 'cyclecare.custom_tags.v1';
  static const _maxTags = 40;

  SharedPreferences? _prefs;

  @override
  List<String> build() {
    // Loaded eagerly but asynchronously: returning an empty list first keeps
    // the log form buildable on the first frame, and the tags appear a moment
    // later without a loading state flashing across the chip grid.
    _load();
    return const [];
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs?.getStringList(_key) ?? const [];
  }

  Future<void> add(String tag) async {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;

    // Case-insensitive de-dupe so "Jaw tension" and "jaw tension" don't become
    // two separate series in the insights.
    final exists = state.any(
      (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists || state.length >= _maxTags) return;

    final next = [...state, trimmed]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    state = next;
    await _persist(next);
  }

  Future<void> remove(String tag) async {
    final next = state.where((existing) => existing != tag).toList();
    state = next;
    await _persist(next);
  }

  Future<void> _persist(List<String> tags) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setStringList(_key, tags);
  }
}

final customTagsProvider =
    NotifierProvider<CustomTagsNotifier, List<String>>(CustomTagsNotifier.new);
