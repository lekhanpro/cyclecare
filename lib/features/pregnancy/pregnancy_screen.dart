import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'application/appointments_controller.dart';
import 'pregnancy_content.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pregnancy mode
//
// Three jobs on one screen, in the order someone actually opens the app for:
// where am I, what is happening this week, and what is coming up. The kick
// counter sits between them because it is the only thing here that gets tapped
// repeatedly rather than read.
// ─────────────────────────────────────────────────────────────────────────────

/// Movements many people are asked to count in a single sitting. Used only to
/// draw a progress bar — the screen never tells anyone what to do about it.
const int _kickTarget = 10;

// ─── State ────────────────────────────────────────────────────────────────────
class PregnancyState {
  const PregnancyState({
    this.isActive = false,
    this.dueDate,
    this.kickCount = 0,
    this.lastKickSession,
  });

  final bool isActive;
  final DateTime? dueDate;
  final int kickCount;
  final DateTime? lastKickSession;

  /// A full term measured from the last menstrual period: 40 weeks.
  static const int gestationDays = 280;

  int get weeksPregnant {
    if (dueDate == null) return 0;
    final conception = dueDate!.subtract(const Duration(days: gestationDays));
    final diff = DateTime.now().difference(conception).inDays;
    return (diff / 7).floor().clamp(0, 42);
  }

  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays.clamp(0, gestationDays);
  }

  /// Total days elapsed, so the hero can show "week 24 + 3 days" rather than
  /// rounding three days of progress away.
  int get daysPregnant {
    if (dueDate == null) return 0;
    final conception = dueDate!.subtract(const Duration(days: gestationDays));
    return DateTime.now().difference(conception).inDays.clamp(0, 294);
  }

  /// Day within the current week, 0–6.
  int get dayOfWeek => daysPregnant % 7;

  double get progress => (daysPregnant / gestationDays).clamp(0.0, 1.0);

  int get trimester => PregnancyContent.trimesterFor(weeksPregnant);

  bool get isOverdue {
    final due = dueDate;
    return due != null && DateTime.now().isAfter(due);
  }

  int get daysOverdue {
    final due = dueDate;
    if (due == null) return 0;
    final over = DateTime.now().difference(due).inDays;
    return over < 0 ? 0 : over;
  }
}

class PregnancyNotifier extends AsyncNotifier<PregnancyState> {
  static const _activeKey = 'cc.preg.active';
  static const _dueDateKey = 'cc.preg.dueDate';
  static const _kickKey = 'cc.preg.kicks';

  /// Added alongside the original keys rather than replacing any of them, so
  /// existing installs read back exactly as before — they simply have no
  /// session stamp until the next kick is logged.
  static const _kickSessionKey = 'cc.preg.kickSession';

  @override
  Future<PregnancyState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(_activeKey) ?? false;
    final dueDateStr = prefs.getString(_dueDateKey);
    final kicks = prefs.getInt(_kickKey) ?? 0;
    final sessionStr = prefs.getString(_kickSessionKey);
    return PregnancyState(
      isActive: active,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
      kickCount: kicks,
      lastKickSession:
          sessionStr != null ? DateTime.tryParse(sessionStr) : null,
    );
  }

  Future<void> activate(DateTime dueDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, true);
    await prefs.setString(_dueDateKey, dueDate.toIso8601String());
    state = AsyncData(PregnancyState(isActive: true, dueDate: dueDate));
  }

  Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, false);
    state = const AsyncData(PregnancyState());
  }

  Future<void> logKick() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.valueOrNull ?? const PregnancyState();
    final newCount = current.kickCount + 1;
    final now = DateTime.now();
    await prefs.setInt(_kickKey, newCount);
    await prefs.setString(_kickSessionKey, now.toIso8601String());
    state = AsyncData(PregnancyState(
      isActive: current.isActive,
      dueDate: current.dueDate,
      kickCount: newCount,
      lastKickSession: now,
    ));
  }

  Future<void> resetKicks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kickKey, 0);
    await prefs.remove(_kickSessionKey);
    final current = state.valueOrNull ?? const PregnancyState();
    state = AsyncData(PregnancyState(
      isActive: current.isActive,
      dueDate: current.dueDate,
      kickCount: 0,
    ));
  }
}

