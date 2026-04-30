import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare_flutter/core/services/partner_service.dart';

void main() {
  group('PartnerLink', () {
    test('copyWith preserves original values when not overridden', () {
      const link = PartnerLink(
        inviteCode: 'ABC123',
        ownerUid: 'owner1',
        partnerUid: null,
        shareCyclePhase: true,
        sharePeriodPrediction: true,
        shareMoodSummary: false,
        shareSymptoms: false,
        shareFlow: false,
      );

      final updated = link.copyWith(shareMoodSummary: true);
      expect(updated.inviteCode, 'ABC123');
      expect(updated.ownerUid, 'owner1');
      expect(updated.shareCyclePhase, true);
      expect(updated.shareMoodSummary, true);
      expect(updated.shareFlow, false);
    });

    test('isLinked returns true only when partnerUid is set', () {
      const unlinked = PartnerLink(inviteCode: 'X', ownerUid: 'o');
      const linked = PartnerLink(inviteCode: 'Y', ownerUid: 'o', partnerUid: 'p');
      expect(unlinked.isLinked, false);
      expect(linked.isLinked, true);
    });

    test('toJson and fromJson roundtrip correctly', () {
      const link = PartnerLink(
        inviteCode: 'TEST01',
        ownerUid: 'uid1',
        partnerUid: 'uid2',
        shareCyclePhase: false,
        sharePeriodPrediction: true,
        shareMoodSummary: true,
        shareSymptoms: false,
        shareFlow: true,
      );

      final json = link.toJson();
      final restored = PartnerLink.fromJson(json);
      expect(restored.inviteCode, link.inviteCode);
      expect(restored.ownerUid, link.ownerUid);
      expect(restored.partnerUid, link.partnerUid);
      expect(restored.shareCyclePhase, link.shareCyclePhase);
      expect(restored.sharePeriodPrediction, link.sharePeriodPrediction);
      expect(restored.shareMoodSummary, link.shareMoodSummary);
      expect(restored.shareSymptoms, link.shareSymptoms);
      expect(restored.shareFlow, link.shareFlow);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final restored = PartnerLink.fromJson({
        'inviteCode': 'DEF',
        'ownerUid': 'o',
      });
      expect(restored.shareCyclePhase, true);
      expect(restored.sharePeriodPrediction, true);
      expect(restored.shareMoodSummary, false);
      expect(restored.shareSymptoms, false);
      expect(restored.shareFlow, false);
      expect(restored.partnerUid, null);
    });
  });

  group('SharedCycleData', () {
    test('toJson and fromJson roundtrip correctly', () {
      const data = SharedCycleData(
        cycleDay: 12,
        currentPhase: 'Follicular',
        daysUntilPeriod: 16,
        nextPeriodDate: '2024-02-01',
        mood: 'Calm',
        symptoms: ['Headache'],
        flow: 'Light',
        confidence: 0.85,
      );

      final json = data.toJson();
      final restored = SharedCycleData.fromJson(json);
      expect(restored.cycleDay, data.cycleDay);
      expect(restored.currentPhase, data.currentPhase);
      expect(restored.daysUntilPeriod, data.daysUntilPeriod);
      expect(restored.nextPeriodDate, data.nextPeriodDate);
      expect(restored.mood, data.mood);
      expect(restored.symptoms, data.symptoms);
      expect(restored.flow, data.flow);
      expect(restored.confidence, data.confidence);
    });
  });
}
