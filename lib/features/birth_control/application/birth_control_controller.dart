import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/birth_control_method.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Birth control state
//
// Three separate stores, deliberately:
//
//  • The original method + streak + last-taken trio, under its original keys.
//    An upgrade must never cost someone their streak, so those three keys are
//    read and written exactly as they were before.
//  • A per-date check-in log, so the screen can show history rather than a
//    single number. A streak counter alone cannot answer "did I miss anything
//    last week", which is the question people actually have.
//  • Pack layout and pack start date, which are pure presentation input for
//    the pack visualiser.
//
// Everything stays on device. Contraception use is among the most sensitive
// things this app knows, and none of it needs a server to be useful.
// ─────────────────────────────────────────────────────────────────────────────

/// Canonical `yyyy-mm-dd` key for a date, ignoring time and zone offset.
String bcDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime bcDateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// ─── Legacy store (original keys, original behaviour) ────────────────────────

class BirthControlState {
  const BirthControlState({
    this.method = BirthControlMethod.none,
    this.streak = 0,
    this.takenToday = false,
    this.lastTaken,
  });

  final BirthControlMethod method;
  final int streak;
  final bool takenToday;
  final DateTime? lastTaken;

  BirthControlState copyWith({
    BirthControlMethod? method,
    int? streak,
    bool? takenToday,
    DateTime? lastTaken,
  }) =>
      BirthControlState(
        method: method ?? this.method,
        streak: streak ?? this.streak,
        takenToday: takenToday ?? this.takenToday,
        lastTaken: lastTaken ?? this.lastTaken,
      );
}

class BirthControlNotifier extends AsyncNotifier<BirthControlState> {
  // Unchanged from the first version of this feature. Renaming any of these
  // would silently reset every existing user's streak.
  static const _methodKey = 'cc.bc.method';
  static const _streakKey = 'cc.bc.streak';
  static const _lastTakenKey = 'cc.bc.lastTaken';

  @override
  Future<BirthControlState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final methodName = prefs.getString(_methodKey) ?? 'none';
    final streak = prefs.getInt(_streakKey) ?? 0;
    final lastTakenStr = prefs.getString(_lastTakenKey);
    final lastTaken =
        lastTakenStr != null ? DateTime.tryParse(lastTakenStr) : null;
    final takenToday =
        lastTaken != null && _isSameDay(lastTaken, DateTime.now());

    return BirthControlState(
      method: BirthControlMethod.fromName(methodName),
      streak: streak,
      takenToday: takenToday,
      lastTaken: lastTaken,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> setMethod(BirthControlMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_methodKey, method.name);
    final current = state.valueOrNull ?? const BirthControlState();
    state = AsyncData(current.copyWith(method: method));
  }

  Future<void> checkIn() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.valueOrNull ?? const BirthControlState();
    if (current.takenToday) return;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final newStreak =
        current.lastTaken != null && _isSameDay(current.lastTaken!, yesterday)
            ? current.streak + 1
            : 1;

    await prefs.setInt(_streakKey, newStreak);
    await prefs.setString(_lastTakenKey, now.toIso8601String());

    state = AsyncData(BirthControlState(
      method: current.method,
      streak: newStreak,
      takenToday: true,
      lastTaken: now,
    ));
  }

  /// Undoes today's check-in. The original screen had no way back from a
  /// mis-tap, which meant the streak number could only ever be wrong upward.
  ///
  /// The streak is walked back by one rather than recomputed, because the
  /// legacy store only remembers the most recent date.
  Future<void> undoTodayCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.valueOrNull ?? const BirthControlState();
    if (!current.takenToday) return;

    final rewound = (current.streak - 1).clamp(0, 1 << 30);
    final previousDay = bcDateOnly(DateTime.now())
        .subtract(const Duration(days: 1))
        .add(const Duration(hours: 12));

    await prefs.setInt(_streakKey, rewound);
    if (rewound == 0) {
      await prefs.remove(_lastTakenKey);
    } else {
      await prefs.setString(_lastTakenKey, previousDay.toIso8601String());
    }

    state = AsyncData(BirthControlState(
      method: current.method,
      streak: rewound,
      takenToday: false,
      lastTaken: rewound == 0 ? null : previousDay,
    ));
  }
}

final birthControlProvider =
    AsyncNotifierProvider<BirthControlNotifier, BirthControlState>(
  BirthControlNotifier.new,
);

// ─── Per-date check-in log ───────────────────────────────────────────────────

enum CheckInStatus {
  /// No record either way. Not the same as a miss.
  unrecorded,
  taken,
  missed,
}

/// A `date -> taken?` map, persisted as JSON.
///
/// Follows the same shape as the education library controllers: return an empty
/// value on the first frame, load asynchronously, and merge rather than replace
/// so an early write is never clobbered by the load that follows it.
class BirthControlCheckInsNotifier extends Notifier<Map<String, bool>> {
  static const storageKey = 'cyclecare.birth_control.checkins.v1';

