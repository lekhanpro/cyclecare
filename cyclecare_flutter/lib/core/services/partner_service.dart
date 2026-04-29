import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartnerLink {
  const PartnerLink({
    required this.inviteCode,
    required this.ownerUid,
    this.partnerUid,
    this.ownerDisplayName,
    this.partnerDisplayName,
    this.shareCyclePhase = true,
    this.sharePeriodPrediction = true,
    this.shareMoodSummary = false,
    this.shareSymptoms = false,
    this.shareFlow = false,
    this.createdAt,
  });

  final String inviteCode;
  final String ownerUid;
  final String? partnerUid;
  final String? ownerDisplayName;
  final String? partnerDisplayName;
  final bool shareCyclePhase;
  final bool sharePeriodPrediction;
  final bool shareMoodSummary;
  final bool shareSymptoms;
  final bool shareFlow;
  final DateTime? createdAt;

  bool get isLinked => partnerUid != null;

  Map<String, dynamic> toJson() => {
        'inviteCode': inviteCode,
        'ownerUid': ownerUid,
        'partnerUid': partnerUid,
        'ownerDisplayName': ownerDisplayName,
        'partnerDisplayName': partnerDisplayName,
        'shareCyclePhase': shareCyclePhase,
        'sharePeriodPrediction': sharePeriodPrediction,
        'shareMoodSummary': shareMoodSummary,
        'shareSymptoms': shareSymptoms,
        'shareFlow': shareFlow,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  factory PartnerLink.fromJson(Map<String, dynamic> json) => PartnerLink(
        inviteCode: json['inviteCode'] as String,
        ownerUid: json['ownerUid'] as String,
        partnerUid: json['partnerUid'] as String?,
        ownerDisplayName: json['ownerDisplayName'] as String?,
        partnerDisplayName: json['partnerDisplayName'] as String?,
        shareCyclePhase: json['shareCyclePhase'] as bool? ?? true,
        sharePeriodPrediction: json['sharePeriodPrediction'] as bool? ?? true,
        shareMoodSummary: json['shareMoodSummary'] as bool? ?? false,
        shareSymptoms: json['shareSymptoms'] as bool? ?? false,
        shareFlow: json['shareFlow'] as bool? ?? false,
        createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      );

  PartnerLink copyWith({
    bool? shareCyclePhase,
    bool? sharePeriodPrediction,
    bool? shareMoodSummary,
    bool? shareSymptoms,
    bool? shareFlow,
    String? partnerUid,
    String? partnerDisplayName,
  }) =>
      PartnerLink(
        inviteCode: inviteCode,
        ownerUid: ownerUid,
        partnerUid: partnerUid ?? this.partnerUid,
        ownerDisplayName: ownerDisplayName,
        partnerDisplayName: partnerDisplayName ?? this.partnerDisplayName,
        shareCyclePhase: shareCyclePhase ?? this.shareCyclePhase,
        sharePeriodPrediction: sharePeriodPrediction ?? this.sharePeriodPrediction,
        shareMoodSummary: shareMoodSummary ?? this.shareMoodSummary,
        shareSymptoms: shareSymptoms ?? this.shareSymptoms,
        shareFlow: shareFlow ?? this.shareFlow,
        createdAt: createdAt,
      );
}

class SharedCycleData {
  const SharedCycleData({
    this.cycleDay,
    this.currentPhase,
    this.daysUntilPeriod,
    this.nextPeriodDate,
    this.mood,
    this.symptoms,
    this.flow,
    this.confidence,
    this.updatedAt,
  });

  final int? cycleDay;
  final String? currentPhase;
  final int? daysUntilPeriod;
  final String? nextPeriodDate;
  final String? mood;
  final List<String>? symptoms;
  final String? flow;
  final double? confidence;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'cycleDay': cycleDay,
        'currentPhase': currentPhase,
        'daysUntilPeriod': daysUntilPeriod,
        'nextPeriodDate': nextPeriodDate,
        'mood': mood,
        'symptoms': symptoms,
        'flow': flow,
        'confidence': confidence,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory SharedCycleData.fromJson(Map<String, dynamic> json) => SharedCycleData(
        cycleDay: json['cycleDay'] as int?,
        currentPhase: json['currentPhase'] as String?,
        daysUntilPeriod: json['daysUntilPeriod'] as int?,
        nextPeriodDate: json['nextPeriodDate'] as String?,
        mood: json['mood'] as String?,
        symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>(),
        flow: json['flow'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble(),
        updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      );
}

class PartnerService {
  PartnerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _links =>
      _firestore.collection('partner_links');

  CollectionReference<Map<String, dynamic>> get _sharedData =>
      _firestore.collection('shared_cycle_data');

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<PartnerLink> createInvite(User user) async {
    final existing = await _links
        .where('ownerUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return PartnerLink.fromJson(existing.docs.first.data());
    }

    final code = _generateCode();
    final link = PartnerLink(
      inviteCode: code,
      ownerUid: user.uid,
      ownerDisplayName: user.displayName,
      createdAt: DateTime.now(),
    );
    await _links.doc(code).set(link.toJson());
    return link;
  }

  Future<PartnerLink?> acceptInvite(User user, String code) async {
    final upperCode = code.toUpperCase().trim();
    final doc = await _links.doc(upperCode).get();
    if (!doc.exists) return null;

    final link = PartnerLink.fromJson(doc.data()!);
    if (link.ownerUid == user.uid) return null;
    if (link.partnerUid != null && link.partnerUid != user.uid) return null;

    final updated = link.copyWith(
      partnerUid: user.uid,
      partnerDisplayName: user.displayName,
    );
    await _links.doc(upperCode).update({
      'partnerUid': user.uid,
      'partnerDisplayName': user.displayName,
    });
    return updated;
  }

  Future<void> updatePermissions(PartnerLink link) async {
    await _links.doc(link.inviteCode).update({
      'shareCyclePhase': link.shareCyclePhase,
      'sharePeriodPrediction': link.sharePeriodPrediction,
      'shareMoodSummary': link.shareMoodSummary,
      'shareSymptoms': link.shareSymptoms,
      'shareFlow': link.shareFlow,
    });
  }

  Future<void> revokeLink(String code) async {
    await _links.doc(code).delete();
  }

  Future<void> pushSharedData(String ownerUid, SharedCycleData data) async {
    await _sharedData.doc(ownerUid).set(data.toJson());
  }

  Stream<SharedCycleData?> watchSharedData(String ownerUid) {
    return _sharedData.doc(ownerUid).snapshots().map(
      (snap) {
        if (!snap.exists || snap.data() == null) return null;
        return SharedCycleData.fromJson(snap.data()!);
      },
    );
  }

  Stream<PartnerLink?> watchMyLink(String uid) {
    return _links
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return PartnerLink.fromJson(snap.docs.first.data());
    });
  }

  Stream<PartnerLink?> watchPartnerLink(String uid) {
    return _links
        .where('partnerUid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return PartnerLink.fromJson(snap.docs.first.data());
    });
  }
}