final pregnancyProvider =
    AsyncNotifierProvider<PregnancyNotifier, PregnancyState>(
  PregnancyNotifier.new,
);

// ─── Screen ───────────────────────────────────────────────────────────────────
class PregnancyScreen extends ConsumerWidget {
  const PregnancyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregAsync = ref.watch(pregnancyProvider);

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(title: const Text('Pregnancy')),
      body: pregAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load pregnancy mode',
          message: 'Something went wrong reading your saved data. '
              'Trying again usually sorts it.',
          icon: Icons.cloud_off_rounded,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(pregnancyProvider),
        ),
        data: (preg) => preg.isActive
            ? _ActivePregnancyView(preg: preg)
            : const _SetupView(),
      ),
    );
  }
}

// ─── Setup ────────────────────────────────────────────────────────────────────
class _SetupView extends StatelessWidget {
  const _SetupView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        28 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        EmptyState(
          emoji: '🤰',
          title: 'Pregnancy mode',
          message: 'Follow the weeks as they come — what is developing, what '
              'your body is doing, and every appointment kept in one place.',
          actionLabel: 'Set your due date',
          onAction: () => _openDueDateSheet(context),
        ),
        const SizedBox(height: 4),
        const Reveal(
          index: 4,
          child: SectionHeader(
            title: "What you'll get",
            padding: EdgeInsets.only(left: 4, right: 4, bottom: 10),
          ),
        ),
        const Reveal(
          index: 5,
          child: ActionTile(
            icon: Icons.auto_stories_rounded,
            emoji: '📖',
            title: 'Week-by-week updates',
            subtitle: 'Weeks 4 to 40, with a size you can actually picture',
            trailing: SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 10),
        const Reveal(
          index: 6,
          child: ActionTile(
            icon: Icons.child_care_rounded,
            emoji: '👣',
            title: 'Kick counter',
            subtitle: 'Track a counting session with one thumb',
            trailing: SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 10),
        const Reveal(
          index: 7,
          child: ActionTile(
            icon: Icons.event_note_rounded,
            emoji: '🗓️',
            title: 'Appointment tracking',
            subtitle: 'Scans, checks and the notes you took last visit',
            trailing: SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 18),
        const Reveal(index: 8, child: _MedicalDisclaimer()),
      ],
    );
  }
}

enum _DueMode { dueDate, lastPeriod }

Future<void> _openDueDateSheet(BuildContext context) async {
  final started = await showAppSheet<bool>(
    context: context,
    title: 'Start pregnancy tracking',
    child: const _DueDateSheet(),
  );
  if (started == true && context.mounted) {
    showAppToast(context, message: 'Pregnancy mode is on');
  }
}

class _DueDateSheet extends ConsumerStatefulWidget {
  const _DueDateSheet();

  @override
  ConsumerState<_DueDateSheet> createState() => _DueDateSheetState();
}

class _DueDateSheetState extends ConsumerState<_DueDateSheet> {
  _DueMode _mode = _DueMode.dueDate;
  DateTime? _picked;
  bool _saving = false;

  /// The due date either way: entered directly, or a full term after the first
  /// day of the last period.
  DateTime? get _due {
    final picked = _picked;
    if (picked == null) return null;
    return _mode == _DueMode.dueDate
        ? picked
        : picked.add(const Duration(days: PregnancyState.gestationDays));
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Two very different ranges: a due date is ahead of you, a last period is
    // behind you. Anchoring each to a sensible default saves a lot of scrolling.
    final (first, last, initial) = _mode == _DueMode.dueDate
        ? (
            today,
            today.add(const Duration(days: 300)),
            _picked ?? today.add(const Duration(days: 180)),
          )
        : (
            today.subtract(const Duration(days: 300)),
            today,
            _picked ?? today.subtract(const Duration(days: 56)),
          );

    final picked = await showDatePicker(
      context: context,
      initialDate: _clampDate(initial, first, last),
      firstDate: first,
      lastDate: last,
      helpText: _mode == _DueMode.dueDate
          ? 'Estimated due date'
          : 'First day of last period',
    );
    if (picked == null || !mounted) return;
    setState(() => _picked = picked);
  }

