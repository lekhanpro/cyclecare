import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'application/birth_control_controller.dart';
import 'domain/birth_control_method.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Birth control
//
// Four jobs, in the order the user cares about them:
//
//  1. Did I take it today? One tap, one unmistakable state.
//  2. Where am I in the pack? A 28-cell grid beats a sentence, because the
//     question is spatial — people picture the blister pack, not a date.
//  3. Have I been missing days? A streak number alone can't answer that, so
//     the history list and the adherence tiles do.
//  4. What is this method, again? Descriptive copy, no advice.
//
// The one thing this screen deliberately refuses to do is tell anyone what to
// do about a missed pill. That answer depends on the product, the position in
// the pack, and the person — and being confidently wrong about it has
// consequences a period tracker has no business risking. The missed-pill
// helper points at the leaflet and at a pharmacist, and stops.
// ─────────────────────────────────────────────────────────────────────────────

class BirthControlScreen extends ConsumerWidget {
  const BirthControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bcAsync = ref.watch(birthControlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birth control'),
        actions: [
          IconButton(
            tooltip: 'About this screen',
            onPressed: () => _showAboutSheet(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: bcAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not open birth control',
          message: '$error',
        ),
        data: (bc) => _Body(bc: bc),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.bc});

  final BirthControlState bc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = bc.method;
    final checkIns = ref.watch(birthControlCheckInsProvider);
    final stats = ref.watch(birthControlAdherenceProvider);
    final pack = ref.watch(pillPackProvider);

    // The legacy store still owns "current streak" — it has been counting for
    // existing users since before the per-date log existed, and dropping to
    // whatever the new log can prove would read as data loss.
    final currentStreak =
        stats.currentStreak > bc.streak ? stats.currentStreak : bc.streak;
    final longestStreak =
        stats.longestStreak > currentStreak ? stats.longestStreak : currentStreak;

    var index = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      children: [
        Reveal(
          index: index++,
          child: _MethodHero(
            method: method,
            onChange: () => _openMethodPicker(context, ref, method),
          ),
        ),
        const SizedBox(height: 14),

        if (method == BirthControlMethod.none)
          Reveal(
            index: index++,
            child: _NoMethodCard(
              onChoose: () => _openMethodPicker(context, ref, method),
            ),
          ),

        if (method.isDailyPill) ...[
          Reveal(
            index: index++,
            child: _TodayCard(
              bc: bc,
              streak: currentStreak,
              onCheckIn: () => _checkInToday(context, ref),
              onUndo: () => _undoToday(context, ref),
              onMissed: () => _showMissedPillSheet(context, ref),
            ),
          ),
          const SizedBox(height: 22),

          SectionHeader(
            title: 'Your pack',
            subtitle: pack.isConfigured
                ? _packSubtitle(pack)
                : 'Tell CycleCare when the current pack started',
            actionLabel: pack.isConfigured ? 'New pack' : null,
            onAction: pack.isConfigured
                ? () => _startNewPack(context, ref, pack)
                : null,
          ),
          Reveal(
            index: index++,
            child: _PackCard(
              settings: pack,
              checkIns: checkIns,
              onLayoutChanged: (layout) =>
                  ref.read(pillPackProvider.notifier).setLayout(layout),
              onPickStart: () => _pickPackStart(context, ref, pack),
              onStartToday: () => ref
                  .read(pillPackProvider.notifier)
                  .setPackStart(DateTime.now()),
              onToggleDay: (date) => _cycleDay(context, ref, date),
            ),
          ),
          const SizedBox(height: 22),
        ],

        SectionHeader(
          title: 'Adherence',
          subtitle: stats.hasData
              ? 'From your own check-ins, last ${stats.windowDays} days'
              : 'Fills in as you check in',
        ),
        Reveal(
          index: index++,
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Current streak',
                  value: '$currentStreak',
                  unit: currentStreak == 1 ? 'day' : 'days',
                  icon: Icons.local_fire_department_rounded,
                  accent: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Longest',
                  value: '$longestStreak',
                  unit: longestStreak == 1 ? 'day' : 'days',
                  icon: Icons.emoji_events_rounded,
                  accent: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Adherence',
                  value: stats.adherencePercent == null
                      ? '—'
                      : '${stats.adherencePercent}',
                  unit: stats.adherencePercent == null ? null : '%',
                  icon: Icons.donut_large_rounded,
                  accent: AppColors.success,
                  caption: stats.hasData
                      ? '${stats.takenInWindow} of ${stats.trackedInWindow} recorded'
                      : 'No records yet',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        SectionHeader(
          title: 'Check-in history',
          subtitle: 'Tap a day to cycle taken, missed, or cleared',
          actionLabel: checkIns.isEmpty ? null : 'Clear',
          onAction: checkIns.isEmpty ? null : () => _clearHistory(context, ref),
        ),
        Reveal(
          index: index++,
          child: _HistoryCard(
            checkIns: checkIns,
            onToggleDay: (date) => _cycleDay(context, ref, date),
          ),
        ),
        const SizedBox(height: 22),

        if (method != BirthControlMethod.none) ...[
          SectionHeader(title: 'About ${method.label.toLowerCase()}'),
          Reveal(index: index++, child: _MethodDetailCard(method: method)),
          const SizedBox(height: 14),
        ],

        Reveal(
          index: index++,
          child: ActionTile(
            icon: Icons.help_outline_rounded,
            emoji: '❓',
            title: 'Missed a pill or a dose?',
            subtitle: 'Where to get an answer for your product',
            onTap: () => _showMissedPillSheet(context, ref),
          ),
        ),
        const SizedBox(height: 14),

        Reveal(
          index: index++,
          child: InfoBanner(
            icon: Icons.health_and_safety_rounded,
            title: 'Educational information only',
            message:
                'CycleCare tracks what you record and describes methods in general '
                'terms. It does not give medical advice, and nothing here replaces '
                'the leaflet supplied with your medication or a conversation with a '
                'pharmacist or clinician.',
            actionLabel: 'What this screen will not do',
            onAction: () => _showAboutSheet(context),
          ),
        ),
      ],
    );
  }

