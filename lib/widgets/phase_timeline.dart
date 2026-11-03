import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_icons.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/phase_colors.dart';
import '../features/tracking/domain/cycle_models.dart';
import '../features/tracking/domain/cycle_windows.dart';
import 'app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phase timeline
//
// The whole current cycle in one card: a bar across every cycle day, then each
// window listed with its dates and how far away it is.
//
// The windows overlap (the fertile window contains ovulation, the PMS window
// sits inside the luteal phase), so the bar is drawn in layers rather than as
// one row of segments. The main track carries the four phases; ovulation is a
// ring on top of it and PMS is a thin strip underneath. Drawing them all in
// one track would make the later window hide the earlier one.
// ─────────────────────────────────────────────────────────────────────────────

/// Swatch and icon for each window, shared by the bar and the list so the two
/// always agree.
({PhaseSwatch swatch, IconData icon}) windowStyle(
  PhaseColors phases,
  CycleWindowKind kind,
) {
  return switch (kind) {
    CycleWindowKind.period => (swatch: phases.period, icon: AppIcons.period),
    CycleWindowKind.follicular => (
        swatch: phases.phase(CyclePhase.follicular),
        icon: AppIcons.basics,
      ),
    CycleWindowKind.fertile => (swatch: phases.fertile, icon: AppIcons.fertile),
    CycleWindowKind.ovulation => (
        swatch: phases.ovulation,
        icon: AppIcons.ovulation,
      ),
    CycleWindowKind.luteal => (swatch: phases.luteal(), icon: AppIcons.luteal),
    CycleWindowKind.pms => (swatch: phases.luteal(), icon: AppIcons.pms),
    CycleWindowKind.nextPeriod => (
        swatch: phases.predicted,
        icon: AppIcons.calendar,
      ),
  };
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.windows,
    required this.phases,
    required this.today,
    required this.markerColor,
    required this.trackColor,
  });

  final CycleWindows windows;
  final PhaseColors phases;
  final DateTime today;
  final Color markerColor;
  final Color trackColor;

  static const _trackHeight = 14.0;
  static const _pmsHeight = 4.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final days = windows.cycleLength;
    double x(DateTime d) =>
        (windows.cycleDayOf(d) - 1) / days * size.width;
    double xEnd(DateTime d) => windows.cycleDayOf(d) / days * size.width;

    final top = size.height - _trackHeight - _gap - _pmsHeight;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, top, size.width, _trackHeight),
      const Radius.circular(_trackHeight / 2),
    );

    canvas.save();
    canvas.clipRRect(track);
    canvas.drawRRect(track, Paint()..color = trackColor);
    // Fertile last, so its one-day overlap with luteal shows as fertile.
    for (final kind in const [
      CycleWindowKind.period,
      CycleWindowKind.follicular,
      CycleWindowKind.luteal,
      CycleWindowKind.fertile,
    ]) {
      final w = windows.of(kind);
      if (w == null) continue;
      canvas.drawRect(
        Rect.fromLTRB(x(w.start), top, xEnd(w.end), top + _trackHeight),
        Paint()..color = windowStyle(phases, kind).swatch.fill,
      );
    }
    canvas.restore();

    final pms = windows.of(CycleWindowKind.pms);
    if (pms != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x(pms.start), top + _trackHeight + _gap,
              xEnd(pms.end), top + _trackHeight + _gap + _pmsHeight),
          const Radius.circular(_pmsHeight / 2),
        ),
        Paint()..color = windowStyle(phases, CycleWindowKind.pms).swatch.fill,
      );
    }

    final ovulation = windows.of(CycleWindowKind.ovulation);
    if (ovulation != null) {
      final center = Offset(
        (x(ovulation.start) + xEnd(ovulation.start)) / 2,
        top + _trackHeight / 2,
      );
      canvas.drawCircle(center, _trackHeight * 0.62, Paint()..color = trackColor);
      canvas.drawCircle(center, _trackHeight * 0.44,
          Paint()..color = phases.ovulation.fill);
    }

    // Today: a pin above the track, so it never hides a window's colour.
    final tx = (x(today) + xEnd(today)) / 2;
    final pin = Paint()..color = markerColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tx - 1.25, top - 6, 2.5, _trackHeight + 12),
        const Radius.circular(1.25),
      ),
      pin,
    );
    canvas.drawCircle(Offset(tx, top - 8), 4.5, pin);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.windows != windows ||
      old.today != today ||
      old.markerColor != markerColor ||
      old.trackColor != trackColor ||
      old.phases.brightness != phases.brightness;
}

