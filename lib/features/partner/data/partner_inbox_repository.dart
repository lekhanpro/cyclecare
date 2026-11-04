import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/partner_share_code.dart';

class LocalPartnerUpdate {
  const LocalPartnerUpdate({
    required this.id,
    required this.snapshots,
    required this.receivedAt,
  });
  final String id;
  final List<PartnerSnapshot> snapshots;
  final DateTime receivedAt;
  PartnerSnapshot get latest => snapshots.first;
  Map<String, dynamic> toJson() => {
    'id': id,
    'snapshots': snapshots.map((s) => s.toJson()).toList(),
    'received_at': receivedAt.toIso8601String(),
  };
  factory LocalPartnerUpdate.fromJson(Map<String, dynamic> j) =>
      LocalPartnerUpdate(
        id: j['id'] as String,
        snapshots: (j['snapshots'] as List)
            .map(
              (s) =>
                  PartnerSnapshot.fromJson((s as Map).cast<String, dynamic>()),
            )
            .toList(),
        receivedAt: DateTime.parse(j['received_at'] as String),
      );
}

class PartnerInboxRepository {
  static const key = 'cc.partner.inbox.v1';
  Future<List<LocalPartnerUpdate>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map(
          (j) =>
              LocalPartnerUpdate.fromJson((j as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> _save(List<LocalPartnerUpdate> items) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode(items.map((i) => i.toJson()).toList()),
    ))
      throw StateError('Could not save received updates');
  }

  Future<String> receive(
    String code, {
    String? replaceId,
    DateTime? now,
  }) async {
    final snapshot = decodeShareCode(code, now: now);
    final items = await load();
    if (replaceId != null) {
      final index = items.indexWhere((i) => i.id == replaceId);
      if (index < 0) throw StateError('Dashboard no longer exists');
      final previous = items[index];
      if (!snapshot.createdAt.isAfter(previous.latest.createdAt))
        throw const FormatException(
          'This update is not newer than the one already saved.',
        );
      items[index] = LocalPartnerUpdate(
        id: replaceId,
        snapshots: [snapshot, ...previous.snapshots].take(30).toList(),
        receivedAt: now ?? DateTime.now(),
      );
    } else {
      final id = const Uuid().v4();
      items.insert(
        0,
        LocalPartnerUpdate(
          id: id,
          snapshots: [snapshot],
          receivedAt: now ?? DateTime.now(),
        ),
      );
      await _save(items);
      return id;
    }
    await _save(items);
    return replaceId;
  }

  Future<void> remove(String id) async =>
      _save((await load()).where((i) => i.id != id).toList());
}
