import 'package:cyclecare/core/theme/app_theme.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_phase_model.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/domain/hormone_illustration.dart';
import 'package:cyclecare/features/tracking/presentation/home_cycle_dial.dart';
import 'package:cyclecare/features/tracking/presentation/home_hormone_chart.dart';
import 'package:cyclecare/widgets/phase_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../shots/shot_harness.dart' show loadShotFonts;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The design's fictional cycle: Oct 8 start, 28 days, today day 23.
CyclePhaseModel designModel({bool showFertileWindow = true, bool showOvulation = true}) {
  final today = DateTime(2025, 10, 30);
  final prediction = const CyclePredictionService().buildPrediction(
    periods: [
      for (var i = 0; i < 6; i++)
        CycleEvent(
          id: 'p$i',
          startDate: DateTime(2025, 10, 8 - 28 * i),
          endDate: DateTime(2025, 10, 12 - 28 * i),
        ),
    ],
    preferences: const CyclePreferences(averageCycleLength: 28, averagePeriodLength: 5),
    referenceDate: today,
  )!;
  return CyclePhaseModel.fromPrediction(
    prediction,
    today: today,
    showFertileWindow: showFertileWindow,
    showOvulation: showOvulation,
  );
}

Widget host(Widget child, {bool reducedMotion = false}) => MaterialApp(
      theme: AppTheme.light(const Color(0xFF793F58)),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ),
      ),
    );

/// Parent that owns the shared selected day, like Home will.
class _Linked extends StatefulWidget {
  const _Linked({required this.model, this.dial = true, this.chart = false});

  final CyclePhaseModel model;
  final bool dial;
  final bool chart;

  @override
  State<_Linked> createState() => _LinkedState();
}

class _LinkedState extends State<_Linked> {
  late int day = widget.model.cycleDay;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (widget.dial)
            CycleDial(
              model: widget.model,
              selectedDay: day,
              onDayChanged: (d) => setState(() => day = d),
              onExplainEstimate: () {},
            ),
          if (widget.chart)
            HormoneChart(
              model: widget.model,
              selectedDay: day,
              onDayChanged: (d) => setState(() => day = d),
            ),
        ],
      );
}