  String _packSubtitle(PillPackSettings pack) {
    final position = pack.dayOfPack(DateTime.now());
    final number = pack.packNumber(DateTime.now());
    if (position == null || number == null) {
      return 'Starts ${_shortDate(pack.packStart!)}';
    }
    final kind = pack.isBreakDay(position) ? 'break day' : 'active day';
    return 'Day $position of ${pack.layout.totalDays} · pack $number · $kind';
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _checkInToday(BuildContext context, WidgetRef ref) async {
    // Both stores are written: the legacy streak keeps its meaning, and the
    // per-date log gains the row that history and adherence read from.
    await ref.read(birthControlProvider.notifier).checkIn();
    await ref
        .read(birthControlCheckInsProvider.notifier)
        .markTaken(DateTime.now());
    if (!context.mounted) return;
    showAppToast(context, message: 'Checked in for today');
  }

  Future<void> _undoToday(BuildContext context, WidgetRef ref) async {
    await ref.read(birthControlProvider.notifier).undoTodayCheckIn();
    await ref
        .read(birthControlCheckInsProvider.notifier)
        .setStatus(DateTime.now(), CheckInStatus.unrecorded);
    if (!context.mounted) return;
    showAppToast(
      context,
      message: "Today's check-in removed",
      kind: ToastKind.info,
    );
  }

  Future<void> _cycleDay(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    if (bcDateOnly(date).isAfter(bcDateOnly(DateTime.now()))) {
      showAppToast(
        context,
        message: 'That day has not happened yet',
        kind: ToastKind.info,
      );
      return;
    }

    // Fired here rather than on the cell so a rejected future day stays silent
    // — the haptic confirms a state change, not that a finger landed.
    Haptics.selection();

    final status =
        await ref.read(birthControlCheckInsProvider.notifier).cycleStatus(date);

    // Cycling *today* has to stay in step with the legacy streak store, or the
    // hero card and the grid would disagree about the same day.
    final isToday = bcDateOnly(date) == bcDateOnly(DateTime.now());
    if (isToday) {
      final legacy = ref.read(birthControlProvider.notifier);
      if (status == CheckInStatus.taken) {
        await legacy.checkIn();
      } else {
        await legacy.undoTodayCheckIn();
      }
    }
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Clear check-in history?',
      message:
          'Every recorded day is removed from this device. Your method and pack '
          'settings are kept.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) return;
    await ref.read(birthControlCheckInsProvider.notifier).clearAll();
    if (!context.mounted) return;
    showAppToast(context, message: 'History cleared', kind: ToastKind.info);
  }

  Future<void> _pickPackStart(
    BuildContext context,
    WidgetRef ref,
    PillPackSettings pack,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: pack.packStart ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 3)),
      lastDate: now,
      helpText: 'First day of your current pack',
    );
    if (picked == null) return;
    await ref.read(pillPackProvider.notifier).setPackStart(picked);
    if (!context.mounted) return;
    showAppToast(context, message: 'Pack start saved');
  }

  Future<void> _startNewPack(
    BuildContext context,
    WidgetRef ref,
    PillPackSettings pack,
  ) async {
    final choice = await showAppSheet<String>(
      context: context,
      title: 'New pack',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Packs after the first one are worked out automatically, so this is '
            'only needed if the rhythm has shifted — a pack started late, or a '
            'switch to a different layout.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: context.mutedColor,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'This pack started today',
            icon: Icons.today_rounded,
            onPressed: () => Navigator.of(context).pop('today'),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Pick a different date',
            icon: Icons.calendar_month_rounded,
            outlined: true,
            onPressed: () => Navigator.of(context).pop('pick'),
          ),
        ],
      ),
    );

    if (choice == 'today') {
      await ref.read(pillPackProvider.notifier).setPackStart(DateTime.now());
      if (!context.mounted) return;
      showAppToast(context, message: 'New pack started today');
    } else if (choice == 'pick' && context.mounted) {
      await _pickPackStart(context, ref, pack);
    }
  }

  Future<void> _openMethodPicker(
    BuildContext context,
    WidgetRef ref,
    BirthControlMethod current,
  ) async {
    final picked = await showAppSheet<BirthControlMethod>(
      context: context,
      title: 'Choose your method',
      child: _MethodPicker(current: current),
    );
    if (picked == null || picked == current) return;

    await ref.read(birthControlProvider.notifier).setMethod(picked);

    // A progestin-only pack has no break week, so the layout that matches it
    // is the continuous one. Set once on switch rather than forced, so anyone
    // on an unusual product can still change it back.
    if (picked == BirthControlMethod.progestinPill) {
      await ref
          .read(pillPackProvider.notifier)
          .setLayout(PillPackLayout.continuous);
    }

    if (!context.mounted) return;
    showAppToast(context, message: 'Method set to ${picked.label}');
  }

  Future<void> _showMissedPillSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final action = await showAppSheet<String>(
      context: context,
      title: 'Missed a pill or a dose?',
      child: const _MissedPillSheet(),
    );
    if (action == null || !context.mounted) return;

    if (action == 'today') {
      await ref
          .read(birthControlCheckInsProvider.notifier)
          .markMissed(DateTime.now());
      if (!context.mounted) return;
      showAppToast(
        context,
        message: 'Today recorded as missed',
        kind: ToastKind.info,
      );
    } else if (action == 'pick') {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now,
        helpText: 'Which day was missed?',
      );
      if (picked == null || !context.mounted) return;
      await ref.read(birthControlCheckInsProvider.notifier).markMissed(picked);
      if (!context.mounted) return;
      showAppToast(
        context,
        message: '${_shortDate(picked)} recorded as missed',
        kind: ToastKind.info,
      );
    }
  }
}