  /// Roughly two years. Old entries are dropped on write so the blob cannot
  /// grow without bound on a device someone keeps for a decade.
  static const _retainedDays = 730;

  SharedPreferences? _prefs;

  @override
  Map<String, bool> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final stored = _decode(prefs.getString(storageKey));

    if (state.isEmpty) {
      state = stored;
      return;
    }
    // In-memory wins: it is the more recent statement of fact.
    final merged = <String, bool>{...stored, ...state};
    state = merged;
    if (merged.length != stored.length) {
      await _persist(merged);
    }
  }

  Map<String, bool> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, bool>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is bool) out[key] = value;
      }
      return out;
    } catch (_) {
      // Corrupt blob. Starting clean beats crashing the screen on open.
      return const {};
    }
  }

  Future<void> _persist(Map<String, bool> value) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(value));
  }

  CheckInStatus statusFor(DateTime date) {
    final recorded = state[bcDateKey(date)];
    if (recorded == null) return CheckInStatus.unrecorded;
    return recorded ? CheckInStatus.taken : CheckInStatus.missed;
  }

  Future<void> setStatus(DateTime date, CheckInStatus status) async {
    final key = bcDateKey(date);
    final next = Map<String, bool>.from(state);
    switch (status) {
      case CheckInStatus.unrecorded:
        next.remove(key);
      case CheckInStatus.taken:
        next[key] = true;
      case CheckInStatus.missed:
        next[key] = false;
    }
    final pruned = _prune(next);
    state = pruned;
    await _persist(pruned);
  }

  /// Taken → missed → cleared → taken. One tap target per day rather than a
  /// menu: the day cells are small, and three states cycle faster than they
  /// pick from a list.
  Future<CheckInStatus> cycleStatus(DateTime date) async {
    final next = switch (statusFor(date)) {
      CheckInStatus.unrecorded => CheckInStatus.taken,
      CheckInStatus.taken => CheckInStatus.missed,
      CheckInStatus.missed => CheckInStatus.unrecorded,
    };
    await setStatus(date, next);
    return next;
  }

  Future<void> markTaken(DateTime date) =>
      setStatus(date, CheckInStatus.taken);

  Future<void> markMissed(DateTime date) =>
      setStatus(date, CheckInStatus.missed);

  Future<void> clearAll() async {
    state = const {};
    await _persist(const {});
  }

  Map<String, bool> _prune(Map<String, bool> value) {
    final cutoff = bcDateOnly(DateTime.now())
        .subtract(const Duration(days: _retainedDays));
    final out = <String, bool>{};
    for (final entry in value.entries) {
      final parsed = DateTime.tryParse(entry.key);
      if (parsed == null || !parsed.isBefore(cutoff)) {
        out[entry.key] = entry.value;
      }
    }
    return out;
  }
}

final birthControlCheckInsProvider =
    NotifierProvider<BirthControlCheckInsNotifier, Map<String, bool>>(
  BirthControlCheckInsNotifier.new,
);

// ─── Adherence maths ─────────────────────────────────────────────────────────

/// Read-only summary of the check-in log.
class AdherenceStats {
  const AdherenceStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.takenInWindow,
    required this.missedInWindow,
    required this.trackedInWindow,
    required this.windowDays,
  });

  final int currentStreak;
  final int longestStreak;
  final int takenInWindow;
  final int missedInWindow;

  /// Days inside the window that carry a record either way. Adherence is a
  /// ratio of recorded days, not of calendar days — a person who started
  /// tracking on Tuesday has not missed the preceding three weeks.
  final int trackedInWindow;

  final int windowDays;

  bool get hasData => trackedInWindow > 0;

  int? get adherencePercent =>
      trackedInWindow == 0 ? null : ((takenInWindow / trackedInWindow) * 100).round();

  /// Builds the summary from a raw check-in map.
  factory AdherenceStats.from(
    Map<String, bool> checkIns, {
    required DateTime today,
    int windowDays = 30,
  }) {
    final anchor = bcDateOnly(today);

    // ── Window counts ──
    var taken = 0;
    var missed = 0;
    for (var i = 0; i < windowDays; i++) {
      final day = anchor.subtract(Duration(days: i));
      final record = checkIns[bcDateKey(day)];
      if (record == null) continue;
      if (record) {
        taken++;
      } else {
        missed++;
      }
    }

    // ── Current streak ──
    //
    // Today counts when it is recorded as taken, but an unrecorded today does
    // not break anything: the day is not over yet, and a streak that resets at
    // midnight would punish someone for opening the app before breakfast.
    var cursor = anchor;
    if (checkIns[bcDateKey(anchor)] == null) {
      cursor = anchor.subtract(const Duration(days: 1));
    }
    var current = 0;
    while (checkIns[bcDateKey(cursor)] == true) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // ── Longest streak ──
    final takenDays = checkIns.entries
        .where((entry) => entry.value)
        .map((entry) => DateTime.tryParse(entry.key))
        .whereType<DateTime>()
        .map(bcDateOnly)
        .toList()
      ..sort();

    var longest = 0;
    var run = 0;
    DateTime? previous;
    for (final day in takenDays) {
      if (previous != null && day.difference(previous).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
      previous = day;
    }

    return AdherenceStats(
      currentStreak: current,
      longestStreak: longest,
      takenInWindow: taken,
      missedInWindow: missed,
      trackedInWindow: taken + missed,
      windowDays: windowDays,
    );
  }
}