  Future<void> _start() async {
    final due = _due;
    if (due == null) return;
    setState(() => _saving = true);
    await ref.read(pregnancyProvider.notifier).activate(due);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final due = _due;
    final preview = due == null ? null : PregnancyState(dueDate: due);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('What do you know?'),
        const SizedBox(height: 8),
        SegmentedSelector<_DueMode>(
          segments: const {
            _DueMode.dueDate: 'Due date',
            _DueMode.lastPeriod: 'Last period',
          },
          value: _mode,
          onChanged: (mode) => setState(() {
            _mode = mode;
            _picked = null;
          }),
        ),
        const SizedBox(height: 18),
        _FieldLabel(
          _mode == _DueMode.dueDate
              ? 'Your estimated due date'
              : 'First day of your last period',
        ),
        const SizedBox(height: 8),
        _PickerField(
          icon: Icons.calendar_today_rounded,
          value: _picked == null
              ? 'Choose a date'
              : DateFormat('EEE, MMM d, yyyy').format(_picked!),
          placeholder: _picked == null,
          onTap: _pick,
        ),
        if (preview != null) ...[
          const SizedBox(height: 16),
          AppCard(
            emphasis: CardEmphasis.tinted,
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'That puts you at about week ${preview.weeksPregnant}, '
                  'day ${preview.dayOfWeek + 1}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: context.inkColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${PregnancyContent.trimesterLabel(preview.trimester)} '
                  'trimester · due '
                  '${DateFormat('MMM d, yyyy').format(preview.dueDate!)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Start tracking',
          icon: Icons.favorite_rounded,
          loading: _saving,
          onPressed: due == null ? null : _start,
        ),
        const SizedBox(height: 12),
        Text(
          'You can change the date or turn pregnancy mode off at any time.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: context.subtleColor,
          ),
        ),
      ],
    );
  }
}

// ─── Active view ──────────────────────────────────────────────────────────────
class _ActivePregnancyView extends ConsumerStatefulWidget {
  const _ActivePregnancyView({required this.preg});

  final PregnancyState preg;

  @override
  ConsumerState<_ActivePregnancyView> createState() =>
      _ActivePregnancyViewState();
}

class _ActivePregnancyViewState extends ConsumerState<_ActivePregnancyView> {
  final ScrollController _weekScroll = ScrollController();

  /// Null means "follow the current week". Set once the user starts browsing,
  /// so the screen does not silently jump back under them.
  int? _selectedWeek;

  /// Pill width plus its trailing gap. Fixed so the strip can be scrolled to a
  /// specific week without measuring anything.
  static const double _pillExtent = 62;

  int get _currentWeek => widget.preg.weeksPregnant
      .clamp(PregnancyContent.minWeek, PregnancyContent.maxWeek);

