import 'package:cyclecare/features/partner/application/partner_sharing_controller.dart';
import 'package:cyclecare/features/partner/domain/partner_share_code.dart';
import 'package:cyclecare/features/partner/domain/partner_snapshot_builder.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 3, 9);
  final lastStart = DateTime(2026, 10, 1);

  final prediction = const CyclePredictionService().buildPrediction(
    periods: [
      for (var i = 0; i < 4; i++)
        CycleEvent(
          id: 'p$i',
          startDate: lastStart.subtract(Duration(days: 28 * i)),
          endDate: lastStart.subtract(Duration(days: 28 * i - 4)),
        ),
    ],
    preferences: const CyclePreferences(),
    referenceDate: now,
  )!;

  final log = DailyLog(
    date: DateTime(2026, 10, 3),
    mood: 'Tired',
    symptoms: const ['Cramps'],
    painLevel: 4,
  );

  const allOff = PartnerSharingOptions(
    sharePhase: false,
    shareNextPeriod: false,
    shareSupportTip: false,
  );

  test('nothing switched on shares nothing but the owner name', () {
    final s = buildPartnerSnapshot(
      prediction: prediction,
      todayLog: log,
      options: allOff,
      ownerName: 'Ava',
      now: now,
    );
    expect(s.ownerName, 'Ava');
    for (final v in [
      s.phase, s.cycleDay, s.nextPeriod, s.fertileStart, s.ovulation,
      s.pmsStart, s.mood, s.symptoms, s.painLevel, s.supportTip, s.note,
    ]) {
      expect(v, isNull);
    }
  });

  test('each switch adds exactly its own field', () {
    PartnerSnapshot snap(PartnerSharingOptions o) => buildPartnerSnapshot(
          prediction: prediction,
          todayLog: log,
          options: o,
          ownerName: 'Ava',
          now: now,
        );

    final phase = snap(allOff.copyWith(sharePhase: true));
    expect(phase.phase, 'Menstrual');
    expect(phase.cycleDay, 3);
    expect(phase.mood, isNull);

    expect(snap(allOff.copyWith(shareNextPeriod: true)).nextPeriod,
        DateTime(2026, 10, 29));
    expect(snap(allOff.copyWith(shareFertileWindow: true)).fertileStart,
        DateTime(2026, 10, 10));
    expect(snap(allOff.copyWith(shareOvulation: true)).ovulation,
        DateTime(2026, 10, 15));
    expect(snap(allOff.copyWith(sharePms: true)).pmsStart,
        DateTime(2026, 10, 24));
    expect(snap(allOff.copyWith(shareMood: true)).mood, 'Tired');
    expect(snap(allOff.copyWith(shareSymptoms: true)).symptoms,
        ['Cramps']);
    expect(snap(allOff.copyWith(sharePain: true)).painLevel, 4);
    expect(snap(allOff.copyWith(shareSupportTip: true)).supportTip,
        isNotEmpty);
  });

  test('a blank note is not sent; a real one is trimmed', () {
    final blank = buildPartnerSnapshot(
      prediction: prediction,
      todayLog: log,
      options: allOff.copyWith(note: '   '),
      ownerName: '',
      now: now,
    );
    expect(blank.note, isNull);
    expect(blank.ownerName, isNull);

    final real = buildPartnerSnapshot(
      prediction: prediction,
      todayLog: log,
      options: allOff.copyWith(note: '  Pizza tonight?  '),
      ownerName: 'Ava',
      now: now,
    );
    expect(real.note, 'Pizza tonight?');
  });

  test('mood and symptoms switched on but not logged stay absent', () {
    final s = buildPartnerSnapshot(
      prediction: prediction,
      todayLog: null,
      options: allOff.copyWith(shareMood: true, shareSymptoms: true, sharePain: true),
      ownerName: 'Ava',
      now: now,
    );
    expect(s.mood, isNull);
    expect(s.symptoms, isNull);
    expect(s.painLevel, isNull);
  });

  test('the code expires a week after it is made', () {
    final s = buildPartnerSnapshot(
      prediction: prediction,
      todayLog: log,
      options: allOff,
      ownerName: 'Ava',
      now: now,
    );
    expect(s.expiresAt, now.add(const Duration(days: 7)));
  });
}