void main() {
  testWidgets('compact enlarged chart range and cycle heading remain readable', (tester) async {
    await tester.runAsync(loadShotFonts);
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(host(_Linked(model: designModel(), chart: true), reducedMotion: true));
    await tester.pumpAndSettle();
    for (final label in ['Your cycle', 'Full cycle', 'This phase']) {
      final text = find.text(label);
      expect(text, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(text);
      expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      expect(paragraph.size.height, greaterThan(0), reason: label);
      final widget = tester.widget<Text>(text);
      final longest = label.split(' ').reduce((a, b) => a.length >= b.length ? a : b);
      final word = TextPainter(text: TextSpan(text: longest, style: widget.style),
        textDirection: TextDirection.ltr, textScaler: const TextScaler.linear(2))..layout();
      expect(paragraph.size.width, greaterThanOrEqualTo(word.width - 1),
        reason: '$label must fit a complete word');
      word.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  group('PhaseBar', () {
    testWidgets('segment widths follow the model fractions', (tester) async {
      final model = designModel();
      await tester.pumpWidget(host(SizedBox(width: 310, child: PhaseBar(model: model))));
      final widths = PhaseBar.segmentWidths(model, 310);
      const available = 310 - PhaseBar.segmentGap * 3;
      for (var i = 0; i < model.segments.length; i++) {
        final seg = model.segments[i];
        final size = tester.getSize(find.byKey(ValueKey('phase-bar-${seg.phase.name}')));
        expect(size.width, closeTo(widths[i], 0.01));
        expect(size.height, PhaseBar.trackHeight);
        if (seg.phase != CyclePhase.ovulation) {
          // The ovulation floor borrows only from the widest (luteal) segment.
          if (seg.phase != CyclePhase.luteal) {
            expect(size.width, closeTo(seg.fractionWidth * available, 0.01));
          }
        } else {
          expect(size.width, greaterThanOrEqualTo(PhaseBar.ovulationFloor));
        }
      }
    });

    testWidgets('hiding the fertile window removes its lane bar', (tester) async {
      await tester.pumpWidget(
          host(SizedBox(width: 310, child: PhaseBar(model: designModel()))));
      expect(find.byKey(const ValueKey('phase-lane-fertile')), findsOneWidget);
      expect(find.byKey(const ValueKey('phase-lane-pms')), findsOneWidget);

      await tester.pumpWidget(host(SizedBox(
          width: 310, child: PhaseBar(model: designModel(showFertileWindow: false)))));
      expect(find.byKey(const ValueKey('phase-lane-fertile')), findsNothing);
      expect(find.byKey(const ValueKey('phase-lane-pms')), findsOneWidget);
    });

    testWidgets('ovulation callout hides when ovulation is not shown', (tester) async {
      await tester.pumpWidget(host(SizedBox(
          width: 310, child: PhaseBar(model: designModel(showOvulation: false)))));
      expect(find.byKey(const ValueKey('phase-bar-ovulation-callout')), findsNothing);
    });

    testWidgets('one semantics label carries the spoken summary', (tester) async {
      final model = designModel();
      await tester.pumpWidget(host(SizedBox(width: 310, child: PhaseBar(model: model))));
      expect(find.bySemanticsLabel(model.spokenSummary), findsOneWidget);
    });

    testWidgets('tabs report selection and call back', (tester) async {
      final model = designModel();
      CyclePhase? tapped;
      await tester.pumpWidget(host(PhaseTabs(
        model: model,
        selected: CyclePhase.luteal,
        onSelected: (p) => tapped = p,
      )));
      await tester.tap(find.byKey(const ValueKey('phase-tab-follicular')));
      expect(tapped, CyclePhase.follicular);
      final luteal = tester.getSemantics(find.byKey(const ValueKey('phase-tab-luteal')));
      expect(luteal, containsSemantics(isSelected: true, isButton: true));
      expect(tester.getSize(find.byKey(const ValueKey('phase-tab-luteal'))).height,
          greaterThanOrEqualTo(54));
    });
  });

  group('CycleDial', () {
    const target10 = (10 - 0.5) / 28 * 2 * 3.141592653589793;
    double dialAngle(WidgetTester tester) => (tester
            .widget<CustomPaint>(find.byKey(const ValueKey('cycle-dial-paint')))
            .painter! as CycleDialPainter)
        .cursorAngle;

    String centre(WidgetTester tester) => tester
        .widgetList<Text>(find.descendant(
            of: find.byKey(const ValueKey('cycle-dial-centre')), matching: find.byType(Text)))
        .map((t) => t.data)
        .join(' | ');

    testWidgets('dragging the ring selects a day and Today resets it', (tester) async {
      final model = designModel();
      await tester.pumpWidget(host(_Linked(model: model)));
      expect(centre(tester), contains('Period in about'));

      // Drag to the 3 o'clock position: a quarter of the way round, day 8.
      final ring = find.byKey(const ValueKey('cycle-dial-ring'));
      final rect = tester.getRect(ring);
      final gesture = await tester.startGesture(rect.topCenter + const Offset(0, 6));
      await gesture.moveTo(rect.centerRight - const Offset(6, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(centre(tester), contains('Exploring cycle day'));
      expect(centre(tester), contains('8'));
      expect(find.text('Day 8 of 28'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cycle-dial-today')));
      await tester.pumpAndSettle();
      expect(find.text('Day 23 of 28'), findsOneWidget);
      expect(centre(tester), contains('Period in about'));
    });

    testWidgets('keyboard arrows, Home and End move the day', (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel())));
      await tester.tap(find.byKey(const ValueKey('cycle-dial-ring')),
          warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(find.text('Day 1 of 28'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Day 2 of 28'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(find.text('Day 28 of 28'), findsOneWidget);
    });

    testWidgets('the next-period estimate stays anchored while exploring',
        (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel())));
      final before =
          tester.widget<Text>(find.byKey(const ValueKey('cycle-dial-forecast'))).data;
      expect(before, 'November 5–9');

      final slider = tester.widget<Slider>(find.byKey(const ValueKey('cycle-dial-slider')));
      slider.onChanged!(4);
      await tester.pumpAndSettle();
      expect(find.text('Day 4 of 28'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('cycle-dial-forecast'))).data,
        before,
      );
    });

    testWidgets('reduced motion moves the cursor without animating', (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel()), reducedMotion: true));
      tester
          .widget<Slider>(find.byKey(const ValueKey('cycle-dial-slider')))
          .onChanged!(10);
      await tester.pump();
      expect(dialAngle(tester), closeTo(target10, 1e-9));
    });

    testWidgets('without reduced motion the cursor animates', (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel())));
      tester
          .widget<Slider>(find.byKey(const ValueKey('cycle-dial-slider')))
          .onChanged!(10);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect((dialAngle(tester) - target10).abs(), greaterThan(0.01));
      await tester.pumpAndSettle();
      expect(dialAngle(tester), closeTo(target10, 1e-6));
    });
  });

  group('HormoneChart', () {
    HormoneChartPainter painter(WidgetTester tester) => tester
        .widget<CustomPaint>(find.byKey(const ValueKey('hormone-chart-paint')))
        .painter! as HormoneChartPainter;

    testWidgets('focusing a hormone mutes the others and All resets', (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel(), dial: false, chart: true)));
      expect(painter(tester).focus, isNull);

      await tester.ensureVisible(find.byKey(const ValueKey('hormone-readout-lh')));
      await tester.tap(find.byKey(const ValueKey('hormone-readout-lh')));
      await tester.pumpAndSettle();
      final p = painter(tester);
      expect(p.focus, HormoneKind.lh);
      expect(p.isMuted(HormoneKind.estrogen), isTrue);
      expect(p.isMuted(HormoneKind.lh), isFalse);
      expect(find.text('LH pattern'), findsOneWidget);
      final lh = tester.getSemantics(find.byKey(const ValueKey('hormone-readout-lh')));
      expect(lh, containsSemantics(isSelected: true, isButton: true));

      await tester.ensureVisible(find.byKey(const ValueKey('hormone-all')));
      await tester.tap(find.byKey(const ValueKey('hormone-all')));
      await tester.pumpAndSettle();
      expect(painter(tester).focus, isNull);
      expect(find.text('Luteal phase'), findsOneWidget);
    });

    testWidgets('scrubbing the plot follows the pointer at once', (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel(), dial: false, chart: true)));
      final stage = find.byKey(const ValueKey('hormone-chart-stage'));
      final rect = tester.getRect(stage);
      // Day 1 sits at x = 35 / 336 of the width.
      await tester.tapAt(Offset(rect.left + rect.width * 35 / 336 + 1, rect.center.dy));
      await tester.pump();
      expect(painter(tester).day, 1);
      expect(find.text('Day 1 · Menstrual'), findsOneWidget);
    });

    testWidgets('dial and chart share the selected day', (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel(), chart: true)));
      tester
          .widget<Slider>(find.byKey(const ValueKey('cycle-dial-slider')))
          .onChanged!(15);
      await tester.pumpAndSettle();
      expect(painter(tester).day, 15);
      expect(find.text('Day 15 · Ovulation'), findsOneWidget);
    });

    testWidgets('never renders a unit or a concentration number', (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel(), dial: false, chart: true)));
      final unit = RegExp(r'\b(pg|ng|ml|iu|miu|nmol|pmol)\b|/(ml|l)\b|%',
          caseSensitive: false);
      final readouts = <String>[];
      for (final k in HormoneKind.values) {
        final node =
            tester.getSemantics(find.byKey(ValueKey('hormone-readout-${k.name}')));
        readouts.add(node.label);
        expect(node.label, isNot(matches(RegExp(r'\d'))));
      }
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        expect(t.data ?? '', isNot(matches(unit)), reason: t.data);
      }
      for (final r in readouts) {
        expect(r, contains('in the illustration'));
      }
      expect(find.text('Educational illustration, not your measured hormone levels.'),
          findsOneWidget);
    });

    testWidgets('This phase zoom narrows the plot to the selected phase',
        (tester) async {
      await tester.pumpWidget(host(_Linked(model: designModel(), dial: false, chart: true)));
      await tester.tap(find.text('This phase'));
      await tester.pumpAndSettle();
      final p = painter(tester);
      expect(p.from, 15);
      expect(p.to, 28);
    });
  });
}