  int get _week => _selectedWeek ?? _currentWeek;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOn(_week, animate: false);
    });
  }

  @override
  void dispose() {
    _weekScroll.dispose();
    super.dispose();
  }

  void _centerOn(int week, {bool animate = true}) {
    if (!_weekScroll.hasClients) return;
    final position = _weekScroll.position;
    final index = week - PregnancyContent.minWeek;
    final target = (index * _pillExtent +
            _pillExtent / 2 -
            position.viewportDimension / 2)
        .clamp(0.0, position.maxScrollExtent);

    if (animate && !Motion.of(context).reduced) {
      _weekScroll.animateTo(
        target,
        duration: AppDurations.normal,
        curve: AppCurves.inOut,
      );
    } else {
      _weekScroll.jumpTo(target);
    }
  }

  void _selectWeek(int week, {bool center = false}) {
    setState(() => _selectedWeek = week);
    if (center) _centerOn(week);
  }

  Future<void> _exit() async {
    final confirmed = await confirmAction(
      context,
      title: 'Exit pregnancy mode?',
      message: 'Tracking turns off and this screen goes back to setup. '
          'Your saved appointments stay where they are.',
      confirmLabel: 'Exit',
    );
    if (!confirmed || !mounted) return;
    await ref.read(pregnancyProvider.notifier).deactivate();
    if (!mounted) return;
    showAppToast(
      context,
      message: 'Pregnancy mode turned off',
      kind: ToastKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preg = widget.preg;
    final week = _week;
    final entry = PregnancyContent.forWeek(week);
    final browsing = week != _currentWeek;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        28 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        Reveal(
          child: _HeroCard(
            preg: preg,
            entry: PregnancyContent.forWeek(_currentWeek),
          ),
        ),
        const SizedBox(height: 22),
        Reveal(
          index: 1,
          child: SectionHeader(
            title: browsing ? 'Week $week' : 'This week',
            subtitle: browsing
                ? 'Reading ahead — tap to jump back'
                : 'Where things are right now',
            actionLabel: browsing ? 'Today' : null,
            onAction: browsing
                ? () {
                    Haptics.selection();
                    setState(() => _selectedWeek = null);
                    _centerOn(_currentWeek);
                  }
                : null,
          ),
        ),
        Reveal(
          index: 2,
          child: SegmentedSelector<int>(
            segments: const {1: '1st', 2: '2nd', 3: '3rd'},
            value: entry.trimester,
            onChanged: (trimester) {
              final range = PregnancyContent.trimesterRange(trimester);
              // Jumping to a trimester lands on its first week unless the
              // current week already sits inside it.
              final target = _currentWeek >= range.start &&
                      _currentWeek <= range.end
                  ? _currentWeek
                  : range.start;
              _selectWeek(target, center: true);
            },
          ),
        ),
        const SizedBox(height: 12),
        _WeekStrip(
          controller: _weekScroll,
          selected: week,
          current: _currentWeek,
          onSelect: _selectWeek,
        ),
        const SizedBox(height: 12),
        _WeekContentCard(entry: entry),
        const SizedBox(height: 24),
        _KickCounterCard(preg: preg),
        const SizedBox(height: 24),
        const _AppointmentsSection(),
        const SizedBox(height: 20),
        const _MedicalDisclaimer(),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Exit pregnancy mode',
          icon: Icons.logout_rounded,
          outlined: true,
          destructive: true,
          onPressed: _exit,
        ),
      ],
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.preg, required this.entry});

  final PregnancyState preg;
  final PregnancyWeek entry;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final radius = BorderRadius.circular(26);

    return ClipRRect(
      borderRadius: radius,
      child: PhaseBackdrop(
        // The backdrop shifts hue by trimester, which gives the screen a slow
        // sense of progress across months without moving anything around.
        colors: _trimesterGradient(preg.trimester),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: GlassCard(
            borderRadius: BorderRadius.circular(21),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEEK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                              color: context.mutedColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AnimatedCount(
                                value: preg.weeksPregnant,
                                style: TextStyle(
                                  fontSize: 44,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.8,
                                  color: context.inkColor,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '+${preg.dayOfWeek}d',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${PregnancyContent.trimesterLabel(preg.trimester)}'
                            ' trimester',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: context.mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ProgressRing(progress: preg.progress, accent: accent),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: preg.isOverdue ? 'Days over' : 'Days to go',
                        value: preg.isOverdue
                            ? '${preg.daysOverdue}'
                            : '${preg.daysUntilDue}',
                      ),
                    ),
                    const _HeroDivider(),
                    Expanded(
                      child: _HeroStat(
                        label: 'Due date',
                        value: preg.dueDate == null
                            ? '—'
                            : DateFormat('MMM d').format(preg.dueDate!),
                      ),
                    ),
                    const _HeroDivider(),
                    Expanded(
                      child: _HeroStat(
                        label: 'Complete',
                        value: '${(preg.progress * 100).round()}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(context.isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.straighten_rounded, size: 16, color: accent),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'About the size of '
                          '${_article(entry.sizeComparison)} '
                          '${entry.sizeComparison}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.inkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: context.inkColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.mutedColor,
          ),
        ),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: context.lineColor.withOpacity(0.7),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  /// Large enough for the percentage to sit inside the ring at a readable
  /// size, small enough to stay a companion to the week number rather than
  /// competing with it.
  static const double _diameter = 86;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);

    return SizedBox(
      width: _diameter,
      height: _diameter,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: progress),
        duration: motion(AppDurations.reveal),
        curve: AppCurves.inOut,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            track: context.lineColor,
            accent: accent,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).round()}%',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: context.inkColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'of 40wk',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: context.mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.accent,
  });

  final double progress;
  final Color track;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    final swept = progress.clamp(0.0, 1.0);
    if (swept <= 0) return;

    // The gradient runs along the arc so the leading edge is the strongest
    // point — the eye lands on where you are, not where you started.
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [accent.withOpacity(0.45), accent],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * swept, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.accent != accent;
}