/// Top-level so both the app bar action and the footer banner can open it.
void _showAboutSheet(BuildContext context) {
  showAppSheet<void>(
    context: context,
    title: 'About this screen',
    child: const _AboutSheet(),
  );
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _MethodHero extends StatelessWidget {
  const _MethodHero({required this.method, required this.onChange});

  final BirthControlMethod method;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return AppCard(
      onTap: onChange,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withOpacity(context.isDark ? 0.22 : 0.11),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(method.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR METHOD',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: context.subtleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  method.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: context.inkColor,
                  ),
                ),
                if (method != BirthControlMethod.none) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _Tag(label: method.hormoneTag),
                      const SizedBox(width: 6),
                      _Tag(label: method.cadence),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 18, color: accent),
              const SizedBox(height: 3),
              Text(
                'Change',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: context.lineColor.withOpacity(context.isDark ? 0.7 : 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.mutedColor,
        ),
      ),
    );
  }
}

class _NoMethodCard extends StatelessWidget {
  const _NoMethodCard({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      emphasis: CardEmphasis.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick a method to unlock tracking',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: context.inkColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Daily pills get a check-in, a pack visualiser and an adherence '
            'history. Every other method gets a plain description and nothing '
            'nagging you.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: context.mutedColor,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Choose a method',
            icon: Icons.list_alt_rounded,
            onPressed: onChoose,
          ),
        ],
      ),
    );
  }
}

