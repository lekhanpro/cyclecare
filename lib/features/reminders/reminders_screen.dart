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
// ─────────────────────────────────────────────────────────────────────────────

/// Font size used to probe the current text scale. Dense rows swap to a stacked
/// variant instead of clipping a time or hiding a control.
const double _textScaleProbe = 14;

double _textScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(_textScaleProbe) / _textScaleProbe;

/// Narrowest a timing control can get before its value starts wrapping into an
/// unreadable column. Scaled by text size, so 200% type always stacks.
const double _minTimingTileWidth = 132;

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  emoji: '🔔',
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
            message: 'Nothing was lost — your reminders stay on this device. '
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

    return _PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            offsetY: AppSpacing.md,
            child: _StatusCard(active: active, total: reminders.length),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Reveal(
            index: 1,
            offsetY: AppSpacing.md,
            child: _SectionTitle(
              title: 'Your reminders',
              subtitle: 'Only the ones switched on are scheduled',
            ),
          ),
          for (var i = 0; i < reminders.length; i++)
            Reveal(
              index: (i + 2).clamp(0, 7),
              offsetY: AppSpacing.md,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ReminderCard(reminder: reminders[i]),
              ),
            ),

          // A labelled button rather than a small "Add" link beside the section
          // title: at 200% text a link in a header row is the first thing to get
          // squeezed out, and this is the only way to create a reminder.
          Reveal(
            index: 7,
            offsetY: AppSpacing.md,
            child: PrimaryButton(
              label: 'Add a reminder',
              icon: Icons.add_alert_rounded,
              outlined: true,
              onPressed: () => _openCustomSheet(context, ref),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Reveal(
            index: 8,
            offsetY: AppSpacing.md,
            child: InfoBanner(
              icon: Icons.info_rounded,
              tone: AppColors.info,
              title: 'If a reminder never arrives',
              message: 'CycleCare schedules reminders on this device, so '
                  'Android has the final say on whether they appear. Open '
                  'Settings, then Apps, then CycleCare, then Notifications, '
                  'and allow them. In Battery, choose unrestricted so the app '
                  'can wake up on time. A test is the only way to see what '
                  'actually arrives.',
              actionLabel: 'Send a test notification',
              onAction: () => _sendTest(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

/// How many reminders are on, and what that means in words.
///
/// "Two of six are on" is a count, not a promise, so the second line names who
/// actually controls delivery instead of implying the app does.
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
            ? '1 of $total reminders is on'
            : '$active of $total reminders are on';
    final detail = none
        ? 'Nothing will be sent until you switch one on below.'
        : 'Scheduled on this device. Android decides whether they appear.';

    return MergeSemantics(
      child: AppCard(
        emphasis: CardEmphasis.tinted,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                none
                    ? Icons.notifications_off_rounded
                    : Icons.notifications_active_rounded,
                size: AppSpacing.xl,
                color: none ? context.mutedColor : context.accentColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: text.titleSmall?.copyWith(
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

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.reminder});

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
      width: AppSpacing.huge,
      height: AppSpacing.huge,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (enabled ? tone : context.subtleColor)
            .withOpacity(context.isDark ? 0.24 : 0.12),
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
        await controller.setEnabled(reminder.id, value);
        if (!context.mounted) return;
        showAppToast(
          context,
          message:
              value ? '${reminder.title} is on' : '${reminder.title} is off',
          kind: value ? ToastKind.success : ToastKind.info,
        );
      },
    );

    return AppCard(
      padding: AppInsets.compactCard,
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
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: enabled
                  ? _ReminderControls(reminder: reminder, stacked: stacked)
                  : _OffNote(type: reminder.type),
            ),
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
    final deletable = reminder.type == ReminderType.customReminder;

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
        final needed = _minTimingTileWidth * scale * tiles +
            AppSpacing.sm * (tiles - 1) +
            (deletable ? AppLayout.minTouchTarget + AppSpacing.sm : 0);
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
              if (deletable) ...[
                const SizedBox(height: AppSpacing.sm),
                _DeleteControl(
                  reminder: reminder,
                  compact: false,
                ),
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
            if (deletable) ...[
              const SizedBox(width: AppSpacing.sm),
              _DeleteControl(reminder: reminder, compact: true),
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
              ? Colors.black.withOpacity(0.20)
              : context.accentColor.withOpacity(0.06),
          borderRadius: radius,
          border: Border.all(
            color: context.lineColor.withOpacity(context.isDark ? 0.72 : 0.62),
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

/// Delete, as a square beside the timing controls when there is room and as a
/// labelled row when there is not. Icon-only never means unlabelled — the
/// reminder's name is in the semantics either way.
class _DeleteControl extends ConsumerWidget {
  const _DeleteControl({required this.reminder, required this.compact});

  final Reminder reminder;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadii.control);

    final icon = Icon(
      Icons.delete_outline_rounded,
      size: AppSpacing.xl,
      color: context.mutedColor,
    );

    return Pressable(
      onTap: () => _confirmDelete(context, ref, reminder),
      scale: 0.94,
      semanticLabel: 'Delete ${reminder.title}',
      semanticHint: 'Asks you to confirm first',
      excludeChildSemantics: true,
      borderRadius: radius,
      minimumSize: const Size.square(AppLayout.minTouchTarget),
      child: Container(
        height: AppLayout.minTouchTarget,
        alignment: Alignment.center,
        padding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.lineColor.withOpacity(context.isDark ? 0.40 : 0.45),
          borderRadius: radius,
        ),
        child: compact
            ? icon
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'Delete this reminder',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        color: context.mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Actions ─────────────────────────────────────────────────────────────────

Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
  await ref.read(remindersControllerProvider.notifier).sendTestNotification();
  if (!context.mounted) return;
  showAppToast(
    context,
    message: 'Test sent. If nothing appears, Android is blocking CycleCare.',
    kind: ToastKind.info,
  );
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
  if (picked == null) return;

  await ref
      .read(remindersControllerProvider.notifier)
      .setTime(reminder.id, picked.hour, picked.minute);

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
  if (choice == null) return;

  await ref
      .read(remindersControllerProvider.notifier)
      .setDaysBefore(reminder.id, choice);

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
  if (!confirmed) return;

  await ref.read(remindersControllerProvider.notifier).remove(reminder.id);
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

Future<void> _openCustomSheet(BuildContext context, WidgetRef ref) async {
  final created = await showAppSheet<bool>(
    context: context,
    title: 'New reminder',
    child: const _CustomReminderForm(),
  );
  if (created == true && context.mounted) {
    showAppToast(context, message: 'Reminder created');
  }
}

class _CustomReminderForm extends ConsumerStatefulWidget {
  const _CustomReminderForm();

  @override
  ConsumerState<_CustomReminderForm> createState() =>
      _CustomReminderFormState();
}

class _CustomReminderFormState extends ConsumerState<_CustomReminderForm> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;

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
    await ref.read(remindersControllerProvider.notifier).addCustom(
          title: title,
          body: _bodyController.text.trim().isEmpty
              ? 'Reminder from CycleCare'
              : _bodyController.text.trim(),
          hour: _time.hour,
          minute: _time.minute,
        );

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
            if (picked != null) setState(() => _time = picked);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Create reminder',
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
      ReminderType.fertileWindowReminder =>
        true,
      ReminderType.dailyLogReminder ||
      ReminderType.pillReminder ||
      ReminderType.customReminder =>
        false,
    };

IconData _iconFor(ReminderType type) => switch (type) {
      ReminderType.periodReminder => Icons.water_drop_rounded,
      ReminderType.ovulationReminder => Icons.egg_alt_rounded,
      ReminderType.fertileWindowReminder => Icons.spa_rounded,
      ReminderType.dailyLogReminder => Icons.edit_note_rounded,
      ReminderType.pillReminder => Icons.medication_rounded,
      ReminderType.customReminder => Icons.notifications_rounded,
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
