import '../domain/partner_access_policy.dart';
import '../domain/partner_share_code.dart';

/// Page grants and field consent are independent and private by default.
class PartnerConsent {
  const PartnerConsent({
    this.fields = const [],
    this.home = false,
    this.calendar = false,
    this.automaticUpdates = false,
  });
  final List<String> fields;
  final bool home, calendar, automaticUpdates;
  static const allowedFields = [
    'name',
    'phase',
    'next_period',
    'mood',
    'symptoms',
    'pain',
    'fertile',
    'ovulation',
    'pms',
    'support_tip',
    'note',
  ];
  PartnerAccessPolicy get pages =>
      PartnerAccessPolicy(home: home, calendar: calendar);
  Map<String, dynamic> toJson() => {
    'fields': fields,
    'home': home,
    'calendar': calendar,
    'automatic_updates': automaticUpdates,
  };
  factory PartnerConsent.fromJson(Map<String, dynamic> j) => PartnerConsent(
    fields: (j['fields'] as List? ?? [])
        .cast<String>()
        .where(allowedFields.contains)
        .toList(),
    home: j['home'] == true,
    calendar: j['calendar'] == true,
    automaticUpdates: j['automatic_updates'] == true,
  );

  /// Applies the identical field allow-list used by the server before upload.
  PartnerSnapshot filter(PartnerSnapshot s) {
    final source = s.toJson();
    const keys = {
      'name': ['n'],
      'phase': ['ph', 'cd'],
      'next_period': ['np', 'dl'],
      'mood': ['m'],
      'symptoms': ['s'],
      'pain': ['p'],
      'fertile': ['fs', 'fe'],
      'ovulation': ['ov'],
      'pms': ['ps', 'pe'],
      'support_tip': ['t'],
      'note': ['no'],
    };
    final output = <String, dynamic>{'c': source['c'], 'x': source['x']};
    if (!automaticUpdates || (!home && !calendar)) {
      return PartnerSnapshot.fromJson(output);
    }
    const calendarFields = {'next_period', 'fertile', 'ovulation', 'pms'};
    for (final f in fields) {
      // With only Calendar granted, never send Home-only observations such as
      // mood, pain, symptoms or notes, even if their field switch is on.
      if (!home && (!calendar || !calendarFields.contains(f))) continue;
      for (final k in keys[f] ?? <String>[]) {
        if (source.containsKey(k)) output[k] = source[k];
      }
    }
    return PartnerSnapshot.fromJson(output);
  }
}

class PartnerConnection {
  const PartnerConnection({
    required this.id,
    required this.ownerId,
    this.partnerId,
    required this.consent,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.revoked = false,
    this.revision = 0,
    this.snapshot,
  });
  final String id, ownerId;
  final String? partnerId;
  final PartnerConsent consent;
  final DateTime createdAt, updatedAt, expiresAt;
  final bool revoked;
  final int revision;
  final PartnerSnapshot? snapshot;
  bool expiredAt(DateTime now) => !now.isBefore(expiresAt);
  bool readableAt(DateTime now) =>
      !revoked &&
      !expiredAt(now) &&
      snapshot != null &&
      !snapshot!.isExpiredAt(now);
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'partner_id': partnerId,
    'consent': consent.toJson(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'revoked': revoked,
    'revision': revision,
    if (snapshot != null) 'snapshot': snapshot!.toJson(),
  };
  factory PartnerConnection.fromJson(Map<String, dynamic> j) =>
      PartnerConnection(
        id: j['id'] as String,
        ownerId: j['owner_id'] as String,
        partnerId: j['partner_id'] as String?,
        consent: PartnerConsent.fromJson(
          (j['consent'] as Map).cast<String, dynamic>(),
        ),
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        expiresAt: DateTime.parse(j['expires_at'] as String),
        revoked: j['revoked'] == true,
        revision: (j['revision'] as num? ?? 0).toInt(),
        snapshot: j['snapshot'] == null
            ? null
            : PartnerSnapshot.fromJson(
                (j['snapshot'] as Map).cast<String, dynamic>(),
              ),
      );
}

class PartnerInvite {
  const PartnerInvite(this.code, this.connection);
  final String code;
  final PartnerConnection connection;
}
