import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Health state
//
// Two small pieces of user-owned data behind the health screen:
//
//  • Which conditions the user has told us apply to them. This is the whole
//    reason the screen can stop being a leaflet — once we know someone is
//    living with endometriosis, their card sorts to the top and the pain diary
//    stops being a curiosity.
//  • A dated pain diary. The single most useful artefact someone can bring to
//    an appointment, and the thing that turns "it hurts a lot sometimes" into
//    a record with dates, levels, and locations on it.
//
// Both are local-only on purpose. This is the most sensitive data in the app
// and none of it needs to leave the device to be useful.
// ─────────────────────────────────────────────────────────────────────────────

/// Conditions the user has marked as "this applies to me".
///
/// Stored as bare ids rather than the full condition content so the educational
/// copy can be rewritten, expanded, or corrected in a later release without
/// migrating anything the user chose.
class MyConditionsNotifier extends Notifier<List<String>> {
  static const _key = 'cyclecare.health_conditions.v1';

  SharedPreferences? _prefs;

  @override
  List<String> build() {
    // Same shape as the custom tags controller: return empty synchronously so
    // the screen is buildable on the first frame, then fill in a moment later.
    // The alternative — an AsyncValue — costs a spinner across the whole
    // screen for data that arrives in a few milliseconds.
    _load();
    return const [];
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs?.getStringList(_key) ?? const [];
  }

  bool has(String id) => state.contains(id);

  Future<void> toggle(String id) async {
    final next = state.contains(id)
        ? state.where((existing) => existing != id).toList()
        : [...state, id];
    state = next;
    await _persist(next);
  }

  Future<void> _persist(List<String> ids) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setStringList(_key, ids);
  }
}

final myConditionsProvider =
    NotifierProvider<MyConditionsNotifier, List<String>>(
  MyConditionsNotifier.new,
);

/// One dated pain record.
///
/// Severity, location and date are separate fields rather than free text
/// because the point of the diary is to be summarisable — "8 entries averaging
/// 7/10, mostly lower abdomen, all in the three days before bleeding" is a
/// sentence a clinician can act on.
@immutable
class PainEntry {
  const PainEntry({
    required this.id,
    required this.date,
    required this.severity,
    this.locations = const [],
    this.notes = '',
  });

  factory PainEntry.fromJson(Map<String, dynamic> json) => PainEntry(
        id: json['id'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        severity: (json['severity'] as num?)?.toInt() ?? 0,
        locations: (json['locations'] as List<dynamic>?)
                ?.map((value) => value.toString())
                .toList() ??
            const [],
        notes: json['notes'] as String? ?? '',
      );

  final String id;
  final DateTime date;

  /// 1–10, matching the severity control everywhere else in the app.
  final int severity;

  /// Body locations, from a fixed list so entries stay comparable.
  final List<String> locations;

  final String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'severity': severity,
        'locations': locations,
        'notes': notes,
      };
}

/// The pain diary, newest first.
class PainEntriesNotifier extends Notifier<List<PainEntry>> {
  static const _key = 'cyclecare.pain_entries.v1';

  /// Generous enough for years of flare-ups, bounded so the preferences blob
  /// can't grow without limit.
  static const _maxEntries = 500;

  SharedPreferences? _prefs;

  @override
  List<PainEntry> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = _decode(_prefs?.getStringList(_key) ?? const []);
  }

  List<PainEntry> _decode(List<String> raw) {
    final entries = <PainEntry>[];
    for (final line in raw) {
      try {
        final decoded = jsonDecode(line);
        if (decoded is Map<String, dynamic>) {
          entries.add(PainEntry.fromJson(decoded));
        }
      } catch (_) {
        // One malformed row must not cost the user the rest of the diary.
        // Skipping it silently is better than an error state over data they
        // can neither see nor repair.
      }
    }
    return _sorted(entries);
  }

  List<PainEntry> _sorted(List<PainEntry> entries) =>
      entries..sort((a, b) => b.date.compareTo(a.date));

  Future<void> add(PainEntry entry) async {
    final next = _sorted([entry, ...state]);
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    state = next;
    await _persist(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((entry) => entry.id != id).toList();
    state = next;
    await _persist(next);
  }

  Future<void> _persist(List<PainEntry> entries) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setStringList(
      _key,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}

final painEntriesProvider =
    NotifierProvider<PainEntriesNotifier, List<PainEntry>>(
  PainEntriesNotifier.new,
);
