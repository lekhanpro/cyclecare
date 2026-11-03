part of 'home_screen.dart';

// ─── Cycle map card ──────────────────────────────────────────────────────────

/// "Your cycle at a glance": SLOT C (phase bar + tabs), the fertile/PMS
/// legend and the selected phase's detail panel.
class _CycleMapCard extends StatefulWidget {
  const _CycleMapCard({required this.model, required this.phaseBar});

  final CyclePhaseModel model;
  final Widget Function(CyclePhase selected, ValueChanged<CyclePhase> onSelected)
      phaseBar;

  @override
  State<_CycleMapCard> createState() => _CycleMapCardState();
}

class _CycleMapCardState extends State<_CycleMapCard> {
  late CyclePhase _selected = widget.model.currentPhase;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final motion = Motion.of(context);
    final phases = PhaseColors.of(context);
    final segment =
        model.segments.firstWhere((s) => s.phase == _selected);

    return _HomeCard(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'Your cycle at a glance',
            trailing: Text(
              '${model.cycleLength}-day estimate',
              style: _caption(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          widget.phaseBar(_selected, (p) => setState(() => _selected = p)),
          if (model.overlays.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                for (final overlay in model.overlays)
                  _LegendEntry(
                    label: overlay.kind.label,
                    range: overlay.dateRangeLabel,
                    color: overlay.kind == CycleOverlayKind.fertile
                        ? phases.fertile.band
                        : phases.pms.band,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // The panel crossfades in place; its height animates so the page
          // never jumps under the finger.
          AnimatedSize(
            duration: motion(AppDurations.normal),
            curve: AppCurves.out,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: motion(AppDurations.fast),
              switchInCurve: AppCurves.out,
              switchOutCurve: AppCurves.out,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              child: KeyedSubtree(
                key: ValueKey(_selected),
                child: _PhaseDetail(model: model, segment: segment),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.label,
    required this.range,
    required this.color,
  });

  final String label;
  final String range;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, estimated $range',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs + 1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(label, style: _caption(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseDetail extends StatelessWidget {
  const _PhaseDetail({required this.model, required this.segment});

  final CyclePhaseModel model;
  final CyclePhaseSegment segment;

  @override
  Widget build(BuildContext context) {
    final swatch = PhaseColors.of(context).phase(segment.phase);
    final tip = PhaseGuidance.tipFor(segment.phase, day: model.cycleDay);
    final pms = model.pms;
    final pmsNote = segment.phase == CyclePhase.luteal &&
            pms != null &&
            pms.start.isAfter(model.today)
        ? ' Your estimated PMS window starts '
            '${DateFormat('MMMM d').format(pms.start)}.'
        : '';
    final ovulationLabel = segment.phase == CyclePhase.ovulation
        ? 'Estimated ovulation'
        : segment.phase.label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.canvasColor,
        borderRadius: BorderRadius.circular(AppRadii.calendarDay),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(_phaseIcon(segment.phase),
                    size: 14, color: swatch.text),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  ovulationLabel,
                  style: AppTextStyles.body(
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ).copyWith(color: swatch.text),
                ),
              ),
              Text(segment.dateRangeLabel, style: _caption(context)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tip.title,
            style: AppTextStyles.heading(fontSize: 18, letterSpacing: -0.3)
                .copyWith(color: context.inkColor),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text('${tip.body}$pmsNote', style: _small(context)),
        ],
      ),
    );
  }
}

// ─── Check-in ────────────────────────────────────────────────────────────────

class _CheckInCard extends ConsumerWidget {
  const _CheckInCard({required this.data, required this.today});

  final CycleTrackerState data;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sage = PhaseColors.of(context).follicular;
    final done = data.logFor(today) != null;
    final title = done ? 'Checked in for today.' : 'A moment for you, today.';
    final subtitle = done
        ? 'Saved on this phone. Add or change anything, any time.'
        : 'Mood, symptoms and the little details.';
    final action = done ? 'Edit' : 'Check in';