/// The current cycle's windows: a bar across every day, then a dated list.
class PhaseTimeline extends StatelessWidget {
  const PhaseTimeline({super.key, required this.windows, this.today});

  final CycleWindows windows;

  /// Injected for tests; defaults to now.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);
    final now = today ?? DateTime.now();
    final text = Theme.of(context).textTheme;
    final day = windows.cycleDayOf(now);

    return AppCard(
      emphasis: CardEmphasis.raised,
      padding: AppInsets.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Cycle bar. Today is cycle day $day of '
                '${windows.cycleLength}.',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 40,
                child: CustomPaint(
                  painter: _BarPainter(
                    windows: windows,
                    phases: phases,
                    today: now,
                    markerColor: context.inkColor,
                    trackColor: context.lineColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ExcludeSemantics(
            // "Today" sits under the marker rather than centred, so the label
            // and the pin always point at the same day. Day 1 and the last day
            // stay at the ends as the scale; near either end the today label
            // replaces them instead of colliding.
            child: SizedBox(
              height: 18,
              child: Stack(
                children: [
                  if (day > 6)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Day 1',
                          style: text.labelSmall
                              ?.copyWith(color: context.mutedColor)),
                    ),
                  if (day < windows.cycleLength - 5)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Day ${windows.cycleLength}',
                          style: text.labelSmall
                              ?.copyWith(color: context.mutedColor)),
                    ),
                  Align(
                    alignment: Alignment(
                      ((day - 0.5) / windows.cycleLength) * 2 - 1,
                      0,
                    ),
                    child: Text('Today · day $day',
                        maxLines: 1,
                        style: text.labelSmall?.copyWith(
                          color: context.inkColor,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < windows.windows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: context.lineColor),
            _WindowRow(window: windows.windows[i], today: now),
          ],
        ],
      ),
    );
  }
}

class _WindowRow extends StatelessWidget {
  const _WindowRow({required this.window, required this.today});

  final CycleWindow window;
  final DateTime today;

  String _dates() {
    final f = DateFormat('d MMM');
    return window.lengthInDays == 1
        ? f.format(window.start)
        : '${f.format(window.start)} – ${f.format(window.end)}';
  }

  /// Hedged on purpose: every one of these dates is an estimate.
  String _status() {
    switch (window.timingOn(today)) {
      case WindowTiming.past:
        return 'Ended';
      case WindowTiming.now:
        return 'Now';
      case WindowTiming.upcoming:
        final n = window.daysUntil(today);
        return n == 1 ? 'Tomorrow' : 'In about $n days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = windowStyle(PhaseColors.of(context), window.kind);
    final timing = window.timingOn(today);
    final text = Theme.of(context).textTheme;
    final active = timing == WindowTiming.now;
    final faded = timing == WindowTiming.past;

    return Semantics(
      container: true,
      label: '${window.kind.label}, ${_dates()}, ${_status()}',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: faded ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            // On a narrow phone at large text the chip ("In about 26 days")
            // left too little room for the label, so below 300dp it moves
            // under the dates instead of being shrunk or clipped.
            child: LayoutBuilder(builder: (context, constraints) {
              final stacked = constraints.maxWidth < 300;
              final chip = _StatusChip(
                  label: _status(), active: active, swatch: style.swatch);
              return Row(
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: style.swatch.surface,
                    shape: BoxShape.circle,
                    border: active
                        ? Border.all(color: style.swatch.fill, width: 2)
                        : null,
                  ),
                  child: Icon(style.icon, size: 18, color: style.swatch.text),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(window.kind.label,
                          style: text.titleSmall
                              ?.copyWith(color: context.inkColor)),
                      Text(_dates(),
                          style: text.bodySmall
                              ?.copyWith(color: context.mutedColor)),
                      if (stacked) ...[
                        const SizedBox(height: AppSpacing.xs),
                        chip,
                      ],
                    ],
                  ),
                ),
                if (!stacked) chip,
              ],
            );
            }),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.active,
    required this.swatch,
  });

  final String label;
  final bool active;
  final PhaseSwatch swatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: active ? swatch.fill : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: active ? null : Border.all(color: context.lineColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: active ? swatch.onFill : context.mutedColor,
            ),
      ),
    );
  }
}