// ─── Today ───────────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.bc,
    required this.streak,
    required this.onCheckIn,
    required this.onUndo,
    required this.onMissed,
  });

  final BirthControlState bc;
  final int streak;
  final VoidCallback onCheckIn;
  final VoidCallback onUndo;
  final VoidCallback onMissed;

  @override
  Widget build(BuildContext context) {
    final phases = PhaseColors.of(context);
    final taken = bc.takenToday;
    final swatch = taken ? phases.fertile : phases.predicted;

    return PhaseCard(
      swatch: swatch,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: swatch.fill.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: taken
                    ? Icon(
                        Icons.check_rounded,
                        size: 24,
                        color: swatch.text,
                      )
                    : Text(
                        bc.method.emoji,
                        style: const TextStyle(fontSize: 21),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taken ? 'Checked in for today' : 'No check-in yet today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: context.inkColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      taken
                          ? 'Recorded on this device only'
                          : 'Tap below once you have taken it',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedCount(
                value: streak,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1,
                  color: context.inkColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                streak == 1 ? 'day streak' : 'day streak so far',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.mutedColor,
                ),
              ),
              const Spacer(),
              if (streak > 0)
                Text(
                  '🔥',
                  style: TextStyle(
                    fontSize: 20,
                    color: context.inkColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (taken)
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Undo check-in',
                    icon: Icons.undo_rounded,
                    outlined: true,
                    onPressed: onUndo,
                  ),
                ),
              ],
            )
          else
            PrimaryButton(
              label: 'Mark as taken',
              icon: Icons.check_rounded,
              onPressed: onCheckIn,
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Pressable(
              onTap: onMissed,
              scale: 0.96,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'I missed one →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: swatch.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pack visualiser ─────────────────────────────────────────────────────────

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.settings,
    required this.checkIns,
    required this.onLayoutChanged,
    required this.onPickStart,
    required this.onStartToday,
    required this.onToggleDay,
  });

  final PillPackSettings settings;
  final Map<String, bool> checkIns;
  final ValueChanged<PillPackLayout> onLayoutChanged;
  final VoidCallback onPickStart;
  final VoidCallback onStartToday;
  final ValueChanged<DateTime> onToggleDay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedSelector<PillPackLayout>(
            segments: {
              for (final layout in PillPackLayout.values)
                layout: layout.label,
            },
            value: settings.layout,
            onChanged: onLayoutChanged,
          ),
          const SizedBox(height: 8),
          Text(
            settings.layout.description,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: context.mutedColor,
            ),
          ),
          const SizedBox(height: 16),
          if (!settings.isConfigured)
            _PackSetup(onStartToday: onStartToday, onPickStart: onPickStart)
          else
            _PackGrid(
              settings: settings,
              checkIns: checkIns,
              onToggleDay: onToggleDay,
            ),
        ],
      ),
    );
  }
}

