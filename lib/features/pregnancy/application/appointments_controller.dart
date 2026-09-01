import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Prenatal appointments
//
// Pregnancy care is a schedule, not a single event: scans, glucose tests,
// midwife checks, consultant reviews. People currently keep these in a phone
// calendar where they sit alongside dentist reminders and lose all context —
// which scan, which clinic, what the last visit concluded.
//
// Stored as a JSON string rather than a string list so the shape can gain
// fields later without a migration that drops everything already saved. A row
// that fails to parse is skipped rather than throwing, so one bad entry can
// never take the whole list down with it.
// ─────────────────────────────────────────────────────────────────────────────

/// A single scheduled or past appointment.
class Appointment {
  const Appointment({
    required this.id,
    required this.title,
    required this.dateTime,
    this.doctor,
    this.location,
    this.notes = '',
  });

  /// Stable identity, so editing an appointment does not depend on its index.
  final String id;

  final String title;

  /// Midwife, obstetrician, or clinic contact. Optional — plenty of
  /// appointments are booked before anyone knows who they will see.
  final String? doctor;

  final DateTime dateTime;
  final String? location;

  /// Free text. Questions to ask beforehand, results noted afterwards.
  final String notes;

  bool isPastAt(DateTime now) => dateTime.isBefore(now);

  Appointment copyWith({
    String? id,
    String? title,
    Object? doctor = _unset,
    DateTime? dateTime,
    Object? location = _unset,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      // Sentinel rather than null-coalescing so a field can be cleared back to
      // null, which `doctor: null` alone cannot express.
      doctor: doctor == _unset ? this.doctor : doctor as String?,
      dateTime: dateTime ?? this.dateTime,
      location: location == _unset ? this.location : location as String?,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (doctor != null) 'doctor': doctor,
        'dateTime': dateTime.toIso8601String(),
        if (location != null) 'location': location,
        if (notes.isNotEmpty) 'notes': notes,
      };

  /// Returns null for a row that cannot be read, so a corrupt entry is dropped
  /// instead of failing the whole decode.
  static Appointment? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final parsedDate = DateTime.tryParse('${json['dateTime']}');
    if (id is! String || id.isEmpty || title is! String || parsedDate == null) {
      return null;
    }

    String? optional(Object? value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return Appointment(
      id: id,
      title: title,
      doctor: optional(json['doctor']),
      dateTime: parsedDate,
      location: optional(json['location']),
      notes: json['notes'] is String ? json['notes'] as String : '',
    );
  }

  static const Object _unset = Object();
}

class AppointmentsNotifier extends Notifier<List<Appointment>> {
  static const _key = 'cyclecare.pregnancy_appointments.v1';

  /// Generous, but bounded — an unbounded list written to preferences on every
  /// edit eventually becomes a visible hitch.
  static const _maxAppointments = 200;

  SharedPreferences? _prefs;

  @override
  List<Appointment> build() {
    // Loaded eagerly but asynchronously, matching the custom-tags controller:
    // returning an empty list first keeps the screen buildable on the first
    // frame, and the list fills in a moment later without a spinner flashing.
    _load();
    return const [];
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_key);
    if (raw == null || raw.isEmpty) return;
    state = _decode(raw);
  }

  Future<void> add(Appointment appointment) async {
    if (state.length >= _maxAppointments) return;
    final entry = appointment.id.isEmpty
        ? appointment.copyWith(id: newId())
        : appointment;
    await _write([...state, entry]);
  }

  /// Replaces the entry sharing [appointment]'s id. A no-op if it is gone —
  /// the sheet may have been open while the row was deleted elsewhere.
  Future<void> update(Appointment appointment) async {
    if (!state.any((existing) => existing.id == appointment.id)) return;
    await _write([
      for (final existing in state)
        if (existing.id == appointment.id) appointment else existing,
    ]);
  }

  Future<void> remove(String id) async {
    final next = state.where((existing) => existing.id != id).toList();
    if (next.length == state.length) return;
    await _write(next);
  }

  Future<void> _write(List<Appointment> next) async {
    final sorted = sortAppointments(next);
    state = sorted;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(
      _key,
      jsonEncode([for (final entry in sorted) entry.toJson()]),
    );
  }

  static List<Appointment> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = <Appointment>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final appointment = Appointment.fromJson(
          entry.map((key, value) => MapEntry('$key', value)),
        );
        if (appointment != null) items.add(appointment);
      }
      return sortAppointments(items);
    } catch (_) {
      // A hand-edited or half-written value should not brick the screen.
      return const [];
    }
  }

  /// Upcoming first, soonest at the top; past appointments follow with the most
  /// recent first. That ordering matches what the user is looking for — the
  /// next thing they have to attend, then the last thing they were told.
  static List<Appointment> sortAppointments(List<Appointment> items) {
    final now = DateTime.now();
    final upcoming = <Appointment>[];
    final past = <Appointment>[];
    for (final item in items) {
      (item.isPastAt(now) ? past : upcoming).add(item);
    }
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    past.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return [...upcoming, ...past];
  }

  static String newId() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'appt_$stamp';
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Appointment>>(
  AppointmentsNotifier.new,
);

/// Appointments still ahead, soonest first.
///
/// Re-sorted here rather than relying on the stored order: an appointment that
/// slipped from upcoming to past while the app was open would otherwise land at
/// the wrong end of its group until the next write.
final upcomingAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(appointmentsProvider)
      .where((appointment) => !appointment.isPastAt(now))
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
});

/// Appointments already attended, most recent first.
final pastAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(appointmentsProvider)
      .where((appointment) => appointment.isPastAt(now))
      .toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
});