    return Pressable(
      onTap: () {
        ref.read(cycleTrackerControllerProvider.notifier).selectDate(today);
        context.go(AppRoutes.log);
      },
      semanticLabel: '$title $subtitle',
      semanticHint: done ? 'Edit today’s check-in' : 'Open today’s log',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        key: ValueKey('home-checkin-${done ? 'done' : 'open'}'),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
        decoration: BoxDecoration(
          color: sage.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.cardColor.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppRadii.compact + 2),
              ),
              child: Icon(done ? AppIcons.check : AppIcons.notes,
                  size: 19, color: sage.text),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _strong(context)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.body(fontSize: 11, height: 1.35)
                        .copyWith(color: sage.text),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              action,
              style: AppTextStyles.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ).copyWith(color: sage.text),
            ),
            Icon(AppIcons.forward, size: 14, color: sage.text),
          ],
        ),
      ),
    );
  }
}

// ─── Every phase. Every window. ──────────────────────────────────────────────

/// One row in the all-windows list.
class _WindowRowData {
  const _WindowRowData({
    required this.name,
    required this.start,
    required this.end,
    required this.swatch,
    required this.icon,
    required this.state,
    required this.isCurrent,
    required this.detail,
  });

  final String name;
  final DateTime start;
  final DateTime end;
  final PhaseSwatch swatch;
  final IconData icon;
  final String state;
  final bool isCurrent;
  final String detail;
}

/// The right-aligned state for a range relative to [today].
String _estimateState(DateTime start, DateTime end, DateTime today) {
  if (end.isBefore(today)) return 'Estimated · passed';
  if (!start.isAfter(today)) return 'Estimated · now';
  final days = start.difference(today).inDays;
  if (days == 1) return 'Estimated · starts tomorrow';
  return 'Estimated · in about $days days';
}

List<_WindowRowData> _windowRows(
  BuildContext context,
  CycleTrackerState data,
  CyclePrediction prediction,
  CyclePhaseModel model,
) {
  final phases = PhaseColors.of(context);
  final today = model.today;
  final rows = <_WindowRowData>[];

  _WindowRowData phaseRow(CyclePhaseSegment s, String name, String detail) {
    // Past the estimate, "you're here" would claim a phase the model cannot
    // place, so no row is marked current.
    final current = s.phase == model.currentPhase && !prediction.isLate;
    var state = _estimateState(s.start, s.end, today);
    if (s.phase == CyclePhase.menstrual && data.periodFor(s.start) != null) {
      state = 'Recorded';
    }
    return _WindowRowData(
      name: name,
      start: s.start,
      end: s.end,
      swatch: s.phase == CyclePhase.menstrual
          ? phases.period
          : phases.phase(s.phase),
      icon: _phaseIcon(s.phase),
      state: current ? 'You’re here' : state,
      isCurrent: current,
      detail: detail,
    );
  }

  _WindowRowData overlayRow(CycleOverlay o, String detail) => _WindowRowData(
        name: o.kind.label,
        start: o.start,
        end: o.end,
        swatch: o.kind == CycleOverlayKind.fertile ? phases.fertile : phases.pms,
        icon: o.kind == CycleOverlayKind.fertile ? AppIcons.fertile : AppIcons.pms,
        state: _estimateState(o.start, o.end, today),
        isCurrent: false,
        detail: detail,
      );

  final seg = model.segments;
  rows.add(phaseRow(seg[0], 'Menstrual',
      'Your period. Days you log here are recorded; the rest are estimated.'));
  rows.add(phaseRow(seg[1], 'Follicular',
      'The days between your period and estimated ovulation.'));
  final fertile = model.fertile;
  if (fertile != null) {
    rows.add(overlayRow(
      fertile,
      'An estimate of the days pregnancy is more likely. It overlaps the '
      'phases and is not reliable as contraception.',
    ));
  }
  if (model.showsOvulation) {
    rows.add(phaseRow(seg[2], 'Ovulation',
        'Estimated from your cycle length and luteal phase. It is not a '
        'measurement.'));
  }
  rows.add(phaseRow(seg[3], 'Luteal',
      'From the day after estimated ovulation to your next period.'));
  final pms = model.pms;
  if (pms != null) {
    rows.add(overlayRow(
      pms,
      'The days before your next period when some people notice changes. '
      'Everyone’s experience is different.',
    ));
  }

  final nextStart = dateOnly(prediction.nextPeriodStart);
  final nextEnd = dateOnly(prediction.nextPeriodEnd);
  final String nextState;
  if (prediction.isLate) {
    nextState = 'Estimate passed · not logged yet';
  } else {
    final days = nextStart.difference(today).inDays;
    nextState = days <= 0
        ? 'Estimated · today'
        : days == 1
            ? 'Estimated · tomorrow'
            : 'Estimated · in about $days days';
  }
  rows.add(_WindowRowData(
    name: 'Next period',
    start: nextStart,
    end: nextEnd,
    swatch: phases.predicted,
    icon: AppIcons.calendar,
    state: nextState,
    isCurrent: false,
    detail: 'An estimate from your recent cycles. It moves as you log.',
  ));
  return rows;
}