class _PackSetup extends StatelessWidget {
  const _PackSetup({required this.onStartToday, required this.onPickStart});

  final VoidCallback onStartToday;
  final VoidCallback onPickStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoBanner(
          icon: Icons.grid_view_rounded,
          message:
              'Set the first day of the pack you are on and CycleCare works out '
              'every pack after it. Nothing is sent anywhere.',
          tone: AppColors.info,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Pack started today',
          icon: Icons.today_rounded,
          onPressed: onStartToday,
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: 'Pick the start date',
          icon: Icons.calendar_month_rounded,
          outlined: true,
          onPressed: onPickStart,
        ),
      ],
    );
  }
}

class _PackGrid extends StatelessWidget {
  const _PackGrid({
    required this.settings,
    required this.checkIns,
    required this.onToggleDay,
  });

  final PillPackSettings settings;
  final Map<String, bool> checkIns;
  final ValueChanged<DateTime> onToggleDay;

  @override
  Widget build(BuildContext context) {
    final today = bcDateOnly(DateTime.now());
    final packStart = settings.packStartFor(today) ?? settings.packStart!;
    final position = settings.dayOfPack(today);
    final total = settings.layout.totalDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_view_week_rounded,
                size: 16, color: context.accentColor),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                position == null
                    ? 'Pack starts ${_shortDate(packStart)}'
                    : 'Day $position of $total · started ${_shortDate(packStart)}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: context.inkColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: 1,
          ),
          itemCount: total,
          itemBuilder: (context, i) {
            final date = packStart.add(Duration(days: i));
            final slot = i + 1;
            return _PackDayCell(
              slot: slot,
              date: date,
              isBreakDay: settings.isBreakDay(slot),
              isToday: date == today,
              isFuture: date.isAfter(today),
              status: _statusFor(date),
              onTap: () => onToggleDay(date),
            );
          },
        ),
        const SizedBox(height: 14),
        const _PackLegend(),
      ],
    );
  }

  CheckInStatus _statusFor(DateTime date) {
    final record = checkIns[bcDateKey(date)];
    if (record == null) return CheckInStatus.unrecorded;
    return record ? CheckInStatus.taken : CheckInStatus.missed;
  }
}

class _PackDayCell extends StatelessWidget {
  const _PackDayCell({
    required this.slot,
    required this.date,
    required this.isBreakDay,
    required this.isToday,
    required this.isFuture,
    required this.status,
    required this.onTap,
  });

