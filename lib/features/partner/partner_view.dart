import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import '../tracking/domain/cycle_models.dart';
import 'domain/partner_share_code.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Partner dashboard
//
// What the partner sees, built from a PartnerSnapshot and nothing else. The
// owner's live preview and the partner's decoded code both render this one
// widget, so "what you see in the preview" and "what they get" cannot differ.
//
// Fields that were not shared are simply not drawn. There is no "hidden"
// placeholder: a row of greyed-out locks would tell the partner exactly which
// things they are not being told, which is its own disclosure.
// ─────────────────────────────────────────────────────────────────────────────

class PartnerDashboard extends StatelessWidget {
  const PartnerDashboard({
    super.key,
    required this.snapshot,
    this.banner,
    this.today,
  });

  final PartnerSnapshot snapshot;

  /// Shown above everything, e.g. "This is what your partner sees".
  final Widget? banner;

  /// Injected for tests; defaults to now.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final now = today ?? DateTime.now();
    final s = snapshot;
    final name = s.ownerName ?? 'Your partner';
    final phase = s.phase == null ? null : CyclePhase.fromLabel(s.phase);
    final hasAnything = s.phase != null ||
        s.nextPeriod != null ||
        s.fertileStart != null ||
        s.ovulation != null ||
        s.pmsStart != null ||
        s.mood != null ||
        s.symptoms != null ||
        s.painLevel != null ||
        s.supportTip != null ||
        s.note != null;

    final cards = <Widget>[
      if (s.note != null) _NoteCard(name: name, note: s.note!),
      if (s.nextPeriod != null)
        _FactCard(
          icon: AppIcons.period,
          swatch: PhaseColors.of(context).period,
          title: s.daysLate != null ? 'Period is late' : 'Next period',
          value: _nextPeriodLine(s, now),
          detail: 'An estimate from past cycles, not a certainty.',
        ),
      if (s.fertileStart != null && s.fertileEnd != null)
        _FactCard(
          icon: AppIcons.fertile,
          swatch: PhaseColors.of(context).fertile,
          title: 'Fertile window',
          value: '${_d(s.fertileStart!)} – ${_d(s.fertileEnd!)}',
          detail: 'Estimated. Not reliable for contraception.',
        ),
      if (s.ovulation != null)
        _FactCard(
          icon: AppIcons.ovulation,
          swatch: PhaseColors.of(context).ovulation,
          title: 'Estimated ovulation',
          value: _d(s.ovulation!),
        ),
      if (s.pmsStart != null && s.pmsEnd != null)
        _FactCard(
          icon: AppIcons.pms,
          swatch: PhaseColors.of(context).luteal(),
          title: 'PMS window',
          value: '${_d(s.pmsStart!)} – ${_d(s.pmsEnd!)}',
          detail: 'Some people notice mood or energy changes around now.',
        ),
      if (s.mood != null || s.symptoms != null || s.painLevel != null)
        _TodayCard(snapshot: s),
      if (s.supportTip != null)
        _FactCard(
          icon: AppIcons.cuddle,
          swatch: PhaseColors.of(context).phase(phase ?? CyclePhase.follicular),
          title: 'What tends to help',
          value: s.supportTip!,
          valueIsProse: true,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: [
        if (banner != null) ...[banner!, const SizedBox(height: AppSpacing.lg)],
        _Header(name: name, phase: phase, cycleDay: s.cycleDay),
        const SizedBox(height: AppSpacing.lg),
        if (!hasAnything)
          const EmptyState(
            icon: AppIcons.privacy,
            title: 'Nothing shared yet',
            message: 'Switch on at least one thing to share and it will '
                'appear here.',
          )
        else
          for (final card in cards) ...[
            card,
            const SizedBox(height: AppSpacing.md),
          ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Shared ${DateFormat('d MMM, HH:mm').format(s.createdAt)} · '
          'a snapshot, it does not update',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: context.mutedColor),
        ),
      ],
    );
  }

  static String _d(DateTime d) => DateFormat('EEE d MMM').format(d);

  static String _nextPeriodLine(PartnerSnapshot s, DateTime now) {
    if (s.daysLate != null) {
      return 'About ${s.daysLate} ${s.daysLate == 1 ? 'day' : 'days'} '
          'later than expected';
    }
    final days = DateTime(s.nextPeriod!.year, s.nextPeriod!.month,
            s.nextPeriod!.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final when = days <= 0
        ? 'Expected about now'
        : days == 1
            ? 'Expected tomorrow'
            : 'In about $days days';
    return '$when · ${_d(s.nextPeriod!)}';
  }
}

/// The lead surface: whose cycle, which phase, which day. Saturated, because it
/// is the one thing the partner opens this for.
class _Header extends StatelessWidget {
  const _Header({required this.name, this.phase, this.cycleDay});

  final String name;
  final CyclePhase? phase;
  final int? cycleDay;

  @override
  Widget build(BuildContext context) {
    final swatch =
        PhaseColors.of(context).phase(phase ?? CyclePhase.follicular);
    final ink = HeroInk.of(context);
    final text = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: swatch.hero,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: text.labelLarge?.copyWith(color: ink.secondary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                phase == null ? 'Cycle update' : '${phase!.label} phase',
                style: text.headlineMedium?.copyWith(
                  color: ink.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (cycleDay != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text('Cycle day $cycleDay',
                    style: text.bodyMedium?.copyWith(color: ink.secondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.swatch,
    required this.title,
    required this.value,
    this.detail,
    this.valueIsProse = false,
  });

  final IconData icon;
  final PhaseSwatch swatch;
  final String title;
  final String value;
  final String? detail;
  final bool valueIsProse;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      emphasis: CardEmphasis.raised,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: swatch.surface, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: swatch.text),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: text.labelMedium
                        ?.copyWith(color: context.mutedColor)),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: valueIsProse
                      ? text.bodyMedium?.copyWith(color: context.inkColor)
                      : text.titleMedium?.copyWith(
                          color: context.inkColor,
                          fontWeight: FontWeight.w800,
                        ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(detail!,
                      style: text.labelSmall
                          ?.copyWith(color: context.mutedColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A line from the owner, quoted. Placed first because it is the only thing
/// here a person wrote.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.name, required this.note});

  final String name;
  final String note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      emphasis: CardEmphasis.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.format_quote_rounded,
                size: 20, color: context.accentColor),
            const SizedBox(width: AppSpacing.xs),
            Text('From $name',
                style: text.labelMedium?.copyWith(color: context.mutedColor)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text(note,
              style: text.titleMedium?.copyWith(
                color: context.inkColor,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.snapshot});

  final PartnerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = snapshot;
    final rows = <(IconData, String, String)>[
      if (s.mood != null) (AppIcons.moodCalm, 'Mood', s.mood!),
      if (s.symptoms != null)
        (AppIcons.symptoms, 'Symptoms', s.symptoms!.join(', ')),
      if (s.painLevel != null)
        (AppIcons.pain, 'Pain', '${s.painLevel} out of 10'),
    ];

    return AppCard(
      emphasis: CardEmphasis.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Today',
              style: text.labelMedium?.copyWith(color: context.mutedColor)),
          const SizedBox(height: AppSpacing.sm),
          for (final (icon, label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(children: [
                Icon(icon, size: 20, color: context.accentColor),
                const SizedBox(width: AppSpacing.md),
                Text(label,
                    style: text.bodyMedium?.copyWith(color: context.mutedColor)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(value,
                      textAlign: TextAlign.end,
                      style: text.bodyMedium?.copyWith(
                        color: context.inkColor,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
