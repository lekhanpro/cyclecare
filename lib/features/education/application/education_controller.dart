import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Education library state
//
// Two tiny lists of article ids, kept on device.
//
// Bookmarks and read-state were previously held in screen state, which meant a
// saved article vanished the moment the user switched tabs. That is worse than
// having no bookmark button at all: the affordance promises persistence and
// then quietly breaks the promise.
//
// Neither list is synced or encrypted. They describe reading habits, not health
// data, and keeping them local means the feature works offline and needs no
// account.
// ─────────────────────────────────────────────────────────────────────────────

/// Shared plumbing for both lists: load once, merge on first read, persist on
/// every mutation.
abstract class _ArticleIdSetNotifier extends Notifier<List<String>> {
  /// The preferences key this list is stored under.
  String get storageKey;

  SharedPreferences? _prefs;

  @override
  List<String> build() {
    // Loaded eagerly but asynchronously. Returning an empty list first keeps
    // the library buildable on the first frame; the saved ids land a moment
    // later without a spinner flashing across the list.
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final stored = prefs.getStringList(storageKey) ?? const <String>[];

    // A write that lands before the first read completes (opening an article
    // straight from a deep link, for instance) would otherwise be erased by
    // it. Merge rather than replace.
    if (state.isEmpty) {
      state = stored;
      return;
    }
    final merged = <String>{...stored, ...state}.toList();
    state = merged;
    if (merged.length != stored.length) {
      await prefs.setStringList(storageKey, merged);
    }
  }

  bool contains(String id) => state.contains(id);

  Future<void> _persist(List<String> ids) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setStringList(storageKey, ids);
  }

  Future<void> clear() async {
    state = const [];
    await _persist(const []);
  }
}

/// Articles the user has saved.
class EducationBookmarksNotifier extends _ArticleIdSetNotifier {
  @override
  String get storageKey => 'cyclecare.education_bookmarks.v1';

  bool isBookmarked(String id) => contains(id);

  /// Adds or removes [id]. Returns true when the article ended up bookmarked,
  /// so the caller can pick the right confirmation copy without re-reading
  /// state that has only just changed.
  bool toggle(String id) {
    final adding = !state.contains(id);
    final next = adding
        ? <String>[...state, id]
        : state.where((existing) => existing != id).toList();
    state = next;
    _persist(next);
    return adding;
  }
}

final educationBookmarksProvider =
    NotifierProvider<EducationBookmarksNotifier, List<String>>(
  EducationBookmarksNotifier.new,
);

/// Articles the user has opened.
///
/// Deliberately coarse: opening an article counts as reading it. Scroll-depth
/// tracking would be more accurate and would also mean a user who read
/// carefully on a small screen gets less credit than one who skimmed on a
/// tablet.
class EducationProgressNotifier extends _ArticleIdSetNotifier {
  @override
  String get storageKey => 'cyclecare.education_read.v1';

  bool hasRead(String id) => contains(id);

  void markRead(String id) {
    if (state.contains(id)) return;
    final next = <String>[...state, id];
    state = next;
    _persist(next);
  }
}

final educationProgressProvider =
    NotifierProvider<EducationProgressNotifier, List<String>>(
  EducationProgressNotifier.new,
);