class _AllWindowsCard extends StatelessWidget {
  const _AllWindowsCard({
    required this.data,
    required this.prediction,
    required this.model,
  });

  final CycleTrackerState data;
  final CyclePrediction prediction;
  final CyclePhaseModel model;

  @override
  Widget build(BuildContext context) {
    final rows = _windowRows(context, data, prediction, model);
    return _HomeCard(
      padding: const EdgeInsets.fromLTRB(15, 17, 15, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'Every phase. Every window.',
            trailing: ExcludeSemantics(
              child: Icon(AppIcons.calendarRange,
                  size: 17, color: context.mutedColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            'Your current cycle · '
            '${_longRange(model.cycleStart, model.cycleEnd)}',
            style: _caption(context),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows)
            _WindowRow(key: ValueKey('home-window-${row.name}'), row: row),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fertile and PMS windows overlap the phases above. All future '
            'dates and ovulation dates are estimates.',
            style: _caption(context),
          ),
        ],
      ),
    );
  }
}

class _WindowRow extends StatelessWidget {
  const _WindowRow({super.key, required this.row});

  final _WindowRowData row;

  @override
  Widget build(BuildContext context) {
    final range = _shortRange(row.start, row.end);
    final stateWidget = row.isCurrent
        ? ListRowBadge(
            label: row.state,
            color: row.swatch.text,
            background: row.swatch.surface,
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: Text(
              row.state,
              textAlign: TextAlign.right,
              style: _caption(context),
            ),
          );

    return ListRow(
      title: row.name,
      subtitle: range,
      icon: row.icon,
      iconColor: row.swatch.text,
      iconBackground: row.swatch.surface,
      trailing: stateWidget,
      showChevron: true,
      semanticLabel:
          '${row.name}, ${_longRange(row.start, row.end)}, ${row.state}',
      onTap: () => showAppSheet<void>(
        context: context,
        title: row.name,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_longRange(row.start, row.end)} · ${row.state}',
                style: _strong(context, size: 14),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                row.detail,
                style: AppTextStyles.body(fontSize: 14)
                    .copyWith(color: context.inkColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Care note ───────────────────────────────────────────────────────────────

class _CareNote extends StatelessWidget {
  const _CareNote({required this.phase, required this.cycleDay});

  final CyclePhase phase;
  final int cycleDay;

  @override
  Widget build(BuildContext context) {
    // Offset by one so the note does not repeat the detail panel's tip.
    final tip = PhaseGuidance.tipFor(phase, day: cycleDay + 1);
    final surface = context.isDark ? AppColors.darkPeach : AppColors.peach;
    final link = context.accent.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cardColor.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: ExcludeSemantics(
              child: Icon(tip.icon, size: 20, color: link),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A LITTLE EXTRA CARE',
                  style:
                      AppTextStyles.overline.copyWith(color: context.mutedColor),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  tip.title,
                  style: AppTextStyles.heading(fontSize: 23, letterSpacing: -0.5)
                      .copyWith(color: context.inkColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(tip.body, style: _small(context)),
                Pressable(
                  onTap: () => context.push(AppRoutes.education),
                  semanticLabel:
                      'Read about your ${phase.label.toLowerCase()} phase',
                  excludeChildSemantics: true,
                  minimumSize: const Size(0, AppLayout.minTouchTarget),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Read about your ${phase.label.toLowerCase()} phase',
                          style: AppTextStyles.body(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ).copyWith(color: link),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(AppIcons.forward, size: 15, color: link),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming ────────────────────────────────────────────────────────────────

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.forecasts, required this.today});

  final List<CycleForecast> forecasts;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final rose = PhaseColors.of(context).predicted;
    final shown = forecasts.take(3).toList();

    return _HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Next period estimates',
                    style: _strong(context).copyWith(
                      fontWeight: FontWeight.w700,
                    )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: context.canvasColor,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.info, size: 12, color: context.mutedColor),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Dates may shift', style: _caption(context)),
                  ],
                ),
              ),
            ],
          ),
          for (var i = 0; i < shown.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.lineColor)),
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var d = 0; d < 5; d++) ...[
                          if (d > 0) const SizedBox(width: 3),
                          CustomPaint(
                            size: const Size(6, 16),
                            painter: _DashedPillPainter(
                              fill: rose.surface.withValues(alpha: 0.6),
                              stroke: rose.fill,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shortRange(shown[i].periodStart, shown[i].periodEnd),
                          style: _strong(context),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(_distance(i, shown[i]), style: _caption(context)),
                      ],
                    ),
                  ),
                  if (i == 0)
                    ListRowBadge(
                      label: 'Up next',
                      color: rose.text,
                      background: rose.surface,
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text('Further-away estimates have more uncertainty.',
              style: _caption(context)),
        ],
      ),
    );
  }

  String _distance(int i, CycleForecast f) {
    if (i == 1) return 'Next cycle';
    if (i >= 2) return 'Following cycle';
    final days = dateOnly(f.periodStart).difference(today).inDays;
    if (days <= 0) return 'Expected around now';
    if (days == 1) return 'About a day away';
    return 'About $days days away';
  }
}