  final int slot;
  final DateTime date;
  final bool isBreakDay;
  final bool isToday;
  final bool isFuture;
  final CheckInStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);

    // Resolution order matters: a recorded status always outranks the
    // decoration for "today" or "break day", because the record is the fact
    // and the rest is context.
    final (fill, border, foreground) = switch (status) {
      CheckInStatus.taken => (
          AppColors.success.withOpacity(context.isDark ? 0.34 : 0.18),
          AppColors.success,
          AppColors.success,
        ),
      CheckInStatus.missed => (
          AppColors.error.withOpacity(context.isDark ? 0.30 : 0.14),
          AppColors.error,
          AppColors.error,
        ),
      CheckInStatus.unrecorded => isBreakDay
          ? (
              context.lineColor.withOpacity(context.isDark ? 0.45 : 0.55),
              Colors.transparent,
              context.subtleColor,
            )
          : (
              context.cardColor,
              isToday ? context.accentColor : context.lineColor,
              isFuture ? context.subtleColor : context.mutedColor,
            ),
    };

    return Pressable(
      onTap: onTap,
      haptic: false,
      scale: 0.9,
      child: AnimatedContainer(
        duration: motion(AppDurations.fast),
        curve: AppCurves.out,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: border,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (status == CheckInStatus.taken)
              Icon(Icons.check_rounded, size: 15, color: foreground)
            else if (status == CheckInStatus.missed)
              Icon(Icons.close_rounded, size: 15, color: foreground)
            else
              Text(
                '$slot',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                  color: foreground,
                ),
              ),
            if (isBreakDay && status == CheckInStatus.unrecorded)
              Text(
                'br',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: context.subtleColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackLegend extends StatelessWidget {
  const _PackLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        const _LegendDot(color: AppColors.success, label: 'Taken'),
        const _LegendDot(color: AppColors.error, label: 'Missed'),
        _LegendDot(color: context.accentColor, label: 'Today', hollow: true),
        _LegendDot(color: context.lineColor, label: 'Break day'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.hollow = false,
  });

  final Color color;
  final String label;
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: hollow ? Colors.transparent : color.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: context.mutedColor,
          ),
        ),
      ],
    );
  }
}