final birthControlAdherenceProvider = Provider<AdherenceStats>((ref) {
  final checkIns = ref.watch(birthControlCheckInsProvider);
  return AdherenceStats.from(checkIns, today: DateTime.now());
});

// ─── Pack layout ─────────────────────────────────────────────────────────────

/// The two common combined-pill pack shapes, plus continuous packs.
///
/// Presented as a layout choice rather than a recommendation — the pack in the
/// user's hand is the authority on which one it is.
enum PillPackLayout {
  active21('21 / 7', 21, 7),
  active24('24 / 4', 24, 4),
  continuous('28 / 0', 28, 0);

  const PillPackLayout(this.label, this.activeDays, this.breakDays);

  final String label;
  final int activeDays;

  /// Placebo, reminder, or hormone-free days at the end of a pack.
  final int breakDays;

  int get totalDays => activeDays + breakDays;

  String get description => switch (this) {
        PillPackLayout.active21 =>
          '21 active days followed by 7 placebo or break days.',
        PillPackLayout.active24 =>
          '24 active days followed by 4 placebo or break days.',
        PillPackLayout.continuous =>
          'All 28 days active, with no break days in the pack.',
      };
}

class PillPackSettings {
  const PillPackSettings({
    this.layout = PillPackLayout.active21,
    this.packStart,
  });

  final PillPackLayout layout;

  /// The first day of the *first* pack the user recorded. Later packs are
  /// derived, so the visualiser keeps working for years without the user ever
  /// having to say "new pack" again.
  final DateTime? packStart;

  bool get isConfigured => packStart != null;

  /// Start date of the pack that contains [day].
  DateTime? packStartFor(DateTime day) {
    final origin = packStart;
    if (origin == null) return null;
    final elapsed = bcDateOnly(day).difference(origin).inDays;
    if (elapsed < 0) return origin;
    final packsDone = elapsed ~/ layout.totalDays;
    return origin.add(Duration(days: packsDone * layout.totalDays));
  }

  /// 1-based position of [day] inside its pack, or null when unconfigured.
  int? dayOfPack(DateTime day) {
    final origin = packStart;
    if (origin == null) return null;
    final elapsed = bcDateOnly(day).difference(origin).inDays;
    if (elapsed < 0) return null;
    return elapsed % layout.totalDays + 1;
  }

  /// 1-based pack count since the start date.
  int? packNumber(DateTime day) {
    final origin = packStart;
    if (origin == null) return null;
    final elapsed = bcDateOnly(day).difference(origin).inDays;
    if (elapsed < 0) return 1;
    return elapsed ~/ layout.totalDays + 1;
  }

  /// True when the 1-based pack position falls in the break stretch.
  bool isBreakDay(int position) => position > layout.activeDays;

  PillPackSettings copyWith({
    PillPackLayout? layout,
    DateTime? packStart,
    bool clearStart = false,
  }) =>
      PillPackSettings(
        layout: layout ?? this.layout,
        packStart: clearStart ? null : (packStart ?? this.packStart),
      );
}

class PillPackNotifier extends Notifier<PillPackSettings> {
  static const layoutKey = 'cyclecare.birth_control.pack_layout.v1';
  static const startKey = 'cyclecare.birth_control.pack_start.v1';

  SharedPreferences? _prefs;

  /// Set by the first mutation. Guards against the load finishing *after* the
  /// user has already made a choice and overwriting it with a stale value —
  /// unlikely, but the failure mode is a silently wrong pack day.
  bool _touched = false;

  @override
  PillPackSettings build() {
    _load();
    return const PillPackSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    if (_touched) return;

    final storedLayout = prefs.getString(layoutKey);
    final storedStart = prefs.getString(startKey);
    final parsedStart =
        storedStart == null ? null : DateTime.tryParse(storedStart);

    state = PillPackSettings(
      layout: PillPackLayout.values.firstWhere(
        (candidate) => candidate.name == storedLayout,
        orElse: () => state.layout,
      ),
      packStart: parsedStart == null ? null : bcDateOnly(parsedStart),
    );
  }

  Future<void> setLayout(PillPackLayout layout) async {
    _touched = true;
    state = state.copyWith(layout: layout);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(layoutKey, layout.name);
  }

  Future<void> setPackStart(DateTime date) async {
    _touched = true;
    final normalised = bcDateOnly(date);
    state = state.copyWith(packStart: normalised);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(startKey, normalised.toIso8601String());
  }

  Future<void> clearPackStart() async {
    _touched = true;
    state = state.copyWith(clearStart: true);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(startKey);
  }
}

final pillPackProvider = NotifierProvider<PillPackNotifier, PillPackSettings>(
  PillPackNotifier.new,
);