/// A rounded pill with a dashed outline: the design's mark for a forecast
/// day, so predicted reads differently from recorded without relying on hue.
class _DashedPillPainter extends CustomPainter {
  _DashedPillPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(5),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    final path = Path()..addRRect(rrect.deflate(0.5));
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 2).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 4;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

// ─── Your space ──────────────────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);
    final peach = context.isDark ? AppColors.darkPeach : AppColors.peach;
    final peachInk = AppContrast.readable(
      context.accent.text,
      surface: peach,
      isDark: context.isDark,
    );
    final items = <({
      IconData icon,
      String title,
      String subtitle,
      String route,
      Color bg,
      Color fg,
    })>[
      (
        icon: AppIcons.article,
        title: 'Learn',
        subtitle: 'Small reads, clear answers',
        route: AppRoutes.education,
        bg: peach,
        fg: peachInk,
      ),
      (
        icon: AppIcons.conditions,
        title: 'Your health',
        subtitle: 'Support for your body',
        route: AppRoutes.health,
        bg: phases.follicular.surface,
        fg: phases.follicular.text,
      ),
      (
        icon: AppIcons.reminders,
        title: 'Reminders',
        subtitle: 'Gentle, discreet nudges',
        route: AppRoutes.reminders,
        bg: phases.ovulation.surface,
        fg: phases.ovulation.text,
      ),
      (
        icon: AppIcons.pill,
        title: 'Birth control',
        subtitle: 'Your daily rhythm',
        route: AppRoutes.birthControl,
        bg: phases.period.surface,
        fg: phases.period.text,
      ),
      (
        icon: AppIcons.partnerPair,
        title: 'Partner sharing',
        subtitle: 'Support on your terms',
        route: AppRoutes.partner,
        bg: phases.luteal().surface,
        fg: phases.luteal().text,
      ),
      (
        icon: AppIcons.pregnancy,
        title: 'Pregnancy',
        subtitle: 'One week at a time',
        route: AppRoutes.pregnancy,
        bg: peach,
        fg: peachInk,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      const gap = 10.0;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final twoUp = constraints.maxWidth >= 300 && scale < 1.6;
      final width =
          twoUp ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: Pressable(
                onTap: () => context.push(item.route),
                semanticLabel: item.title,
                semanticHint: item.subtitle,
                excludeChildSemantics: true,
                borderRadius: BorderRadius.circular(19),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 125),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: context.lineColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: item.bg,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.compact),
                            ),
                            child: Icon(item.icon, size: 18, color: item.fg),
                          ),
                          const Spacer(),
                          Icon(AppIcons.forward,
                              size: 13, color: context.mutedColor),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(item.title, style: _strong(context)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.subtitle, style: _caption(context)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ─── Companion ───────────────────────────────────────────────────────────────

String _petAsset(PetType type) => switch (type) {
      PetType.bunny => 'assets/pets/luna-bunny.png',
      PetType.cat => 'assets/pets/miso-cat.png',
      PetType.bear => 'assets/pets/maple-bear.png',
      PetType.fox => 'assets/pets/pip-fox.png',
    };

/// The companion, apart from the cycle content. Still by default and under
/// reduced motion; Play is an explicit opt-in to a slow breathing scale.
class _CompanionSection extends ConsumerStatefulWidget {
  const _CompanionSection();

  @override
  ConsumerState<_CompanionSection> createState() => _CompanionSectionState();
}

class _CompanionSectionState extends ConsumerState<_CompanionSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _playing = false;

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _breath.repeat(reverse: true);
    } else {
      _breath.animateTo(0, duration: Motion.of(context)(AppDurations.fast));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProvider).valueOrNull ?? const PetState();
    final sage = PhaseColors.of(context).follicular;
    final accent = context.accent;

    return Semantics(
      container: true,
      label: 'Your companion',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: sage.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: 1.04).animate(
                  CurvedAnimation(parent: _breath, curve: Curves.easeInOut),
                ),
                child: Image.asset(
                  _petAsset(pet.type),
                  width: 58,
                  height: 68,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => SizedBox(
                    width: 58,
                    height: 68,
                    child: Icon(pet.type.icon, size: 40, color: sage.text),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A little company.', style: _strong(context)),
                  Pressable(
                    onTap: () => context.go(AppRoutes.pet),
                    semanticLabel: 'Visit ${pet.name}',
                    excludeChildSemantics: true,
                    minimumSize: const Size(0, AppLayout.minTouchTarget),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Visit ${pet.name}',
                            style: AppTextStyles.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ).copyWith(color: sage.text),
                          ),
                        ),
                        Icon(AppIcons.forward, size: 12, color: sage.text),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Pressable(
              onTap: _toggle,
              selected: _playing,
              semanticLabel: _playing
                  ? 'Pause companion animation'
                  : 'Play companion animation',
              excludeChildSemantics: true,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Container(
                key: const ValueKey('home-companion-motion'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.cardColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  _playing ? 'Pause motion' : 'Play motion',
                  style: AppTextStyles.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ).copyWith(color: accent.text),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Icon(AppIcons.privacy, size: 12, color: context.mutedColor),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'Just for you. Stored on your phone.',
            textAlign: TextAlign.center,
            style: _caption(context),
          ),
        ),
      ],
    );
  }
}

