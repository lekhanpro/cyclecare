// The four Home visuals (phase bar, phase tabs, cycle dial, hormone chart)
// stacked in one column, against the same cycle ShotSeed.typical() stores:
// day 23 of a 28-day cycle, five-day periods. Run with --dart-define=SHOTS=true.

import 'package:cyclecare/core/theme/cyclecare_theme.dart';
import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/cycle_phase_model.dart';
import 'package:cyclecare/features/tracking/domain/cycle_prediction_service.dart';
import 'package:cyclecare/features/tracking/presentation/home_cycle_dial.dart';
import 'package:cyclecare/features/tracking/presentation/home_hormone_chart.dart';
import 'package:cyclecare/widgets/phase_bar.dart';
import 'package:flutter/material.dart';

import 'shot_harness.dart';

CyclePhaseModel _typicalModel() {
  final today = ShotSeed.today;
  final lastStart = DateTime(today.year, today.month, today.day - 22);
  final prediction = const CyclePredictionService().buildPrediction(
    periods: [
      for (var i = 0; i < 7; i++)
        CycleEvent(
          id: 'shot-$i',
          startDate: DateTime(lastStart.year, lastStart.month, lastStart.day - 28 * i),
          endDate: DateTime(lastStart.year, lastStart.month, lastStart.day - 28 * i + 4),
        ),
    ],
    preferences: const CyclePreferences(averageCycleLength: 28, averagePeriodLength: 5),
    referenceDate: today,
  )!;
  return CyclePhaseModel.fromPrediction(prediction, today: today);
}

class _Column extends StatefulWidget {
  const _Column({required this.model});

  final CyclePhaseModel model;

  @override
  State<_Column> createState() => _ColumnState();
}

class _ColumnState extends State<_Column> {
  late int day = widget.model.cycleDay;
  late CyclePhase phase = widget.model.currentPhase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CycleDial(
                model: widget.model,
                selectedDay: day,
                onDayChanged: (d) => setState(() => day = d),
                onExplainEstimate: () {},
              ),
              const SizedBox(height: 16),
              HormoneChart(
                model: widget.model,
                selectedDay: day,
                onDayChanged: (d) => setState(() => day = d),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(15, 16, 15, 14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: context.lineColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PhaseBar(model: widget.model),
                    const SizedBox(height: 10),
                    PhaseTabs(
                      model: widget.model,
                      selected: phase,
                      onSelected: (p) => setState(() => phase = p),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    testShot('homedial $theme', (tester) async {
      await pumpShotScreen(
        tester,
        _Column(model: _typicalModel()),
        dark: dark,
        height: 1900,
      );
      await captureShot(tester, 'homedial-$theme');
    });
  }

  testShot('homedial light 200% text', (tester) async {
    await pumpShotScreen(
      tester,
      _Column(model: _typicalModel()),
      height: 3200,
      textScale: 2,
    );
    await captureShot(tester, 'homedial-light-200');
  });
}