// ─── History ─────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.checkIns, required this.onToggleDay});

  final Map<String, bool> checkIns;
  final ValueChanged<DateTime> onToggleDay;

  static const _days = 30;

  @override
  Widget build(BuildContext context) {
    final today = bcDateOnly(DateTime.now());

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: SizedBox(
        // Bounded so the page stays scannable: the history is a reference,
        // not the main event, and 30 full-height rows would bury everything
        // under it.
        height: 306,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _days,
          separatorBuilder: (context, _) => Divider(
            height: 1,
            thickness: 1,
            indent: 14,
            endIndent: 14,
            color: context.lineColor.withOpacity(0.5),
          ),
          itemBuilder: (context, i) {
            final date = today.subtract(Duration(days: i));
            final record = checkIns[bcDateKey(date)];
            final status = record == null
                ? CheckInStatus.unrecorded
                : (record ? CheckInStatus.taken : CheckInStatus.missed);
            return _HistoryRow(
              date: date,
              status: status,
              offset: i,
              onTap: () => onToggleDay(date),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.date,
    required this.status,
    required this.offset,
    required this.onTap,
  });

  final DateTime date;
  final CheckInStatus status;
  final int offset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (status) {
      CheckInStatus.taken => ('Taken', AppColors.success, Icons.check_rounded),
      CheckInStatus.missed => ('Missed', AppColors.error, Icons.close_rounded),
      CheckInStatus.unrecorded => (
          'Not recorded',
          context.subtleColor,
          Icons.remove_rounded,
        ),
    };

    final title = switch (offset) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => _weekdayName(date),
    };

    return Pressable(
      onTap: onTap,
      haptic: false,
      scale: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.withOpacity(context.isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: tone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: context.inkColor,
                    ),
                  ),
                  Text(
                    _shortDate(date),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: context.mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: status == CheckInStatus.unrecorded
                    ? context.subtleColor
                    : tone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Method detail ───────────────────────────────────────────────────────────

class _MethodDetailCard extends StatelessWidget {
  const _MethodDetailCard({required this.method});

  final BirthControlMethod method;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            method.summary,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: context.mutedColor,
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: 'How it is used',
            value: method.routine,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.science_rounded,
            label: 'Type',
            value: '${method.hormoneTag} · ${method.cadence.toLowerCase()}',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: context.subtleColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Method picker sheet ─────────────────────────────────────────────────────

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.current});

  final BirthControlMethod current;

  @override
  Widget build(BuildContext context) {
    final grouped = BirthControlMethod.grouped;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descriptions are general. The leaflet in your pack and your own '
          'clinician are the authority on your product.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: context.mutedColor,
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8, top: 4),
            child: Text(
              entry.key.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: context.subtleColor,
              ),
            ),
          ),
          for (final method in entry.value)
            _MethodOption(
              method: method,
              selected: method == current,
              onTap: () => Navigator.of(context).pop(method),
            ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final BirthControlMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      emphasis: selected ? CardEmphasis.tinted : CardEmphasis.outlined,
      borderColor: selected ? accent : null,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(method.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  method.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: context.inkColor,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 19, color: accent)
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  size: 19,
                  color: context.subtleColor,
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            method.summary,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: context.mutedColor,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.autorenew_rounded,
                size: 14,
                color: context.subtleColor,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  method.routine,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: context.subtleColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Missed-pill helper ──────────────────────────────────────────────────────

/// Deliberately gives no guidance.
///
/// Every safe answer to "I missed one" depends on the product, the position in
/// the pack and the person, so this sheet routes to the two sources that can
/// actually answer it and offers to record the day. Nothing more.
class _MissedPillSheet extends StatelessWidget {
  const _MissedPillSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoBanner(
          icon: Icons.report_gmailerrorred_rounded,
          tone: AppColors.warning,
          title: 'CycleCare cannot tell you what to do',
          message:
              'What applies after a missed pill depends on the exact product, '
              'where you are in the pack, and your own medical history. This app '
              'has none of that context and will not guess.',
        ),
        const SizedBox(height: 18),
        Text(
          'Where to get a real answer',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: context.inkColor,
          ),
        ),
        const SizedBox(height: 10),
        const _SourceTile(
          emoji: '📄',
          title: 'The leaflet that came with your pack',
          body:
              'The patient information leaflet is written for your specific '
              'product and covers missed doses for it. If the paper is gone, the '
              'manufacturer publishes the same leaflet online.',
        ),
        const SizedBox(height: 10),
        const _SourceTile(
          emoji: '🧑‍⚕️',
          title: 'A pharmacist or your clinician',
          body:
              'A pharmacist can usually answer the same day and without an '
              'appointment. Your prescriber or clinic can as well.',
        ),
        const SizedBox(height: 22),
        Text(
          'Record it for your own history',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: context.inkColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Optional, and only for you. Marking a day makes it visible in your '
          'history and adherence figures.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: context.mutedColor,
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Mark today as missed',
          icon: Icons.event_busy_rounded,
          onPressed: () => Navigator.of(context).pop('today'),
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: 'Choose another day',
          icon: Icons.calendar_month_rounded,
          outlined: true,
          onPressed: () => Navigator.of(context).pop('pick'),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: context.inkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: context.mutedColor,
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

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoBanner(
          icon: Icons.health_and_safety_rounded,
          title: 'Educational information only',
          message:
              'Method descriptions here are general and are not tailored to any '
              'product or person. They are not medical advice.',
        ),
        SizedBox(height: 16),
        _SourceTile(
          emoji: '🚫',
          title: 'What this screen will not do',
          body:
              'It does not state doses, does not tell you when or whether to take '
              'anything, does not quote effectiveness figures, and does not advise '
              'on missed doses.',
        ),
        SizedBox(height: 10),
        _SourceTile(
          emoji: '✅',
          title: 'What it does do',
          body:
              'Keeps a record of the days you check in, shows where you are in a '
              'pack, and describes methods in plain terms so the vocabulary is '
              'familiar next time you talk to a clinician.',
        ),
        SizedBox(height: 10),
        _SourceTile(
          emoji: '🔒',
          title: 'Where your records live',
          body:
              'Check-ins, method and pack settings are stored on this device only. '
              'They are not uploaded and not shared with a partner account.',
        ),
      ],
    );
  }
}

// ─── Date formatting ─────────────────────────────────────────────────────────
//
// Hand-rolled rather than pulled from a formatting package: two labels, two
// lookup tables, and no extra dependency reaching into a self-contained
// feature.

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _weekdayName(DateTime date) => _weekdays[date.weekday - 1];

String _shortDate(DateTime date) => '${date.day} ${_months[date.month - 1]}';