// ─── Alerts ──────────────────────────────────────────────────────────────────

/// Flags an unusually long gap since the last recorded period. Nothing before
/// 46 days, and it never names a condition.
AmenorrheaResult? _longGap(List<CycleEvent> periods, DateTime today) {
  if (periods.isEmpty) return null;
  final latest = periods
      .map((p) => dateOnly(p.startDate))
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final daysSince = today.difference(latest).inDays;
  if (daysSince <= 45) return null;
  final severity = daysSince >= 180
      ? AmenorrheaSeverity.severe
      : daysSince >= 90
          ? AmenorrheaSeverity.moderate
          : AmenorrheaSeverity.mild;
  return AmenorrheaResult(
    severity: severity,
    daysSinceLastPeriod: daysSince,
    lastPeriodDate: latest,
    description:
        '$daysSince days since your last logged period. ${severity.description}.',
    recommendations: const [
      'Check whether any periods are missing from your log',
      'Note recent changes in stress, weight, travel, or medication',
      'Consider talking to a healthcare provider',
    ],
  );
}

/// The late-period check-in, per the late reference: gentle, one action.
class _LateAlert extends ConsumerWidget {
  const _LateAlert({required this.prediction, required this.today});

  final CyclePrediction prediction;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peach = context.isDark ? AppColors.darkPeach : AppColors.peach;
    final days = prediction.daysLate;
    final shortest = prediction.shortestCycle;
    final longest = prediction.longestCycle;
    final rangeCopy = shortest != null && longest != null
        ? 'Your last cycles ranged from $shortest to $longest days. '
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('home-late-alert'),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: peach,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.help, size: 13, color: context.inkColor),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      'A gentle check-in',
                      style: AppTextStyles.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ).copyWith(color: context.inkColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg + 2),
              Semantics(
                header: true,
                child: Text(
                  'Your period hasn’t been logged yet.',
                  style: AppTextStyles.heading(
                    fontSize: 29,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ).copyWith(color: context.inkColor),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'It’s about $days ${days == 1 ? 'day' : 'days'} past your '
                'estimate. Cycles can shift. If it has started, you can add it '
                'now.',
                style: _small(context),
              ),
              const SizedBox(height: AppSpacing.xl + 2),
              PrimaryButton(
                label: 'Log my period',
                icon: AppIcons.period,
                onPressed: () async {
                  await ref
                      .read(cycleTrackerControllerProvider.notifier)
                      .logPeriodStart(today);
                  if (!context.mounted) return;
                  showAppToast(context, message: 'Period logged for today');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ConfidenceNote(
          title: 'An estimate, not a deadline.',
          text: '${rangeCopy}Logging helps update future estimates. If it '
              'stays off or something feels wrong, a clinician is the right '
              'next step.',
        ),
      ],
    );
  }
}

/// A long gap since the last logged period: an observation with next steps.
class _GapAlert extends ConsumerWidget {
  const _GapAlert({required this.result, required this.today});

  final AmenorrheaResult result;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severe = result.severity == AmenorrheaSeverity.severe;
    final tone = severe
        ? AccentRoles.dangerText(Theme.of(context).brightness)
        : context.accent.text;

    return _HomeCard(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      child: Column(
        key: const ValueKey('home-gap-alert'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.warning, size: 18, color: tone),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(result.severity.displayName,
                    style: _strong(context, size: 14).copyWith(color: tone)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(result.description, style: _small(context)),
          const SizedBox(height: AppSpacing.sm),
          for (final step in result.recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('•  $step', style: _small(context)),
            ),
          Text(
            'This is an observation from your logs, not a diagnosis.',
            style: _caption(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: () => context.go(AppRoutes.calendar),
                child: const Text('Review your cycle history'),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(cycleTrackerControllerProvider.notifier)
                      .logPeriodStart(today);
                  if (!context.mounted) return;
                  showAppToast(context, message: 'Period logged for today');
                },
                child: const Text('Log a period'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
