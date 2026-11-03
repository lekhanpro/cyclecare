import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_phase_model.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A regular history ending with a period that starts on [lastStart].
List<CycleEvent> _history(
  DateTime lastStart, {
  int cycles = 6,
  int length = 28,
  int periodLength = 5,
}) {
  return [
    for (var i = 0; i < cycles; i++)
      CycleEvent(
        id: 'p$i',
        startDate: DateTime(
          lastStart.year,
          lastStart.month,
          lastStart.day - length * i,
        ),
        endDate: DateTime(
          lastStart.year,
          lastStart.month,
          lastStart.day - length * i + periodLength - 1,
        ),
      ),
  ];
}

CyclePrediction _predict(
  DateTime lastStart,
  DateTime today, {
  int length = 28,
  int periodLength = 5,
  int cycles = 6,
}) {
  return const CyclePredictionService().buildPrediction(
    periods: _history(
      lastStart,
      cycles: cycles,
      length: length,
      periodLength: periodLength,
    ),
    preferences: CyclePreferences(
      averageCycleLength: length,
      averagePeriodLength: periodLength,
    ),
    referenceDate: today,
  )!;
}

void main() {
  // ── The design's fictional cycle ──────────────────────────────────────────
  //
  // Cycle starts Oct 8, length 28, period 5, luteal 14, next period Nov 5,
  // today Oct 30 = day 23. Every number asserted below is read off
  // `redesign/home-refinement.css` and `D:/tmp/design-ref/home/*-spec.txt`.
  final lastStart = DateTime(2025, 10, 8);
  final today = DateTime(2025, 10, 30);

  CyclePhaseModel designModel({
    bool showFertileWindow = true,
    bool showOvulation = true,
  }) =>
      CyclePhaseModel.fromPrediction(
        _predict(lastStart, today),
        today: today,
        showFertileWindow: showFertileWindow,
        showOvulation: showOvulation,
      );

  group('the design example cycle', () {
    test('anchors on Oct 8 with a 28-day length and day 23 today', () {
      final model = designModel();

      expect(model.cycleStart, DateTime(2025, 10, 8));
      expect(model.cycleLength, 28);
      expect(model.cycleEnd, DateTime(2025, 11, 4));
      expect(model.nextPeriodStart, DateTime(2025, 11, 5));
      expect(model.cycleDay, 23);
      expect(model.currentPhase, CyclePhase.luteal);
      expect(model.wasClamped, isFalse);
    });

    test('lays out four segments on the design dates and day ranges', () {
      final model = designModel();

      expect(
        model.segments.map((s) => s.phase).toList(),
        [
          CyclePhase.menstrual,
          CyclePhase.follicular,
          CyclePhase.ovulation,
          CyclePhase.luteal,
        ],
      );

      // menstrual days 1-5, Oct 8-12.
      final menstrual = model.segmentOf(CyclePhase.menstrual);
      expect(menstrual.startDay, 1);
      expect(menstrual.endDay, 5);
      expect(menstrual.start, DateTime(2025, 10, 8));
      expect(menstrual.end, DateTime(2025, 10, 12));

      // follicular days 6-14, Oct 13-21 — the whole phase, not the early
      // CycleWindows gap that ends on Oct 16.
      final follicular = model.segmentOf(CyclePhase.follicular);
      expect(follicular.startDay, 6);
      expect(follicular.endDay, 14);
      expect(follicular.start, DateTime(2025, 10, 13));
      expect(follicular.end, DateTime(2025, 10, 21));

      // ovulation day 15, Oct 22 — one day, from ovulationDate.
      final ovulation = model.segmentOf(CyclePhase.ovulation);
      expect(ovulation.startDay, 15);
      expect(ovulation.endDay, 15);
      expect(ovulation.start, DateTime(2025, 10, 22));
      expect(ovulation.end, DateTime(2025, 10, 22));
      expect(ovulation.lengthInDays, 1);

      // luteal days 16-28, Oct 23-Nov 4.
      final luteal = model.segmentOf(CyclePhase.luteal);
      expect(luteal.startDay, 16);
      expect(luteal.endDay, 28);
      expect(luteal.start, DateTime(2025, 10, 23));
      expect(luteal.end, DateTime(2025, 11, 4));
      expect(luteal.dateRangeLabel, 'Oct 23\u2013Nov 4');
    });

    test('segment fractions match the design CSS widths', () {
      final model = designModel();

      // .menstrual{width:17.857%} .follicular{32.143%} .ovulation{3.571%}
      expect(model.segmentOf(CyclePhase.menstrual).fractionWidth,
          closeTo(0.17857, 0.0001));
      expect(model.segmentOf(CyclePhase.follicular).fractionWidth,
          closeTo(0.32143, 0.0001));
      expect(model.segmentOf(CyclePhase.ovulation).fractionWidth,
          closeTo(0.03571, 0.0001));
      // Luteal is the remainder: flex:1 in the CSS.
      expect(model.segmentOf(CyclePhase.luteal).fractionWidth,
          closeTo(13 / 28, 0.0001));

      // .home-today-pin{left:80.357%} — the centre of day 23.
      expect(model.todayFraction, closeTo(0.80357, 0.0001));
    });

    test('overlays sit on the fertile and PMS windows, not in the sequence',
        () {
      final model = designModel();

      // fertile overlay days 10-16, Oct 17-23.
      final fertile = model.fertile!;
      expect(fertile.startDay, 10);
      expect(fertile.endDay, 16);
      expect(fertile.start, DateTime(2025, 10, 17));
      expect(fertile.end, DateTime(2025, 10, 23));
      // .home-fertile-band{left:32.143%;width:25%}
      expect(fertile.fractionStart, closeTo(0.32143, 0.0001));
      expect(fertile.fractionWidth, closeTo(0.25, 0.0001));

      // PMS overlay days 24-28, Oct 31-Nov 4.
      final pms = model.pms!;
      expect(pms.startDay, 24);
      expect(pms.endDay, 28);
      expect(pms.start, DateTime(2025, 10, 31));
      expect(pms.end, DateTime(2025, 11, 4));
      // .home-pms-band{left:82.143%;width:17.857%}
      expect(pms.fractionStart, closeTo(0.82143, 0.0001));
      expect(pms.fractionWidth, closeTo(0.17857, 0.0001));

      // The overlays overlap the segments — that is the point of being
      // overlays. Fertile spans late follicular, ovulation and early luteal.
      expect(model.segmentOnDay(fertile.startDay).phase,
          CyclePhase.follicular);
      expect(model.segmentOnDay(fertile.endDay).phase, CyclePhase.luteal);
      expect(model.segmentOnDay(pms.startDay).phase, CyclePhase.luteal);
    });

    test('the four segments stay contiguous and cover every cycle day', () {
      final model = designModel();

      var expectedDay = 1;
      for (final segment in model.segments) {
        expect(segment.startDay, expectedDay);
        expect(segment.endDay, greaterThanOrEqualTo(segment.startDay));
        expect(segment.fractionWidth, greaterThan(0));
        expectedDay = segment.endDay + 1;
      }
      expect(expectedDay - 1, model.cycleLength);

      // Every day resolves to exactly one segment.
      for (var day = 1; day <= model.cycleLength; day++) {
        final matches =
            model.segments.where((s) => s.containsDay(day)).toList();
        expect(matches.length, 1, reason: 'day $day');
      }
    });

    test('resolves a date to its segment, and nothing outside the cycle', () {
      final model = designModel();

      expect(model.segmentFor(DateTime(2025, 10, 8))!.phase,
          CyclePhase.menstrual);
      expect(model.segmentFor(DateTime(2025, 10, 13))!.phase,
          CyclePhase.follicular);
      expect(model.segmentFor(DateTime(2025, 10, 22))!.phase,
          CyclePhase.ovulation);
      expect(model.segmentFor(DateTime(2025, 11, 4))!.phase,
          CyclePhase.luteal);
      // Outside: the day before day 1 and the next period's first day.
      expect(model.segmentFor(DateTime(2025, 10, 7)), isNull);
      expect(model.segmentFor(DateTime(2025, 11, 5)), isNull);
    });

    test('reports which overlay today falls in', () {
      final model = designModel();

      // Oct 30 is day 23: inside neither window — PMS opens tomorrow.
      expect(model.isInFertileWindow, isFalse);
      expect(model.isInPmsWindow, isFalse);
      expect(model.isPmsOn(DateTime(2025, 10, 31)), isTrue);
      expect(model.isPmsOn(DateTime(2025, 11, 4)), isTrue);
      expect(model.isPmsOn(DateTime(2025, 11, 5)), isFalse);
      expect(model.isFertileOn(DateTime(2025, 10, 17)), isTrue);
      expect(model.isFertileOn(DateTime(2025, 10, 23)), isTrue);
      expect(model.isFertileOn(DateTime(2025, 10, 24)), isFalse);
    });

    test('speaks the design reference aria sentence', () {
      expect(
        designModel().spokenSummary,
        'Cycle day 23 of 28. '
        'Menstrual days 1 to 5, follicular days 6 to 14, '
        'estimated ovulation day 15, luteal days 16 to 28. '
        'Fertile window days 10 to 16. PMS window days 24 to 28.',
      );
    });
  });

  group('display preferences', () {
    test('hiding the fertile window drops the overlay, keeps four segments',
        () {
      final model = designModel(showFertileWindow: false);

      expect(model.fertile, isNull);
      expect(model.showsFertileWindow, isFalse);
      expect(model.isInFertileWindow, isFalse);
      expect(model.overlays.map((o) => o.kind).toList(),
          [CycleOverlayKind.pms]);
      // The sequence is untouched: the bar still adds up.
      expect(model.segments.length, 4);
      expect(model.segmentOf(CyclePhase.ovulation).startDay, 15);
    });

    test('hiding ovulation suppresses the callout, not the segment', () {
      final model = designModel(showOvulation: false);

      expect(model.showsOvulation, isFalse);
      expect(model.segments.length, 4);
      expect(model.segmentOf(CyclePhase.ovulation).startDay, 15);
      expect(model.spokenSummary, isNot(contains('ovulation')));
      expect(model.spokenSummary, contains('luteal days 16 to 28'));
    });
  });

  group('short and irregular cycles', () {
    test('a 21-day cycle keeps every segment at least a day long', () {
      final model = CyclePhaseModel.fromPrediction(
        _predict(lastStart, DateTime(2025, 10, 10), length: 21),
        today: DateTime(2025, 10, 10),
      );

      expect(model.cycleLength, 21);
      // Period 1-5, follicular 6-7, ovulation 8, luteal 9-21.
      expect(model.segmentOf(CyclePhase.menstrual).endDay, 5);
      expect(model.segmentOf(CyclePhase.follicular).startDay, 6);
      expect(model.segmentOf(CyclePhase.follicular).endDay, 7);
      expect(model.segmentOf(CyclePhase.ovulation).startDay, 8);
      expect(model.segmentOf(CyclePhase.luteal).startDay, 9);
      expect(model.segmentOf(CyclePhase.luteal).endDay, 21);

      for (final segment in model.segments) {
        expect(segment.lengthInDays, greaterThanOrEqualTo(1));
        expect(segment.end.isBefore(segment.start), isFalse);
      }
    });

    test('a long period on a short cycle yields to the other three phases',
        () {
      // A 21-day cycle logged with 9-day periods: days 1-9 would leave no
      // room, so the menstrual segment is the thing that gives.
      final model = CyclePhaseModel.fromPrediction(
        _predict(lastStart, DateTime(2025, 10, 10),
            length: 21, periodLength: 9),
        today: DateTime(2025, 10, 10),
      );

      var expectedDay = 1;
      for (final segment in model.segments) {
        expect(segment.startDay, expectedDay);
        expect(segment.lengthInDays, greaterThanOrEqualTo(1));
        expectedDay = segment.endDay + 1;
      }
      expect(expectedDay - 1, model.cycleLength);
      expect(model.segmentOf(CyclePhase.ovulation).lengthInDays, 1);
    });

    test('clamps a cycle too short to hold four phases, and says so', () {
      // Not reachable through the prediction service, which clamps cycle
      // length to 21-45. A hand-built prediction can still ask for it.
      final model = CyclePhaseModel.fromPrediction(
        CyclePrediction(
          nextPeriodStart: DateTime(2025, 10, 10),
          nextPeriodEnd: DateTime(2025, 10, 12),
          ovulationDate: DateTime(2025, 10, 9),
          fertileWindowStart: DateTime(2025, 10, 7),
          fertileWindowEnd: DateTime(2025, 10, 9),
          averageCycleLength: 2,
          averagePeriodLength: 5,
          confidence: 0.3,
          isIrregular: true,
          cycleDay: 1,
          daysUntilPeriod: 2,
          phase: 'Menstrual',
          isLate: false,
          daysLate: 0,
        ),
        today: DateTime(2025, 10, 8),
      );

      expect(model.wasClamped, isTrue);
      expect(model.cycleLength, 4);
      expect(model.segments.map((s) => s.lengthInDays).toList(),
          [1, 1, 1, 1]);
      expect(model.segments.last.endDay, 4);
    });

    test('a long gap since the last log leaves today past the cycle end', () {
      // Nearly two cycles since the last log. Once a period is late the
      // prediction service holds `nextPeriodStart` on the first expected date
      // — its roll-forward loop cannot run for a late cycle — so the model
      // lays out that expected cycle, Oct 8 to Nov 4, and today sits beyond
      // it. Home answers this with the late alert from the prediction rather
      // than inventing a cycle the records do not support.
      final lateDay = DateTime(2025, 12, 1);
      final model = CyclePhaseModel.fromPrediction(
        _predict(lastStart, lateDay),
        today: lateDay,
      );

      expect(model.cycleStart,
          model.nextPeriodStart.subtract(const Duration(days: 28)));
      expect(model.cycleEnd.isBefore(lateDay), isTrue);
      expect(model.segmentFor(lateDay), isNull);
      // The today pin stops at the end of the bar instead of running off it.
      expect(model.cycleDay, 28);
      expect(model.currentPhase, CyclePhase.luteal);
    });
  });

  group('history state', () {
    test('no logged period means no model at all', () {
      expect(CyclePhaseModel.maybeFromPrediction(null), isNull);
      expect(CyclePhaseModel.historyFor(null), CycleHistoryState.none);
      expect(CycleHistoryState.none.isSufficient, isFalse);
    });

    test('a single logged period is still learning', () {
      final prediction = const CyclePredictionService().buildPrediction(
        periods: [CycleEvent(id: 'p0', startDate: lastStart)],
        preferences: const CyclePreferences(),
        referenceDate: today,
      )!;
      final model = CyclePhaseModel.fromPrediction(prediction, today: today);

      expect(model.history, CycleHistoryState.learning);
      expect(model.history.isSufficient, isFalse);
      expect(model.cyclesTracked, 0);
      // Still a complete, renderable layout — just not a measured one.
      expect(model.segments.length, 4);
    });

    test('six logged cycles count as established', () {
      final model = designModel();

      expect(model.history, CycleHistoryState.established);
      expect(model.history.isSufficient, isTrue);
      expect(model.cyclesTracked, 5);
      expect(model.isIrregular, isFalse);
    });
  });
}
