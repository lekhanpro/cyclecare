import 'dart:convert';

import 'package:crypto/crypto.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Partner share code
//
// The app has no server, so sharing is a code the owner sends and the partner
// pastes in. The code *is* the data: compact JSON, base64url, with a checksum.
//
//   CC1-<payload>-<check>
//
// The checksum is the first 8 hex characters of SHA-256 over the payload. It is
// there to catch a mistyped or truncated paste, not to stop forgery — anyone
// can recompute it. That is acceptable because the code only ever carries what
// the owner chose to send to this person; there is nothing behind it to reach.
//
// Only switched-on fields are written. An absent key means "not shared", which
// is different from "shared but empty" and the dashboard shows the difference.
// ─────────────────────────────────────────────────────────────────────────────

const _prefix = 'CC1';

/// What one code carries. Every field except the timestamps is optional.
class PartnerSnapshot {
  const PartnerSnapshot({
    required this.createdAt,
    required this.expiresAt,
    this.ownerName,
    this.phase,
    this.cycleDay,
    this.nextPeriod,
    this.daysLate,
    this.fertileStart,
    this.fertileEnd,
    this.ovulation,
    this.pmsStart,
    this.pmsEnd,
    this.mood,
    this.symptoms,
    this.painLevel,
    this.supportTip,
    this.note,
  });

  final DateTime createdAt;
  final DateTime expiresAt;
  final String? ownerName;

  /// Phase label, e.g. "Luteal".
  final String? phase;
  final int? cycleDay;
  final DateTime? nextPeriod;

  /// Set when the period was already late at the time the code was made.
  final int? daysLate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
  final DateTime? ovulation;
  final DateTime? pmsStart;
  final DateTime? pmsEnd;
  final String? mood;
  final List<String>? symptoms;

  /// 0–10, as logged.
  final int? painLevel;
  final String? supportTip;
  final String? note;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  Map<String, Object> toJson() {
    String d(DateTime v) =>
        '${v.year.toString().padLeft(4, '0')}-'
        '${v.month.toString().padLeft(2, '0')}-'
        '${v.day.toString().padLeft(2, '0')}';
    return {
      'c': createdAt.toUtc().millisecondsSinceEpoch,
      'x': expiresAt.toUtc().millisecondsSinceEpoch,
      if (ownerName != null) 'n': ownerName!,
      if (phase != null) 'ph': phase!,
      if (cycleDay != null) 'cd': cycleDay!,
      if (nextPeriod != null) 'np': d(nextPeriod!),
      if (daysLate != null) 'dl': daysLate!,
      if (fertileStart != null) 'fs': d(fertileStart!),
      if (fertileEnd != null) 'fe': d(fertileEnd!),
      if (ovulation != null) 'ov': d(ovulation!),
      if (pmsStart != null) 'ps': d(pmsStart!),
      if (pmsEnd != null) 'pe': d(pmsEnd!),
      if (mood != null) 'm': mood!,
      if (symptoms != null) 's': symptoms!,
      if (painLevel != null) 'p': painLevel!,
      if (supportTip != null) 't': supportTip!,
      if (note != null) 'no': note!,
    };
  }

  static PartnerSnapshot fromJson(Map<String, dynamic> j) {
    DateTime? d(String k) => j[k] == null ? null : DateTime.parse(j[k] as String);
    DateTime ms(String k) =>
        DateTime.fromMillisecondsSinceEpoch(j[k] as int, isUtc: true).toLocal();
    return PartnerSnapshot(
      createdAt: ms('c'),
      expiresAt: ms('x'),
      ownerName: j['n'] as String?,
      phase: j['ph'] as String?,
      cycleDay: j['cd'] as int?,
      nextPeriod: d('np'),
      daysLate: j['dl'] as int?,
      fertileStart: d('fs'),
      fertileEnd: d('fe'),
      ovulation: d('ov'),
      pmsStart: d('ps'),
      pmsEnd: d('pe'),
      mood: j['m'] as String?,
      symptoms: (j['s'] as List?)?.cast<String>(),
      painLevel: j['p'] as int?,
      supportTip: j['t'] as String?,
      note: j['no'] as String?,
    );
  }
}

/// Why a pasted code was rejected. Each one gets its own message, because "it
/// didn't work" gives the partner nothing to do about it.
enum ShareCodeError {
  /// Not a CycleCare code at all, or cut short.
  malformed,

  /// Looks right but the checksum disagrees: a typo or a missing character.
  checksum,

  /// Valid, but past its expiry.
  expired,
}

class ShareCodeException implements Exception {
  const ShareCodeException(this.error);
  final ShareCodeError error;

  String get message => switch (error) {
        ShareCodeError.malformed =>
          "That doesn't look like a CycleCare code. Check you copied all of it.",
        ShareCodeError.checksum =>
          'Part of this code is wrong or missing. Ask for it to be sent again, '
              'or copy and paste rather than typing it.',
        ShareCodeError.expired =>
          'This code has expired. Ask for a new one.',
      };

  @override
  String toString() => 'ShareCodeException($error)';
}

String _check(String payload) =>
    sha256.convert(utf8.encode(payload)).toString().substring(0, 8);

/// Encodes a snapshot. Padding is stripped; [decodeShareCode] restores it.
String encodeShareCode(PartnerSnapshot snapshot) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode(snapshot.toJson())))
      .replaceAll('=', '');
  return '$_prefix-$payload-${_check(payload)}';
}

/// Decodes and validates a code. Throws [ShareCodeException].
///
/// Whitespace and line breaks are ignored, since messaging apps wrap long
/// strings and a pasted code often arrives in pieces.
PartnerSnapshot decodeShareCode(String input, {DateTime? now}) {
  final code = input.replaceAll(RegExp(r'\s'), '');
  final parts = code.split('-');
  if (parts.length != 3 || parts[0] != _prefix || parts[1].isEmpty) {
    throw const ShareCodeException(ShareCodeError.malformed);
  }
  final payload = parts[1];
  if (parts[2].toLowerCase() != _check(payload)) {
    throw const ShareCodeException(ShareCodeError.checksum);
  }

  final PartnerSnapshot snapshot;
  try {
    final padded = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
    final json = jsonDecode(utf8.decode(base64Url.decode(padded)));
    snapshot = PartnerSnapshot.fromJson(json as Map<String, dynamic>);
  } catch (_) {
    throw const ShareCodeException(ShareCodeError.malformed);
  }

  if (snapshot.isExpiredAt(now ?? DateTime.now())) {
    throw const ShareCodeException(ShareCodeError.expired);
  }
  return snapshot;
}
