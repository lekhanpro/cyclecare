import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/haptics.dart';
import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/widgets.dart';
import '../application/custom_tags_controller.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_models.dart';
import '../domain/cycle_phase_model.dart';
import '../domain/daily_log_validator.dart';
import '../domain/logging_catalog.dart';
import 'log_fields.dart';
import 'log_tiles.dart';
import 'record_summary_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily log ("A moment for you.")
//
// The whole form is rendered from LoggingCatalog: twelve accordion groups,
// each field drawn by its LogFieldKind and read and written only through its
// binding. The screen keeps one draft DailyLog; saving hands that draft to
// the controller, which validates it. Nothing is clamped: an out-of-range
// number stays as typed, the validator's message shows under it, and saving
// waits until it fits.
//
// Unlogged is never zero. An untouched field stays null in the draft, shows
// "Not logged", and is not counted in "N things recorded".
// ─────────────────────────────────────────────────────────────────────────────

/// Calendar-safe day arithmetic across daylight-saving boundaries.
DateTime _shiftDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  /// The groups open on first visit, matching the design. The set is state,
  /// so it survives rebuilds, saves and day changes.
  final _open = <String>{'flow', 'mood'};

  /// Fields whose "See all N choices" is expanded.
  final _showAll = <String>{};

  BuildContext? findGroupContext(String id) {
    BuildContext? found;
    void visit(Element element) {
      if (element.widget.key == ValueKey('log-group-$id')) {
        found = element;
      } else if (found == null) {
        element.visitChildren(visit);
      }
    }

    (context as Element).visitChildren(visit);
    return found;
  }

  /// Number fields keep the text as typed, so "36." or an out-of-range value
  /// is never rewritten under the cursor.
  final _numberText = <String, String>{};

  /// Number text that is not a usable value yet. Blocks saving.
  final _parseErrors = <String, String>{};

  DailyLog? _draft;
  DailyLog? _stored;
  DateTime? _loadedDate;

  /// Bumped on every hydrate so text inputs re-read the draft.
  int _generation = 0;

  bool _dirty = false;
  bool _saving = false;
  bool _deleting = false;
  bool _saveFailed = false;
  bool _confirmingExit = false;

  bool get _busy => _saving || _deleting;

  DateTime get _today => dateOnly(DateTime.now());

  void _hydrate(CycleTrackerState data) {
    final selected = dateOnly(data.selectedDate);
    if (_loadedDate == selected && _draft != null) return;
    _loadedDate = selected;
    _stored = data.logFor(selected);
    _draft = _stored ?? DailyLog(date: selected);
    _numberText.clear();
    _parseErrors.clear();
    _showAll.clear();
    _dirty = false;
    _saveFailed = false;
    _generation++;
  }

  void _update(DailyLog next) {
    setState(() {
      _draft = next;
      _dirty = true;
    });
  }

  void _onNumberChanged(LogField field, String text) {
    final binding = field.binding;
    final draft = _draft!;
    _numberText[field.id] = text;
    final trimmed = text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) {
      _parseErrors.remove(field.id);
      _update(binding.clear(draft));
      return;
    }
    final value = num.tryParse(trimmed);
    if (value == null) {
      _parseErrors[field.id] = 'Enter a number, like ${_example(field)}.';
      _update(binding.clear(draft));
      return;
    }
    try {
      final next = binding.write(draft, value);
      _parseErrors.remove(field.id);
      _update(next);
    } on ArgumentError {
      _parseErrors[field.id] = 'Enter a whole number.';
      _update(binding.clear(draft));
    }
  }

  String _example(LogField field) => switch (field.id) {
    'temperatureCelsius' => '36.5',
    'weightKg' => '62.5',
    'heightCm' => '165',
    'sleepHours' => '7.5',
    _ => '${field.min ?? 0}',
  };

  Map<String, String> _errors() {
    final draft = _draft;
    final errors = <String, String>{};
    if (draft != null) {
      for (final issue in DailyLogValidator.validate(draft)) {
        errors.putIfAbsent(issue.field, () => _sentence(issue.message));
      }
    }
    errors.addAll(_parseErrors);
    return errors;
  }

  static String _sentence(String message) =>
      '${message[0].toUpperCase()}${message.substring(1)}.';

  LogGroup? _groupOf(String fieldId) {
    for (final group in LoggingCatalog.groups) {
      if (group.fields.any((field) => field.id == fieldId)) return group;
    }
    return null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleTrackerControllerProvider);
    final library = ref.watch(customTagsProvider);
    final data = state.valueOrNull;
    if (data != null) _hydrate(data);
    final ready = data != null && _draft != null;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _guardLeave();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: state.when(
            loading: () => _padded(const [
              SizedBox(height: AppSpacing.xxl),
              SkeletonListRows(count: 6, semanticLabel: 'Loading your log'),
            ]),
            error: (_, __) => _padded([
              const SizedBox(height: AppSpacing.xxl),
              EmptyStateView(
                icon: AppIcons.warning,
                title: 'Could not open your log',
                message: 'Nothing was changed. Try again in a moment.',
                actionLabel: 'Try again',
                actionIcon: AppIcons.undo,
                onAction: () => ref.invalidate(cycleTrackerControllerProvider),
              ),
            ]),
            data: (value) => _saveFailed
                ? _saveErrorView(context)
                : _form(context, value, library),
          ),
        ),
        // Docked: a Column sized to its content, never a Center, so the bar
        // cannot claim the whole viewport and blank the form.
        bottomNavigationBar: ready && !_saveFailed
            ? _SaveBar(
                count: _draft!.observationCount,
                dirty: _dirty,
                saving: _saving,
                existing: _stored != null,
                onSave: _busy || !_dirty ? null : _save,
              )
            : null,
      ),
    );
  }

  Widget _padded(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      final side = _sidePadding(constraints.maxWidth);
      return ListView(
        padding: EdgeInsets.fromLTRB(side, AppSpacing.md, side, 40),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: children,
      );
    },
  );

  Widget _form(
    BuildContext context,
    CycleTrackerState data,
    List<String> library,
  ) {
    final draft = _draft!;
    final errors = _errors();
    final selected = _loadedDate!;
    final model = CyclePhaseModel.maybeFromPrediction(
      data.prediction,
      today: selected,
    );
    // The model is anchored on the current cycle; a day outside it gets no
    // badge rather than a clamped, wrong "Day 1".
    final offset = model == null
        ? null
        : selected.difference(model.cycleStart).inDays + 1;
    final cycleDay =
        offset != null && offset >= 1 && offset <= model!.cycleLength
        ? offset
        : null;

    return _padded([
      PageHeader(
        eyebrow: 'A little check-in',
        title: 'A moment for you.',
        titleFontSize: 31,
        bottomSpacing: 17,
        trailing: HeaderIconButton(
          icon: AppIcons.undo,
          semanticLabel: 'Undo unsaved changes',
          onTap: _dirty && !_busy ? _confirmRevert : null,
        ),
      ),
      _DateStepper(
        date: selected,
        today: _today,
        cycleDay: cycleDay,
        hasEntry: _stored != null,
        onPrevious: () => _selectDate(_shiftDays(selected, -1)),
        onNext: selected.isBefore(_today)
            ? () => _selectDate(_shiftDays(selected, 1))
            : null,
        onPick: () => _pickDate(selected),
      ),
      const SizedBox(height: 13),
      Text(
        'Only what you want to share with yourself.',
        style: AppTextStyles.body(
          fontSize: 13,
          height: 1.5,
        ).copyWith(color: context.mutedColor),
      ),
      const SizedBox(height: 10),
      const _Reassurance(),
      Wrap(
        spacing: 8,
        children: [
          for (final item in const [
            ('flow', 'Bleeding'),
            ('pain', 'Pain & activities'),
          ])
            TextButton(
              onPressed: () {
                setState(() => _open.add(item.$1));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final target = findGroupContext(item.$1);
                  if (target != null)
                    Scrollable.ensureVisible(
                      target,
                      duration: Motion.of(context).reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                    );
                });
              },
              child: Text(item.$2),
            ),
        ],
      ),
      const SizedBox(height: 17),
      for (final group in LoggingCatalog.groups) ...[
        _GroupCard(
          key: ValueKey('log-group-${group.id}'),
          group: group,
          count: logGroupCount(group, draft),
          summary: logGroupSummary(group, draft),
          hasError: group.fields.any((field) => errors.containsKey(field.id)),
          open: _open.contains(group.id),
          onToggle: () => setState(() {
            if (!_open.remove(group.id)) _open.add(group.id);
          }),
          panel: () => _panel(group, draft, errors, library),
        ),
        const SizedBox(height: 11),
      ],
      const SizedBox(height: 9),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.wellbeing, size: 15, color: context.accent.text),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'A little detail is enough. You don’t need to fill everything.',
              style: AppTextStyles.body(
                fontSize: 12,
                height: 1.5,
              ).copyWith(color: context.mutedColor),
            ),
          ),
        ],
      ),
      if (_stored != null) ...[
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _busy ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: AccentRoles.dangerText(
                Theme.of(context).brightness,
              ),
            ),
            icon: const Icon(AppIcons.trash, size: 16),
            label: const Text('Delete this day’s entry'),
          ),
        ),
      ],
    ]);
  }

  Widget _panel(
    LogGroup group,
    DailyLog draft,
    Map<String, String> errors,
    List<String> library,
  ) {
    final multiField = group.fields.length > 1;
    final children = <Widget>[
      if (group.id == 'pain')
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: RecordCareGuidance(),
        ),
      if (group.description != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            group.description!,
            style: AppTextStyles.body(
              fontSize: 12,
              height: 1.5,
            ).copyWith(color: context.mutedColor),
          ),
        ),
    ];

    for (final field in group.fields) {
      final key = ValueKey('log-field-${field.id}-$_generation');
      final error = errors[field.id];
      final Widget control = switch (field.kind) {
        LogFieldKind.single ||
        LogFieldKind.multi ||
        LogFieldKind.scale => LogChoiceField(
          key: key,
          field: field,
          log: draft,
          showHeading: multiField || field.kind == LogFieldKind.scale,
          showAll: _showAll.contains(field.id),
          onToggleShowAll: () => setState(() {
            if (!_showAll.remove(field.id)) _showAll.add(field.id);
          }),
          onChanged: _update,
          error: error,
        ),
        LogFieldKind.number => LogNumberField(
          key: key,
          field: field,
          initial: _numberText[field.id] ?? _numberInitial(field, draft),
          onChanged: (text) => _onNumberChanged(field, text),
          error: error,
        ),
        LogFieldKind.text || LogFieldKind.textarea => LogTextField(
          key: key,
          field: field,
          initial: (field.binding.read(draft) as String?) ?? '',
          onChanged: (text) => _update(field.binding.write(_draft!, text)),
          error: error,
        ),
        LogFieldKind.custom => LogCustomTagsField(
          key: key,
          field: field,
          library: library,
          log: draft,
          onChanged: _update,
          onAddToLibrary: (tag) =>
              ref.read(customTagsProvider.notifier).add(tag),
          onRemoveFromLibrary: _removeTag,
        ),
        LogFieldKind.date => const SizedBox.shrink(),
      };
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: control,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 0, 13, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  String _numberInitial(LogField field, DailyLog draft) {
    final value = field.binding.read(draft);
    return value is num ? formatLogNumber(value) : '';
  }

  Widget _saveErrorView(BuildContext context) {
    final draft = _draft!;
    final recorded = [
      for (final group in LoggingCatalog.groups)
        if (logGroupCount(group, draft) > 0)
          (group, logGroupSummary(group, draft)),
    ];
    return _padded([
      PageHeader(
        sectionLabel: 'A little interruption',
        onBack: () => setState(() => _saveFailed = false),
        title: 'Your check-in is still here.',
        subtitle: 'We couldn’t save it just yet.',
      ),
      ErrorRetryView(
        noteTitle: 'Your changes haven’t been saved.',
        noteMessage:
            'Keep this page open and try again. Your choices are '
            'still here, so you don’t need to enter them again.',
        retryLabel: 'Try saving again',
        onRetry: _busy ? null : _save,
        caption: 'We’ll confirm when your record is saved.',
        secondaryLabel: 'Return to my check-in',
        onSecondary: () => setState(() => _saveFailed = false),
        dangerLabel: 'Leave without saving',
        onDanger: _confirmRevert,
        details: recorded.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (group, summary) in recorded)
                    ListRow(
                      icon: AppIcons.named(group.icon),
                      iconColor: logToneFor(context, group.tone).foreground,
                      iconBackground: logToneFor(
                        context,
                        group.tone,
                      ).background,
                      title: group.title,
                      subtitle: summary,
                    ),
                ],
              ),
      ),
    ]);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<bool> _save() async {
    if (_busy || _draft == null) return false;
    final errors = _errors();
    if (errors.isNotEmpty) {
      setState(() {
        for (final id in errors.keys) {
          final group = _groupOf(id);
          if (group != null) _open.add(group.id);
        }
      });
      showAppToast(
        context,
        message: 'One value needs a look before saving. Nothing was lost.',
        kind: ToastKind.warning,
      );
      return false;
    }

    final draft = _draft!.copyWith(date: _loadedDate);
    setState(() => _saving = true);
    try {
      await ref.read(cycleTrackerControllerProvider.notifier).saveLog(draft);
      if (!mounted) return true;
      setState(() {
        _saving = false;
        _dirty = false;
        _saveFailed = false;
        _stored = draft;
      });
      Haptics.commit();
      final count = draft.observationCount;
      showAppToast(
        context,
        message: count == 0
            ? 'Saved. Nothing recorded for this day.'
            : 'Saved · ${_things(count)} recorded',
      );
      return true;
    } on InvalidDailyLogException catch (error) {
      if (!mounted) return false;
      setState(() {
        _saving = false;
        for (final issue in error.issues) {
          final group = _groupOf(issue.field);
          if (group != null) _open.add(group.id);
        }
      });
      showAppToast(
        context,
        message: 'One value needs a look before saving. Nothing was lost.',
        kind: ToastKind.warning,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      // The draft is kept untouched; the saveError view offers a retry.
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
      return false;
    }
  }

  Future<void> _delete() async {
    final stored = _stored;
    final date = _loadedDate;
    if (_busy || stored == null || date == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Delete this entry?',
      message:
          'Everything recorded for ${DateFormat.MMMMd().format(date)} '
          'will be removed from this phone.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    final controller = ref.read(cycleTrackerControllerProvider.notifier);
    try {
      await controller.deleteLog(date);
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _loadedDate = null;
      });
      showAppToast(
        context,
        message: 'Entry deleted',
        kind: ToastKind.info,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await controller.saveLog(stored);
            if (mounted) setState(() => _loadedDate = null);
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showAppToast(
        context,
        message: 'Could not delete this entry. It is still here.',
        kind: ToastKind.error,
      );
    }
  }

  Future<void> _removeTag(String tag) async {
    await ref.read(customTagsProvider.notifier).remove(tag);
    if (!mounted) return;
    showAppToast(
      context,
      message: '“$tag” removed from your list. Days already logged keep it.',
      kind: ToastKind.info,
    );
  }

  void _revert() => setState(() => _loadedDate = null);

  Future<void> _confirmRevert() async {
    final discard = await confirmAction(
      context,
      title: 'Undo your changes?',
      message: 'This day goes back to how it was last saved.',
      confirmLabel: 'Undo changes',
      cancelLabel: 'Keep editing',
    );
    if (discard && mounted) _revert();
  }

  /// Save, discard or stay. Returns true when it is safe to move on.
  Future<bool> _resolveUnsaved() async {
    if (!_dirty) return true;
    if (_saving) {
      showAppToast(
        context,
        message: 'Still saving, one moment.',
        kind: ToastKind.info,
      );
      return false;
    }
    final choice = await showUnsavedChangesDialog(context);
    if (!mounted) return false;
    switch (choice) {
      case UnsavedChangesChoice.save:
        return _save();
      case UnsavedChangesChoice.discard:
        _revert();
        return true;
      case UnsavedChangesChoice.keepEditing:
        return false;
    }
  }

  Future<void> _guardLeave() async {
    if (_confirmingExit) return;
    _confirmingExit = true;
    final leave = await _resolveUnsaved();
    _confirmingExit = false;
    if (!leave || !mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _pickDate(DateTime selected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selected.isAfter(_today) ? _today : selected,
      firstDate: DateTime(_today.year - 5, _today.month, _today.day),
      lastDate: _today,
      helpText: 'Pick a day to check in',
    );
    if (picked == null || !mounted) return;
    await _selectDate(picked);
  }

  Future<void> _selectDate(DateTime date) async {
    final target = dateOnly(date);
    if (target == _loadedDate || target.isAfter(_today)) return;
    if (!await _resolveUnsaved() || !mounted) return;
    await ref.read(cycleTrackerControllerProvider.notifier).selectDate(target);
  }
}

String _things(int count) => count == 1 ? '1 thing' : '$count things';

double _sidePadding(double width) => math.max(
  AppLayout.pageGutterFor(width),
  (width - AppLayout.maxContentWidth) / 2,
);

// ─── Frame ───────────────────────────────────────────────────────────────────

class _DateStepper extends StatelessWidget {
  const _DateStepper({
    required this.date,
    required this.today,
    required this.cycleDay,
    required this.hasEntry,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime date;
  final DateTime today;
  final int? cycleDay;
  final bool hasEntry;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  String get _label {
    final day = DateFormat.MMMMd().format(date);
    if (date == today) return 'Today · $day';
    if (date == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday · $day';
    }
    return DateFormat('EEEE · MMMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final period = PhaseColors.of(context).period;
    final muted = context.mutedColor;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: context.lineColor),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: onPrevious,
            icon: Icon(AppIcons.back, size: 17, color: muted),
          ),
          Expanded(
            child: Semantics(
              button: true,
              label:
                  '$_label${hasEntry ? ', has an entry' : ''}'
                  '${cycleDay == null ? '' : ', cycle day $cycleDay'}',
              hint: 'Pick another day',
              excludeSemantics: true,
              child: InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(AppRadii.compact),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppLayout.minTouchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Icon(AppIcons.calendar, size: 17, color: muted),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ).copyWith(color: context.inkColor),
                          ),
                        ),
                        if (cycleDay != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          ListRowBadge(
                            label: 'Day $cycleDay',
                            color: period.text,
                            background: period.surface,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: onNext == null ? 'No future days' : 'Next day',
            onPressed: onNext,
            icon: Icon(
              AppIcons.forward,
              size: 17,
              color: onNext == null ? context.subtleColor : muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Reassurance extends StatelessWidget {
  const _Reassurance();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body(
      fontSize: 11,
      height: 1.35,
    ).copyWith(color: context.mutedColor);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        // Flexible label: at 360 px with large text the icon and this line
        // together are wider than the row, which overflowed by 5.3 px.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.shield,
                size: 13,
                color: PhaseColors.of(context).follicular.text,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text('Private on your phone', style: style)),
            ],
          ),
        ),
        Text('Every field is optional', style: style),
      ],
    );
  }
}

