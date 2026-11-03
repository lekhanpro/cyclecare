import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/haptics.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import 'application/reminders_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reminders
//
// One screen owns every notification the app can send, grouped into calm cards
// rather than scattered between here and Settings. Three rules shape it:
//
//  • A toggle must do something. An earlier version's switch had an empty
//    callback, so it animated and changed nothing.
//  • State is stated, never implied. An off reminder says "off, nothing will be
//    sent" in words instead of relying on a dimmer shade of the same row —
//    dimming is invisible to a screen reader and ambiguous to everyone else.
//  • The screen never claims delivery. CycleCare schedules on the device;
//    Android decides whether anything appears. The only honest way to know is
//    to send a test, so that action is always one tap away.
//
// The layout is a settings screen, not a feed. Six reminders used to arrive as
// six separate elevated cards, which gave six toggles six equal claims on the
// eye — the same as none. Now one surface leads (the count), the delivery
// caveat sits directly under it because it is the one thing the screen cannot
// promise, and the reminders themselves are two grouped lists with hairline
// rules and a single leading-icon column, so a row is read by its position
// rather than by its own border.
// ─────────────────────────────────────────────────────────────────────────────

/// Font size used to probe the current text scale. Dense rows swap to a stacked
/// variant instead of clipping a time or hiding a control.
const double _textScaleProbe = 14;

double _textScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(_textScaleProbe) / _textScaleProbe;

/// Narrowest a timing control can get before its value starts wrapping into an
/// unreadable column. Scaled by text size, so 200% type always stacks.
const double _minTimingTileWidth = 132;

/// Width of the leading icon column every row shares.
const double _markerSize = AppSpacing.huge;

/// Where a row's text starts, and therefore where its divider starts. Running
/// the rule under the icon column instead would hide the one alignment that
/// makes a list of rows read as a group.
const double _rowTextInset = AppSpacing.lg + _markerSize + AppSpacing.md;

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(remindersControllerProvider.notifier)
          .refreshSchedule()
          .catchError((Object _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersControllerProvider);

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            tooltip: 'Send a test notification',
            onPressed: () => _sendTest(context, ref),
            icon: const Icon(Icons.notifications_active_rounded),
          ),
        ],
      ),
      body: remindersAsync.when(
        loading: () => const _LoadingReminders(),
        error: (error, _) => _LoadFailure(error: error),
        data: (reminders) => reminders.isEmpty
            ? _PageShell(
                fillViewport: true,
                child: EmptyState(
                  icon: AppIcons.reminders,
                  title: 'No reminders yet',
                  message:
                      'Add one and CycleCare will nudge you before your period, '
                      'at pill time, or whenever suits you.',
                  actionLabel: 'Add a reminder',
                  onAction: () => _openCustomSheet(context, ref),
                ),
              )
            : _RemindersBody(reminders: reminders),
      ),
    );
  }
}

/// Page scaffolding shared by every state: safe area, a width-aware gutter, and
/// a content column that stops growing at [AppLayout.maxContentWidth] and
/// centres itself on tablets.
class _PageShell extends StatelessWidget {
  const _PageShell({required this.child, this.fillViewport = false});

  final Widget child;

  /// Stretches the content to at least one viewport height, so a short
  /// placeholder sits centred rather than pinned under the app bar.
  final bool fillViewport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

          Widget content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: child,
            ),
          );

          if (fillViewport) {
            content = ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: content,
            );
          }

          return SingleChildScrollView(
            padding: fillViewport
                ? EdgeInsets.symmetric(horizontal: gutter)
                : EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.md,
                    gutter,
                    AppSpacing.xxxl,
                  ),
            child: content,
          );
        },
      ),
    );
  }
}

/// Loading, named rather than blank. A bare spinner reads as a stall, and it
/// gives assistive technology nothing to announce.
class _LoadingReminders extends StatelessWidget {
  const _LoadingReminders();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: AppSpacing.xxl,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  semanticsLabel: 'Loading your reminders',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Getting your reminders ready',
                textAlign: TextAlign.center,
                style: text.labelLarge?.copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Load failure, kept actionable. The raw exception is never the headline — it
/// is unreadable on a phone and it buries the one thing the user can do.
class _LoadFailure extends ConsumerWidget {
  const _LoadFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final detail = error.toString().trim();