// ─── Week browser ─────────────────────────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.controller,
    required this.selected,
    required this.current,
    required this.onSelect,
  });

  final ScrollController controller;
  final int selected;
  final int current;
  final void Function(int week) onSelect;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final accent = context.accentColor;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    const count = PregnancyContent.maxWeek - PregnancyContent.minWeek + 1;

    return SizedBox(
      height: 60,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) {
          final week = PregnancyContent.minWeek + index;
          final isSelected = week == selected;
          final isCurrent = week == current;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 54,
              child: Pressable(
                haptic: false,
                scale: 0.93,
                onTap: () {
                  if (isSelected) return;
                  Haptics.selection();
                  onSelect(week);
                },
                child: AnimatedContainer(
                  duration: motion(AppDurations.fast),
                  curve: AppCurves.out,
                  decoration: BoxDecoration(
                    color: isSelected ? accent : context.cardColor,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isCurrent
                              ? accent.withOpacity(0.55)
                              : context.lineColor,
                      // The current week keeps a heavier outline even when
                      // another week is selected, so "where I actually am"
                      // never disappears from the strip.
                      width: isCurrent && !isSelected ? 1.7 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accent.withOpacity(0.26),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$week',
                        style: TextStyle(
                          fontSize: 17,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: isSelected ? onAccent : context.inkColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isCurrent ? 'now' : 'wk',
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: isSelected
                              ? onAccent.withOpacity(0.82)
                              : isCurrent
                                  ? accent
                                  : context.subtleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WeekContentCard extends StatelessWidget {
  const _WeekContentCard({required this.entry});

  final PregnancyWeek entry;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return AppCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(context.isDark ? 0.22 : 0.11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Week ${entry.week}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${PregnancyContent.trimesterLabel(entry.trimester)} trimester',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: context.mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            'Roughly ${_article(entry.sizeComparison)} '
            '${entry.sizeComparison}',
            style: TextStyle(
              fontSize: 19,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: context.inkColor,
            ),
          ),
          const SizedBox(height: 16),
          _ContentBlock(
            icon: Icons.child_care_rounded,
            title: 'Your baby',
            body: entry.babyUpdate,
          ),
          const SizedBox(height: 15),
          _ContentBlock(
            icon: Icons.favorite_rounded,
            title: 'Your body',
            body: entry.bodyUpdate,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(context.isDark ? 0.15 : 0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withOpacity(0.26)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  size: 17,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Worth knowing',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          color: context.inkColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.tip,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: context.isDark
                              ? context.inkColor.withOpacity(0.86)
                              : context.mutedColor,
                        ),
                      ),
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

class _ContentBlock extends StatelessWidget {
  const _ContentBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: context.inkColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.55,
            fontWeight: FontWeight.w600,
            color: context.mutedColor,
          ),
        ),
      ],
    );
  }
}

// ─── Kick counter ─────────────────────────────────────────────────────────────
class _KickCounterCard extends ConsumerWidget {
  const _KickCounterCard({required this.preg});

  final PregnancyState preg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = Motion.of(context);
    final accent = context.accentColor;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    final count = preg.kickCount;
    final session = preg.lastKickSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Kick counter',
          subtitle: session == null
              ? 'Tap once for every movement you feel'
              : 'Last movement ${DateFormat('h:mm a').format(session)}',
        ),
        AppCard(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedCount(
                    value: count,
                    style: TextStyle(
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.6,
                      color: context.inkColor,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      count == 1 ? 'movement' : 'movements',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: context.mutedColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (count >= _kickTarget)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withOpacity(context.isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '10 reached',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < _kickTarget; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: AnimatedContainer(
                          duration: motion(AppDurations.fast),
                          curve: AppCurves.out,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i < count
                                ? (count >= _kickTarget
                                    ? AppColors.success
                                    : accent)
                                : context.lineColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      // Haptics are fired by hand here: reaching the target
                      // deserves a different response from the nine taps
                      // before it, which the shared tap feedback cannot express.
                      haptic: false,
                      scale: 0.96,
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _logKick(context, ref),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(
                                context.isDark ? 0.34 : 0.28,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: onAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Log a movement',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: onAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Pressable(
                    haptic: false,
                    scale: 0.94,
                    borderRadius: BorderRadius.circular(16),
                    onTap: count == 0 ? null : () => _reset(context, ref),
                    child: Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.lineColor),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 21,
                        color: count == 0
                            ? context.subtleColor
                            : context.mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                'Counting to 10 movements in one sitting is a common way to '
                'check in. You know your own pattern best — if it changes, '
                'your care team would rather hear from you than not.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: context.subtleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _logKick(BuildContext context, WidgetRef ref) {
    final next = preg.kickCount + 1;
    if (next == _kickTarget) {
      Haptics.celebrate();
    } else {
      Haptics.tap();
    }
    ref.read(pregnancyProvider.notifier).logKick();
    if (next == _kickTarget) {
      // Info rather than success: the success toast fires its own haptic and
      // would land on top of the celebration.
      showAppToast(
        context,
        message: '10 movements logged in this session',
        kind: ToastKind.info,
      );
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    Haptics.warn();
    await ref.read(pregnancyProvider.notifier).resetKicks();
    if (!context.mounted) return;
    showAppToast(
      context,
      message: 'Counter reset',
      kind: ToastKind.info,
    );
  }
}

// ─── Appointments ─────────────────────────────────────────────────────────────
class _AppointmentsSection extends ConsumerWidget {
  const _AppointmentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingAppointmentsProvider);
    final past = ref.watch(pastAppointmentsProvider);
    final isEmpty = upcoming.isEmpty && past.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Appointments',
          subtitle: upcoming.isEmpty
              ? 'Scans, checks and tests in one place'
              : '${upcoming.length} coming up',
          actionLabel: 'Add',
          onAction: () => _openAppointmentSheet(context),
        ),
        if (isEmpty)
          AppCard(
            emphasis: CardEmphasis.outlined,
            padding: EdgeInsets.zero,
            child: EmptyState(
              title: 'Nothing booked yet',
              message: 'Add your next scan or midwife check and it will sit '
                  'here alongside the notes you took last time.',
              icon: Icons.event_available_rounded,
              actionLabel: 'Add appointment',
              onAction: () => _openAppointmentSheet(context),
            ),
          )
        else ...[
          for (final appointment in upcoming) ...[
            _AppointmentCard(appointment: appointment, isPast: false),
            const SizedBox(height: 10),
          ],
          if (past.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Past visits',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  color: context.mutedColor,
                ),
              ),
            ),
            for (final appointment in past) ...[
              _AppointmentCard(appointment: appointment, isPast: true),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ],
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({required this.appointment, required this.isPast});

  final Appointment appointment;
  final bool isPast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = isPast ? context.mutedColor : context.accentColor;
    final date = appointment.dateTime;
    final subtitle = [
      if (appointment.doctor != null) appointment.doctor!,
      if (appointment.location != null) appointment.location!,
    ].join(' · ');

    return AppCard(
      emphasis: isPast ? CardEmphasis.outlined : CardEmphasis.raised,
      padding: const EdgeInsets.all(13),
      onTap: () => _openAppointmentSheet(context, existing: appointment),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: tone.withOpacity(context.isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: tone,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 19,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: context.inkColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: context.inkColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('EEE, h:mm a').format(date)}'
                  '${isPast ? '' : ' · ${_relativeDay(date)}'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPast ? context.subtleColor : tone,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: context.mutedColor,
                    ),
                  ),
                ],
                if (appointment.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.sticky_note_2_rounded,
                        size: 13,
                        color: context.subtleColor,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          appointment.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.subtleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Pressable(
            haptic: false,
            scale: 0.88,
            onTap: () => _confirmDelete(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: context.subtleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete appointment?',
      message: '${appointment.title} will be removed from your list. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(appointmentsProvider.notifier).remove(appointment.id);
    if (!context.mounted) return;
    showAppToast(context, message: 'Appointment deleted', kind: ToastKind.info);
  }
}

/// What the editor sheet did, reported back so the toast fires from a context
/// that is still around to show it.
enum _SheetResult { saved, updated, deleted }

Future<void> _openAppointmentSheet(
  BuildContext context, {
  Appointment? existing,
}) async {
  final result = await showAppSheet<_SheetResult>(
    context: context,
    title: existing == null ? 'New appointment' : 'Edit appointment',
    child: _AppointmentSheet(existing: existing),
  );
  if (result == null || !context.mounted) return;

  showAppToast(
    context,
    message: switch (result) {
      _SheetResult.saved => 'Appointment saved',
      _SheetResult.updated => 'Appointment updated',
      _SheetResult.deleted => 'Appointment deleted',
    },
    kind: result == _SheetResult.deleted ? ToastKind.info : ToastKind.success,
  );
}

class _AppointmentSheet extends ConsumerStatefulWidget {
  const _AppointmentSheet({this.existing});

  final Appointment? existing;

  @override
  ConsumerState<_AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends ConsumerState<_AppointmentSheet> {
  late final TextEditingController _title;
  late final TextEditingController _doctor;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late DateTime _when;
  bool _saving = false;

  /// The appointments almost everyone books at least once. Typing them out on
  /// a phone keyboard six times over is the kind of friction that stops people
  /// logging anything at all.
  static const List<String> _presets = [
    'Midwife check',
    'Ultrasound scan',
    'Blood test',
    'Glucose test',
    'Consultant review',
    'Antenatal class',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _doctor = TextEditingController(text: existing?.doctor ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _when = existing?.dateTime ?? _defaultWhen();
  }

  @override
  void dispose() {
    _title.dispose();
    _doctor.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  static DateTime _defaultWhen() {
    final target = DateTime.now().add(const Duration(days: 7));
    return DateTime(target.year, target.month, target.day, 10);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = now.subtract(const Duration(days: 400));
    final last = now.add(const Duration(days: 400));

    final picked = await showDatePicker(
      context: context,
      initialDate: _clampDate(_when, first, last),
      firstDate: first,
      lastDate: last,
      helpText: 'Appointment date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _when = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _when.hour,
        _when.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
      helpText: 'Appointment time',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _when = DateTime(
        _when.year,
        _when.month,
        _when.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showAppToast(
        context,
        message: 'Give the appointment a name first',
        kind: ToastKind.warning,
      );
      return;
    }

    setState(() => _saving = true);

    final doctor = _doctor.text.trim();
    final location = _location.text.trim();
    final draft = Appointment(
      id: widget.existing?.id ?? AppointmentsNotifier.newId(),
      title: title,
      doctor: doctor.isEmpty ? null : doctor,
      dateTime: _when,
      location: location.isEmpty ? null : location,
      notes: _notes.text.trim(),
    );

    final notifier = ref.read(appointmentsProvider.notifier);
    if (widget.existing == null) {
      await notifier.add(draft);
    } else {
      await notifier.update(draft);
    }

    if (!mounted) return;
    // The toast is left to the caller: this route is about to be torn down and
    // a messenger call on the way out is how you get a toast that never shows.
    Navigator.of(context).pop(
      widget.existing == null ? _SheetResult.saved : _SheetResult.updated,
    );
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await confirmAction(
      context,
      title: 'Delete appointment?',
      message: '${existing.title} will be removed from your list. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    await ref.read(appointmentsProvider.notifier).remove(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop(_SheetResult.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = _title.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('What is it'),
        const SizedBox(height: 8),
        _AppointmentField(
          controller: _title,
          hint: 'Midwife check',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _presets)
              SelectableChip(
                label: preset,
                selected: selectedPreset == preset,
                onSelected: (_) => setState(() {
                  _title.text = preset;
                  _title.selection = TextSelection.collapsed(
                    offset: preset.length,
                  );
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const _FieldLabel('When'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _PickerField(
                icon: Icons.calendar_today_rounded,
                value: DateFormat('EEE, MMM d').format(_when),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _PickerField(
                icon: Icons.schedule_rounded,
                value: DateFormat('h:mm a').format(_when),
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Who you are seeing'),
        const SizedBox(height: 8),
        _AppointmentField(
          controller: _doctor,
          hint: 'Midwife, obstetrician or clinic',
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Where'),
        const SizedBox(height: 8),
        _AppointmentField(
          controller: _location,
          hint: 'Clinic or hospital',
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Notes'),
        const SizedBox(height: 8),
        _AppointmentField(
          controller: _notes,
          hint: 'Questions to ask, or what you were told',
          minLines: 3,
          maxLines: 5,
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: widget.existing == null
              ? 'Save appointment'
              : 'Update appointment',
          icon: Icons.check_rounded,
          loading: _saving,
          onPressed: _save,
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Delete appointment',
            icon: Icons.delete_outline_rounded,
            outlined: true,
            destructive: true,
            onPressed: _delete,
          ),
        ],
      ],
    );
  }
}

// ─── Small shared pieces ──────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
        color: context.inkColor,
      ),
    );
  }
}

class _AppointmentField extends StatelessWidget {
  const _AppointmentField({
    required this.controller,
    required this.hint,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.lineColor),
    );

    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: context.inkColor,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: context.isDark
            ? context.canvasColor.withOpacity(0.55)
            : context.canvasColor,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.subtleColor,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.accentColor, width: 1.6),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: context.isDark
              ? context.canvasColor.withOpacity(0.55)
              : context.canvasColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.lineColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: context.accentColor),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: placeholder ? context.subtleColor : context.inkColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalDisclaimer extends StatelessWidget {
  const _MedicalDisclaimer();

  @override
  Widget build(BuildContext context) {
    return const InfoBanner(
      title: 'Not medical advice',
      message: 'CycleCare is not a medical device and this content is general '
          'information, not guidance for your pregnancy. Your midwife or '
          'doctor knows your history — follow them, and get in touch with '
          'them about anything that worries you.',
      icon: Icons.health_and_safety_rounded,
      tone: AppColors.info,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
List<Color> _trimesterGradient(int trimester) => switch (trimester) {
      1 => AppColors.follicularGradient,
      2 => AppColors.ovulationGradient,
      _ => AppColors.lutealGradient,
    };

/// Keeps `showDatePicker` out of assertion territory when a stored date falls
/// outside the range we want to offer.
DateTime _clampDate(DateTime value, DateTime first, DateTime last) {
  if (value.isBefore(first)) return first;
  if (value.isAfter(last)) return last;
  return value;
}

String _article(String noun) {
  if (noun.isEmpty) return 'a';
  return 'aeiou'.contains(noun[0].toLowerCase()) ? 'an' : 'a';
}

String _relativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final days = target.difference(today).inDays;

  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days < 0) return '${-days}d ago';
  if (days < 7) return 'in $days days';
  final weeks = (days / 7).round();
  return weeks == 1 ? 'in a week' : 'in $weeks weeks';
}