// ─── Accordion group ─────────────────────────────────────────────────────────

/// One catalogue group: tone-tinted icon tile, title, a summary of what is
/// recorded, a count badge and a chevron. The panel is built only while open
/// and grows from under the anchored header.
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    super.key,
    required this.group,
    required this.count,
    required this.summary,
    required this.hasError,
    required this.open,
    required this.onToggle,
    required this.panel,
  });

  final LogGroup group;
  final int count;
  final String summary;
  final bool hasError;
  final bool open;
  final VoidCallback onToggle;
  final Widget Function() panel;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final tone = logToneFor(context, group.tone);
    final accent = context.accent;
    final danger = AccentRoles.dangerText(Theme.of(context).brightness);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: hasError ? danger : context.lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: open,
            child: Pressable(
              onTap: onToggle,
              scale: 0.99,
              semanticLabel: group.title,
              semanticValue: count == 0
                  ? 'Nothing recorded'
                  : '${_things(count)} recorded: $summary',
              semanticHint: open ? 'Tap to collapse' : 'Tap to expand',
              excludeChildSemantics: true,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: tone.background,
                        borderRadius: BorderRadius.circular(AppRadii.compact),
                      ),
                      child: Icon(
                        AppIcons.named(group.icon),
                        size: 22,
                        color: tone.foreground,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style: AppTextStyles.body(
                              fontSize: 15,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ).copyWith(color: context.inkColor),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            hasError ? 'A value needs a look' : summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(fontSize: 12, height: 1.3)
                                .copyWith(
                                  color: hasError ? danger : context.mutedColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (count > 0)
                      Container(
                        key: ValueKey('log-count-${group.id}'),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.surface,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          '$count',
                          style: AppTextStyles.body(
                            fontSize: 11,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ).copyWith(color: accent.text),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: motion(AppDurations.normal),
                      curve: AppCurves.out,
                      child: Icon(
                        AppIcons.down,
                        size: 15,
                        color: context.mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: motion(AppDurations.normal),
            curve: AppCurves.out,
            alignment: Alignment.topCenter,
            child: open ? panel() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ─── Save bar ────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.count,
    required this.dirty,
    required this.saving,
    required this.existing,
    required this.onSave,
  });

  final int count;
  final bool dirty;
  final bool saving;
  final bool existing;
  final Future<bool> Function()? onSave;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body(
      fontSize: 11,
      height: 1.3,
    ).copyWith(color: context.mutedColor);
    final status = saving
        ? 'Saving…'
        : dirty
        ? 'Unsaved changes'
        : existing
        ? 'Saved on this phone'
        : 'Your daily space';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.canvasColor,
        border: Border(top: BorderSide(color: context.lineColor)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = _sidePadding(constraints.maxWidth);
            return Padding(
              padding: EdgeInsets.fromLTRB(side, AppSpacing.sm, side, 9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: AppSpacing.md,
                      children: [
                        Text(
                          count == 0
                              ? 'Nothing recorded yet'
                              : '${_things(count)} recorded',
                          key: const ValueKey('log-save-count'),
                          style: style,
                        ),
                        Text(status, style: style),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: !dirty && existing ? 'Saved' : 'Save my check-in',
                    icon: AppIcons.check,
                    loading: saving,
                    onPressed: onSave == null ? null : () => onSave!(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
