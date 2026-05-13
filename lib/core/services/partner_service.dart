// Partner service — stub until Supabase Realtime is configured.
class PartnerService {
  Future<void> pushSharedData(String uid, dynamic data) async {}
  Stream<dynamic> watchMyLink(String uid) => const Stream.empty();
  Stream<dynamic> watchPartnerLink(String uid) => const Stream.empty();
  Stream<dynamic> watchSharedData(String ownerUid) => const Stream.empty();
}

class PartnerLink {
  const PartnerLink({required this.code, required this.ownerUid});
  final String code;
  final String ownerUid;
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
  });

  final int? cycleDay;
  final String? currentPhase;
  final int? daysUntilPeriod;
  final String? nextPeriodDate;
  final String? mood;
  final List<String>? symptoms;
  final String? flow;
  final double? confidence;
}
