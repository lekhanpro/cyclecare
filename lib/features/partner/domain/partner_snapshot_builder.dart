import '../../tracking/domain/cycle_models.dart';
import '../application/partner_sharing_controller.dart';
import 'partner_share_code.dart';

// Builds what the partner will see from the owner's data and switches.
//
// This one function feeds both the live "preview as your partner" screen and
// the share code, so the preview cannot drift from what is actually sent.

/// How long a code stays valid.
const shareCodeLifetime = Duration(days: 7);

PartnerSnapshot buildPartnerSnapshot({
  required CyclePrediction? prediction,
  required DailyLog? todayLog,
  required PartnerSharingOptions options,
  required String ownerName,
  required DateTime now,
}) {
  final p = prediction;
  final log = todayLog;
  final note = options.note.trim();

  return PartnerSnapshot(
    createdAt: now,
    expiresAt: now.add(shareCodeLifetime),
    ownerName: ownerName.trim().isEmpty ? null : ownerName.trim(),
    phase: options.sharePhase && p != null ? p.currentPhase.label : null,
    cycleDay: options.sharePhase && p != null ? p.cycleDay : null,
    nextPeriod: options.shareNextPeriod && p != null ? p.nextPeriodStart : null,
    daysLate: options.shareNextPeriod && p != null && p.isLate
        ? p.daysLate
        : null,
    fertileStart:
        options.shareFertileWindow && p != null ? p.fertileWindowStart : null,
    fertileEnd:
        options.shareFertileWindow && p != null ? p.fertileWindowEnd : null,
    ovulation: options.shareOvulation && p != null ? p.ovulationDate : null,
    pmsStart: options.sharePms && p != null ? p.pmsWindowStart : null,
    pmsEnd: options.sharePms && p != null ? p.pmsWindowEnd : null,
    mood: options.shareMood && (log?.mood?.isNotEmpty ?? false)
        ? log!.mood
        : null,
    symptoms: options.shareSymptoms && (log?.symptoms.isNotEmpty ?? false)
        ? log!.symptoms
        : null,
    painLevel: options.sharePain && log != null ? log.painLevel : null,
    supportTip: options.shareSupportTip && p != null
        ? supportTipFor(p.currentPhase)
        : null,
    note: note.isEmpty ? null : note,
  );
}

/// One line of practical, non-clinical guidance for a partner.
///
/// Framed as what tends to help rather than instructions, and kept mild: nobody
/// wants an app telling their partner how to manage them.
String supportTipFor(CyclePhase phase) => switch (phase) {
      CyclePhase.menstrual =>
        'Energy is usually lowest now. Warmth, food, and a lighter schedule '
            'tend to help more than anything else.',
      CyclePhase.follicular =>
        'Energy is usually climbing in this stretch — a good window for plans '
            'and bigger things.',
      CyclePhase.ovulation =>
        'Energy and mood are often at their highest around now.',
      CyclePhase.luteal =>
        'The days before a period can bring lower energy and a shorter fuse. '
            'Patience and an early night both go a long way.',
    };