    return _PageShell(
      fillViewport: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyState(
            icon: Icons.notifications_off_rounded,
            title: 'We could not load your reminders',
            message:
                'Nothing was lost — your reminders stay on this device. '
                'Try again, and they should come back.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(remindersControllerProvider),
          ),
          Text(
            'Reference: ${error.runtimeType}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(color: context.subtleColor),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              detail,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: context.subtleColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemindersBody extends ConsumerWidget {
  const _RemindersBody({required this.reminders});

  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = reminders.where((reminder) => reminder.enabled).length;

    // Cycle reminders fire against a prediction; the rest fire on the clock.
    // That is the only grouping the user can act on — it is also what decides
    // whether a row has a notice period at all, so the two lists never carry
    // mismatched controls.
    final cycle = reminders.where((r) => _supportsLeadTime(r.type)).toList();
    final daily = reminders.where((r) => !_supportsLeadTime(r.type)).toList();

    return _PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            offsetY: AppSpacing.md,
            child: _StatusCard(active: active, total: reminders.length),
          ),

          // Directly under the lead surface rather than at the foot of the
          // page: the count says how many are scheduled, and this is the
          // immediate qualification on that number. Burying it below six cards
          // means it is read only after a reminder has already failed to
          // arrive.
          const SizedBox(height: AppSpacing.md),
          Reveal(
            index: 1,
            offsetY: AppSpacing.md,
            child: _DeliveryNote(onTest: () => _sendTest(context, ref)),
          ),

          if (cycle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const Reveal(
              index: 2,
              offsetY: AppSpacing.md,
              child: _SectionTitle(
                title: 'Around your cycle',
                subtitle: 'Sent ahead of an estimated date',
              ),
            ),
            Reveal(
              index: 3,
              offsetY: AppSpacing.md,
              child: _ReminderGroup(reminders: cycle),
            ),
          ],

          if (daily.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const Reveal(
              index: 4,
              offsetY: AppSpacing.md,
              child: _SectionTitle(
                title: 'Every day',
                subtitle: 'Sent at the same time each day',
              ),
            ),
            Reveal(
              index: 5,
              offsetY: AppSpacing.md,
              child: _ReminderGroup(reminders: daily),
            ),
          ],

          // A labelled button rather than a small "Add" link beside the section
          // title: at 200% text a link in a header row is the first thing to get
          // squeezed out, and this is the only way to create a reminder.
          const SizedBox(height: AppSpacing.xl),
          Reveal(
            index: 6,
            offsetY: AppSpacing.md,
            child: PrimaryButton(
              label: 'Add a reminder',
              icon: Icons.add_alert_rounded,
              outlined: true,
              onPressed: () => _openCustomSheet(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

/// One grouped list of reminder rows inside a single surface.
///
/// A flat card holding hairline-separated rows rather than one card per
/// reminder. Six bordered cards down a page is six boxes the eye has to
/// enter and leave; one box with six rows is a settings list, which is what
/// this screen is. The rule starts at the text inset so the icon column reads
/// as one continuous edge.
class _ReminderGroup extends StatelessWidget {
  const _ReminderGroup({required this.reminders});

  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return AppCard(
      emphasis: CardEmphasis.outlined,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < reminders.length; i++) ...[
              if (i > 0)
                Divider(
                  height: AppStrokes.hairline,
                  thickness: AppStrokes.hairline,
                  indent: _rowTextInset,
                  endIndent: AppSpacing.lg,
                  color: context.lineColor,
                ),
              _ReminderRow(reminder: reminders[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// The delivery caveat, and the only action that can actually test it.
///
/// Phrased as a condition the user may already be in rather than a warning:
/// the app cannot read the system's per-app notification state from here, so
/// asserting "notifications are blocked" would be a guess. Sending one is the
/// check, so that is the action — and the route to the OS switch stays on
/// screen, because a user whose notifications are off cannot be told to go
/// look for the instructions.
class _DeliveryNote extends ConsumerWidget {
  const _DeliveryNote({required this.onTest});
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reminderScheduleReportProvider);
    final saveError = ref.watch(reminderSaveErrorProvider);
    final env = report.environment;
    final controller = ref.read(remindersControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (saveError != null) ...[
          InfoBanner(
            icon: AppIcons.reminders,
            tone: AppColors.period,
            title: 'Change not saved',
            message: saveError,
            actionLabel: 'Retry change',
            onAction: () => _perform(context, controller.retryLastEdit),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        InfoBanner(
          icon: AppIcons.reminders,
          tone: AppColors.info,
          title: env.canRequest
              ? 'Allow reminders on this device'
              : env.blocked
              ? 'Notifications are blocked'
              : '${report.accepted} of ${report.requested} accepted by the system',
          message: env.canRequest
              ? 'Allow notifications to receive reminders. Tracking works either way.'
              : env.blocked
              ? 'Your reminder choices are saved. Allow notifications in system settings, then return here.'
              : 'Acceptance does not confirm delivery. Android may delay or hide reminders.'
                    '${report.approximate ? ' Timing is approximate: exact alarms are unavailable.' : ''}',
          actionLabel: env.canRequest
              ? 'Allow notifications'
              : env.blocked && env.canOpenSystemSettings
              ? 'Open system settings'
              : 'Send a test notification',
          onAction: env.canRequest
              ? () => _perform(context, controller.requestPermission)
              : env.blocked && env.canOpenSystemSettings
              ? () async {
                  final opened = await controller.openSystemSettings();
                  if (!opened && context.mounted) {
                    showAppToast(
                      context,
                      message:
                          'Open your device settings, then CycleCare notifications.',
                      kind: ToastKind.info,
                    );
                  }
                }
              : onTest,
        ),
        for (final failure in report.failures) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${failure.reminderTitle}: ${failure.reason}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (report.skipped.isNotEmpty)
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            title: Text('${report.skipped.length} not scheduled · details'),
            children: [
              for (final skip in report.skipped)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '${skip.reminderTitle}: ${skip.reason}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        if (report.hasFailures)
          TextButton(
            onPressed: () => _perform(context, controller.refreshSchedule),
            child: const Text('Retry scheduling'),
          ),
        if (env.canOpenSystemSettings && !env.blocked)
          TextButton(
            onPressed: () => controller.openSystemSettings(),
            child: const Text('Open system settings'),
          ),
      ],
    );
  }
}

/// How many reminders are on — the one surface that leads this screen.
///
/// The count gets the page's largest type because "how many of these are
/// actually going to fire" is the question the screen exists to answer, and a
/// number read at a glance answers it faster than a sentence. It is the only
/// lifted surface here; everything below is a flat grouped list, so the
/// figure-to-ground split does the work a second elevated card would undo.
///
/// "Two of six are on" is a count, not a promise. The second line says what
/// that does and does not mean rather than implying delivery.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.active, required this.total});

  final int active;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final none = active == 0;
    final headline = none
        ? 'All reminders are off'
        : active == 1
        ? '1 reminder is on'
        : '$active reminders are on';
    final detail = none ? 'Switch one on below.' : '$active of $total enabled';

    // The count carries its own tone, but the icon and the sentence both say
    // the same thing, so nothing here depends on reading the colour.
    final tone = none ? context.mutedColor : context.accentColor;

    return MergeSemantics(
      child: AppCard(
        emphasis: CardEmphasis.floating,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: AppSpacing.huge + AppSpacing.md,
                height: AppSpacing.huge + AppSpacing.md,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: context.isDark ? 0.20 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: none
                    ? Icon(
                        Icons.notifications_off_rounded,
                        size: AppSpacing.xxl,
                        color: tone,
                      )
                    : AnimatedCount(
                        value: active,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: tone,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: context.inkColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    detail,
                    style: text.bodySmall?.copyWith(color: context.mutedColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section label, announced as a heading so a screen reader can jump between
/// groups instead of reading the page end to end.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: SectionHeader(
          title: title,
          subtitle: subtitle,
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            right: AppSpacing.xs,
            bottom: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// One reminder, as a row in a grouped list.
///
/// The row owns no border and no shadow — the group around it provides both.
/// What makes it legible instead is alignment: every row's icon sits in the
/// same column, every title starts at the same inset, and the timing controls
/// are indented to that inset too, so the whole list has one left edge rather
/// than six.
class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final controller = ref.read(remindersControllerProvider.notifier);
    final tone = _toneFor(reminder.type);
    final enabled = reminder.enabled;
    final stacked = _textScaleOf(context) > 1.3;

    final marker = Container(
      width: _markerSize,
      height: _markerSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (enabled ? tone : context.subtleColor).withValues(
          alpha: context.isDark ? 0.24 : 0.12,
        ),
        borderRadius: BorderRadius.circular(AppRadii.compact),
      ),
      child: Icon(
        _iconFor(reminder.type),
        size: AppSpacing.xl,
        color: enabled ? tone : context.subtleColor,
      ),
    );

    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reminder.title,
          style: text.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            // Dimmer when off, but the state is also spelled out below — colour
            // alone never carries it.
            color: enabled ? context.inkColor : context.mutedColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          reminder.body,
          style: text.bodySmall?.copyWith(color: context.mutedColor),
        ),
      ],
    );

    final toggle = Switch.adaptive(
      value: enabled,
      onChanged: (value) async {
        Haptics.selection();
        if (!await _perform(
          context,
          () => controller.setEnabled(reminder.id, value),
        )) {
          return;
        }
        if (!context.mounted) return;
        showAppToast(
          context,
          message: value
              ? '${reminder.title} is on'
              : '${reminder.title} is off',
          kind: value ? ToastKind.success : ToastKind.info,
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Merged so the switch is announced with its title and description
          // instead of as a bare "on/off" control.
          MergeSemantics(
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(child: marker),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: labels),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          toggle,
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              enabled ? 'On' : 'Off',
                              style: text.labelLarge?.copyWith(
                                color: context.inkColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(child: marker),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: labels),
                      const SizedBox(width: AppSpacing.sm),
                      toggle,
                    ],
                  ),
          ),

          // Timing controls only exist while the reminder is on. When it is off
          // the space is used to say so, and to say what turning it on does —
          // configuring something that will not fire is busywork, and a blank
          // gap explains nothing.
          AnimatedSize(
            duration: motion(AppDurations.normal),
            curve: AppCurves.inOut,
            alignment: Alignment.topCenter,
            child: Padding(
              // Hangs off the title's left edge rather than the card's, so the
              // controls read as belonging to this row. At large text sizes the
              // indent is dropped — the row has already stacked, and keeping it
              // would leave the time picker in a column too narrow to read.
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                left: stacked ? 0 : _rowTextInset - AppSpacing.lg,
              ),
              child: enabled
                  ? _ReminderControls(reminder: reminder, stacked: stacked)
                  : _OffNote(type: reminder.type),
            ),
          ),
          if (reminder.type == ReminderType.customReminder)
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _openCustomSheet(context, ref, reminder: reminder),
                  icon: const Icon(AppIcons.sliders),
                  label: const Text('Edit reminder'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref, reminder),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete reminder'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The off state, in words.
///
/// A greyed-out row tells a sighted user "probably off" and tells a screen
/// reader nothing at all. This says what is not happening and what to do.
class _OffNote extends StatelessWidget {
  const _OffNote({required this.type});

  final ReminderType type;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final what = _supportsLeadTime(type) ? 'time and notice period' : 'time';

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.notifications_paused_rounded,
              size: AppSpacing.lg,
              color: context.subtleColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Off, so nothing will be sent. Switch it on to set the $what.',
              style: text.bodySmall?.copyWith(color: context.mutedColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Time, notice period, and delete for one reminder.
///
/// Laid out from the width the row actually has rather than the screen's, so it
/// holds inside a card on a 320dp phone and inside a bounded column on a tablet.
class _ReminderControls extends ConsumerWidget {
  const _ReminderControls({required this.reminder, required this.stacked});

  final Reminder reminder;
  final bool stacked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadTime = _supportsLeadTime(reminder.type);

    final time = _TimingTile(
      icon: Icons.schedule_rounded,
      label: 'Time',
      value: _formatTime(context, reminder.hour, reminder.minute),
      semanticLabel: '${reminder.title} time',
      semanticHint: 'Change the time',
      onTap: () => _pickTime(context, ref, reminder),
    );

    final notice = leadTime
        ? _TimingTile(
            icon: Icons.event_rounded,
            label: 'Notice',
            value: _noticeLabel(reminder.daysBefore),
            semanticLabel: '${reminder.title} notice period',
            semanticHint: 'Change how far ahead this arrives',
            onTap: () => _pickLeadTime(context, ref, reminder),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tiles = notice == null ? 1 : 2;
        final scale = _textScaleOf(context);
        final needed =
            _minTimingTileWidth * scale * tiles + AppSpacing.sm * (tiles - 1);
        final stack = stacked || constraints.maxWidth < needed;

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              time,
              if (notice != null) ...[
                const SizedBox(height: AppSpacing.sm),
                notice,
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: time),
            if (notice != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: notice),
            ],
          ],
        );
      },
    );
  }
}

/// A labelled value that opens a picker. The label is what the control sets,
/// the value is what it is set to now, and both are announced.
class _TimingTile extends StatelessWidget {
  const _TimingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.semanticLabel,
    required this.semanticHint,
    this.trailingLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final String semanticLabel;
  final String semanticHint;

  /// Optional affordance word, for the one place this shape is the only control
  /// on its row.
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadii.control);

    return Pressable(
      onTap: onTap,
      scale: 0.97,
      semanticLabel: semanticLabel,
      semanticValue: value,
      semanticHint: semanticHint,
      excludeChildSemantics: true,
      borderRadius: radius,
      minimumSize: const Size(0, AppLayout.minTouchTarget),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.isDark
              ? Colors.black.withValues(alpha: 0.20)
              : context.accentColor.withValues(alpha: 0.06),
          borderRadius: radius,
          border: Border.all(
            color: context.lineColor.withValues(
              alpha: context.isDark ? 0.72 : 0.62,
            ),
            width: AppStrokes.hairline,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSpacing.lg, color: context.mutedColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.labelSmall?.copyWith(color: context.mutedColor),
                  ),
                  Text(
                    value,
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: context.inkColor,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  trailingLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Actions ─────────────────────────────────────────────────────────────────

Future<bool> _perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (_) {
    if (context.mounted) {
      showAppToast(
        context,
        message: 'Could not complete that change. Please try again.',
        kind: ToastKind.warning,
      );
    }
    return false;
  }
}

Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
  try {
    final report = await ref
        .read(remindersControllerProvider.notifier)
        .sendTestNotification();
    if (!context.mounted) return;
    showAppToast(
      context,
      message: report.handedToSystem
          ? 'Test accepted by the system. Check whether it appears.'
          : report.failureReason ?? 'The test was not accepted. Try again.',
      kind: report.handedToSystem ? ToastKind.info : ToastKind.warning,
    );
  } catch (_) {
    if (context.mounted) {
      showAppToast(
        context,
        message: 'Could not send a test. Check system settings and retry.',
        kind: ToastKind.warning,
      );
    }
  }
}

Future<void> _pickTime(
  BuildContext context,
  WidgetRef ref,
  Reminder reminder,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    helpText: reminder.title,
  );
  if (picked == null || !context.mounted) return;

  if (!await _perform(
    context,
    () => ref
        .read(remindersControllerProvider.notifier)
        .setTime(reminder.id, picked.hour, picked.minute),
  )) {
    return;
  }

  if (!context.mounted) return;
  showAppToast(
    context,
    message: 'Set to ${_formatTime(context, picked.hour, picked.minute)}',
  );
}

Future<void> _pickLeadTime(
  BuildContext context,
  WidgetRef ref,
  Reminder reminder,
) async {
  final choice = await showAppSheet<int>(
    context: context,
    title: 'How much notice?',
    child: _LeadTimeOptions(current: reminder.daysBefore ?? 0),
  );
  if (choice == null || !context.mounted) return;

  if (!await _perform(
    context,
    () => ref
        .read(remindersControllerProvider.notifier)
        .setDaysBefore(reminder.id, choice),
  )) {
    return;
  }

  if (!context.mounted) return;
  showAppToast(
    context,
    message: 'Notice set to ${_noticeLabel(choice).toLowerCase()}',
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Reminder reminder,
) async {
  final confirmed = await confirmAction(
    context,
    title: 'Delete this reminder?',
    message: '${reminder.title} will stop sending notifications.',
  );
  if (!confirmed || !context.mounted) return;

  if (!await _perform(
    context,
    () => ref.read(remindersControllerProvider.notifier).remove(reminder.id),
  )) {
    return;
  }
  if (!context.mounted) return;
  showAppToast(context, message: 'Reminder deleted', kind: ToastKind.info);
}

class _LeadTimeOptions extends StatelessWidget {
  const _LeadTimeOptions({required this.current});

  final int current;

  static const _choices = <int>[0, 1, 2, 3, 5, 7];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How far ahead of the estimated date should this arrive?',
          style: text.bodyMedium?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final days in _choices)
              SelectableChip(
                label: _noticeLabel(days),
                selected: current == days,
                onSelected: (_) => Navigator.of(context).pop(days),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Custom reminder sheet ───────────────────────────────────────────────────

Future<void> _openCustomSheet(
  BuildContext context,
  WidgetRef ref, {
  Reminder? reminder,
}) async {
  final created = await showAppSheet<bool>(
    context: context,
    title: reminder == null ? 'New reminder' : 'Edit reminder',
    child: _CustomReminderForm(reminder: reminder),
  );
  if (created == true && context.mounted) {
    showAppToast(
      context,
      message: reminder == null ? 'Reminder created' : 'Reminder updated',
    );
  }
}

class _CustomReminderForm extends ConsumerStatefulWidget {
  const _CustomReminderForm({this.reminder});
  final Reminder? reminder;

  @override
  ConsumerState<_CustomReminderForm> createState() =>
      _CustomReminderFormState();
}

class _CustomReminderFormState extends ConsumerState<_CustomReminderForm> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder != null) {
      _titleController.text = reminder.title;
      _bodyController.text = reminder.body;
      _time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    }
  }

  static const _presets = <({String title, String body})>[
    (title: 'Take your pill', body: 'Time for your daily pill.'),
    (title: 'Drink water', body: 'A glass of water now would help.'),
    (title: 'Log your day', body: 'A quick check-in keeps predictions sharp.'),
    (title: 'Take supplements', body: 'Time for your supplements.'),
    (title: 'Stretch', body: 'A few minutes of movement.'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppToast(
        context,
        message: 'Give the reminder a name first',
        kind: ToastKind.warning,
      );
      return;
    }

    setState(() => _saving = true);
    final saved = await _perform(context, () async {
      final controller = ref.read(remindersControllerProvider.notifier);
      final body = _bodyController.text.trim().isEmpty
          ? 'Reminder from CycleCare'
          : _bodyController.text.trim();
      if (widget.reminder case final reminder?) {
        await controller.updateReminder(
          reminder.copyWith(
            title: title,
            body: body,
            hour: _time.hour,
            minute: _time.minute,
          ),
        );
      } else {
        await controller.addCustom(
          title: title,
          body: body,
          hour: _time.hour,
          minute: _time.minute,
        );
      }
    });
    if (!saved) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Start from one of these, or write your own.',
          style: text.bodySmall?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final preset in _presets)
              SelectableChip(
                label: preset.title,
                selected: _titleController.text.trim() == preset.title,
                onSelected: (_) => setState(() {
                  _titleController.text = preset.title;
                  _bodyController.text = preset.body;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Reminder name',
            hintText: 'Take your pill',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _bodyController,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Optional',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _TimingTile(
          icon: Icons.schedule_rounded,
          label: 'Repeats every day at',
          value: _formatTime(context, _time.hour, _time.minute),
          semanticLabel: 'Reminder time, every day',
          semanticHint: 'Change the time',
          trailingLabel: 'Change',
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _time,
            );
            if (picked != null && mounted) setState(() => _time = picked);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: widget.reminder == null ? 'Create reminder' : 'Save reminder',
          icon: Icons.add_alert_rounded,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Reminders anchored to a predicted date can be sent ahead of it. A daily
/// reminder cannot — "two days before every day" is meaningless.
bool _supportsLeadTime(ReminderType type) => switch (type) {
  ReminderType.periodReminder ||
  ReminderType.ovulationReminder ||
  ReminderType.fertileWindowReminder => true,
  ReminderType.dailyLogReminder ||
  ReminderType.pillReminder ||
  ReminderType.customReminder => false,
};

/// Resolved through the shared registry rather than picked here. This screen
/// used its own glyph for ovulation and the fertile window, so the same two
/// concepts were drawn one way on the home screen and another way here — which
/// is precisely the inconsistency `app_icons.dart` exists to prevent.
IconData _iconFor(ReminderType type) => switch (type) {
  ReminderType.periodReminder => AppIcons.period,
  ReminderType.ovulationReminder => AppIcons.ovulation,
  ReminderType.fertileWindowReminder => AppIcons.fertile,
  ReminderType.dailyLogReminder => AppIcons.notes,
  ReminderType.pillReminder => AppIcons.pill,
  ReminderType.customReminder => AppIcons.reminders,
};

Color _toneFor(ReminderType type) => switch (type) {
  ReminderType.periodReminder => AppColors.period,
  ReminderType.ovulationReminder => AppColors.ovulation,
  ReminderType.fertileWindowReminder => AppColors.fertile,
  ReminderType.dailyLogReminder => AppColors.info,
  ReminderType.pillReminder => AppColors.luteal,
  ReminderType.customReminder => AppColors.success,
};

/// Follows the device's 12/24-hour setting rather than hardcoding AM and PM.
String _formatTime(BuildContext context, int hour, int minute) =>
    TimeOfDay(hour: hour, minute: minute).format(context);

String _noticeLabel(int? daysBefore) {
  final days = daysBefore ?? 0;
  if (days <= 0) return 'Same day';
  return days == 1 ? '1 day before' : '$days days before';
}
