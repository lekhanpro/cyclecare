import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/haptics.dart';
import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/widgets.dart';
import '../application/cycle_tracker_controller.dart';
import '../application/custom_tags_controller.dart';
import '../domain/cycle_models.dart';
import '../domain/tracking_options.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily log
//
// The screen that determines whether this app gets used past week one. A log
// form is a chore, so the design fights that on four fronts:
//
//  • Date context first. The day being edited is named, navigable by arrow,
//    and shown in a week strip that marks which days already hold an entry.
//    Editing the wrong day is the one mistake this form can't undo for you.
//  • Frequency order. Flow, mood, symptoms and pain are always open, in the
//    order people reach for them. Discharge signs, body metrics and medication
//    collapse behind a summary line — most users touch four sections, not
//    eight, but the ones who want cervical firmness would leave if it were
//    missing.
//  • Progressive disclosure inside the big groups too. Mood and symptoms show
//    the common handful and keep the rest one tap away, so the first screen is
//    a decision rather than an inventory. Anything already selected stays
//    visible whether the group is expanded or not.
//  • Nothing is required, and nothing is lost. Every field is optional and
//    saving never validates, because a form that scolds someone for a partial
//    entry gets one attempt. Leaving a day with unsaved edits asks first.
//
// Discrete taps over sliders throughout: a slider demands precision the user
// does not have about their own body, and it fails badly one-handed.
// ─────────────────────────────────────────────────────────────────────────────

/// Font size used to probe the current text scale. Layouts that cannot survive
/// large type swap to a stacked variant instead of clipping.
const double _textScaleProbe = 14;

double _textScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(_textScaleProbe) / _textScaleProbe;

/// Calendar-safe day arithmetic. Adding `Duration(days: 1)` skips or repeats a
/// day across a daylight-saving boundary.
DateTime _shiftDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  /// How many options a large group shows before "See all". Small enough to
  /// scan in one pass, large enough to cover the common answer.
  static const _moodPreview = 6;
  static const _symptomPreview = 6;

  FlowIntensity _flow = FlowIntensity.none;
  String? _mood;
  String? _discharge;
  String? _cervicalMucus;
  String? _cervicalPosition;
  String? _cervicalFirmness;
  String? _cervicalOpening;
  final _symptoms = <String>{};
  int _painLevel = 0;
  double? _sleepHours;
  int _waterMl = 0;
  bool _medicineTaken = false;

  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicineController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _loadedDate;
  bool _dirty = false;
  bool _saving = false;
  bool _deleting = false;
  bool _showAllMoods = false;
  bool _showAllSymptoms = false;

  /// True while the discard prompt is on screen. A back gesture can fire more
  /// than once before the dialog settles, and two stacked prompts would leave
  /// one of them orphaned behind the other.
  bool _confirmingExit = false;

  /// True while a write is in flight. Gates save, delete, and the app bar
  /// action so a second tap can't queue a duplicate operation.
  bool get _busy => _saving || _deleting;

  DateTime get _firstSelectableDate => _shiftDays(DateTime.now(), -365 * 5);

  DateTime get _lastSelectableDate => _shiftDays(DateTime.now(), 30);

  @override
  void dispose() {
    _temperatureController.dispose();
    _weightController.dispose();
    _medicineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Marks the form dirty on every change so the save button can reflect
  /// whether there is anything to commit.
  void _edit(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
  }

  /// Dirty flag for the free-text fields, which own their own rendering.
  /// Rebuilds only on the clean → dirty edge, so typing doesn't rebuild the
  /// form on every keystroke but the save button still wakes up.
  void _markDirty() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleTrackerControllerProvider);
    final customTags = ref.watch(customTagsProvider);

    // Hydration happens before the Scaffold so the save bar and the app bar
    // see the same dirty state as the form itself, whatever order Flutter
    // builds them in.
    final data = state.valueOrNull;
    if (data != null) _hydrateFromLog(data);
    final selectedDate = data?.selectedDate;
    final existing = data != null && data.logFor(data.selectedDate) != null;

    return PopScope(
      // Leaving is only interrupted while there is something to lose. Once the
      // prompt has been answered the form is clean again, so a second back
      // gesture behaves exactly the way it does everywhere else in the app.
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmDiscardAndLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily log'),
          actions: [
            if (existing && selectedDate != null)
              IconButton(
                tooltip: 'Delete this entry',
                onPressed: _busy ? null : () => _deleteLog(selectedDate),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: state.when(
          loading: () => Center(
            child: Semantics(
              label: 'Loading your log',
              liveRegion: true,
              child: const CircularProgressIndicator(),
            ),
          ),
          // Deliberately not the exception text: it names nothing the user can
          // act on. The retry is the actionable part.
          error: (_, __) => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not open your log',
            message: 'Nothing was changed. Try again in a moment.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(cycleTrackerControllerProvider),
          ),
          data: (value) => _form(context, value, customTags),
        ),
        // Docked rather than floating: in this slot the bar is always
        // reachable, never covers the last field, and rides above the keyboard
        // and the shell's navigation bar without any manual inset arithmetic.
        bottomNavigationBar: data == null || selectedDate == null
            ? null
            : _SaveBar(
                dirty: _dirty,
                enabled: _dirty && !_busy,
                saving: _saving,
                existing: existing,
                onSave: () => _save(selectedDate),
              ),
      ),
    );
  }

  /// The one discard prompt. Switching days and leaving the screen risk the
  /// same work, so they ask the same question in the same words.
  Future<bool> _confirmDiscard() => confirmAction(
        context,
        title: 'Leave without saving?',
        message: 'Your changes to this day have not been saved yet.',
        confirmLabel: 'Discard changes',
        cancelLabel: 'Keep editing',
      );

  /// Runs when a back gesture was refused because the form holds unsaved work.
  ///
  /// Discarding restores the stored values instead of only clearing the dirty
  /// flag: the prompt says "discard changes", so the edits have to actually go,
  /// otherwise the next back press would leave with them still on screen and
  /// the save button greyed out over them.
  Future<void> _confirmDiscardAndLeave() async {
    if (_confirmingExit) return;

    // A write already in flight is not the user's to abandon — it finishes,
    // and the dirty flag clears on its own a moment later.
    if (_saving) {
      showAppToast(
        context,
        message: 'Still saving — one moment.',
        kind: ToastKind.info,
      );
      return;
    }

    _confirmingExit = true;
    final discard = await _confirmDiscard();
    _confirmingExit = false;
    if (!discard || !mounted) return;

    setState(() {
      // Forces a re-hydrate on the next build, which resets every field.
      _loadedDate = null;
      // Cleared here too, so the guard lifts even if the data is momentarily
      // unavailable and hydration has nothing to read.
      _dirty = false;
    });

    // PopScope publishes the lifted guard when it rebuilds, so wait for that
    // frame before asking to leave again.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    // Nothing to pop: the log is the current tab rather than a pushed route,
    // so the screen stays put and has to say what just happened. The guard is
    // down either way, so a second back press does whatever it normally would.
    showAppToast(context, message: 'Changes discarded', kind: ToastKind.info);
  }

  Widget _form(
    BuildContext context,
    CycleTrackerState data,
    List<String> customTags,
  ) {
    final phases = PhaseColors.of(context);
    final periodTone = phases.period.fill;
    final selected = data.selectedDate;
    final previous = _shiftDays(selected, -1);
    final next = _shiftDays(selected, 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.sm,
                gutter,
                AppSpacing.xl,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Reveal(
                  child: _DateHeader(
                    date: selected,
                    hasEntry: data.logFor(selected) != null,
                    dayStatus: data.statusFor(selected),
                    onPick: () => _pickDate(selected),
                    onPrevious: previous.isBefore(_firstSelectableDate)
                        ? null
                        : () => _selectDate(previous),
                    onNext: next.isAfter(_lastSelectableDate)
                        ? null
                        : () => _selectDate(next),
                    statusFor: data.statusFor,
                    hasLogFor: data.hasLogFor,
                    onSelected: _selectDate,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Always open, in the order people reach for them ────────
                Reveal(
                  index: 1,
                  child: _Section(
                    icon: Icons.water_drop_rounded,
                    accent: periodTone,
                    title: 'Flow',
                    detail: _flow == FlowIntensity.none
                        ? 'Pick the closest match for today'
                        : 'Logged as ${_flow.label.toLowerCase()}',
                    child: _ChipGrid(
                      children: [
                        for (final flow in FlowIntensity.values)
                          SelectableChip(
                            label: flow.label,
                            selected: _flow == flow,
                            accent: periodTone,
                            onSelected: (_) => _edit(() => _flow = flow),
                          ),
                      ],
                    ),
                  ),
                ),

                Reveal(
                  index: 2,
                  child: _Section(
                    icon: Icons.mood_rounded,
                    title: 'Mood',
                    detail: _mood ?? 'One word is plenty — the pattern counts',
                    child: _ChipGrid(children: _moodChips()),
                  ),
                ),

                Reveal(
                  index: 3,
                  child: _Section(
                    icon: Icons.healing_rounded,
                    title: 'Symptoms',
                    detail: _symptoms.isEmpty
                        ? 'Tap anything you noticed, however minor'
                        : '${_symptoms.length} selected',
                    child: _ChipGrid(children: _symptomChips(customTags)),
                  ),
                ),

                Reveal(
                  index: 4,
                  child: _Section(
                    icon: Icons.bolt_rounded,
                    accent: periodTone,
                    title: 'Pain',
                    detail: _painLevel == 0
                        ? 'Nothing logged — leave it blank if there was none'
                        : '$_painLevel out of 10',
                    child: SeveritySelector(
                      value: _painLevel,
                      accent: periodTone,
                      onChanged: (value) => _edit(() => _painLevel = value),
                    ),
                  ),
                ),

                // ── Opt-in. Collapsed so the common path stays short ───────
                Reveal(
                  index: 5,
                  child: _CollapsibleSection(
                    // Discreet on the outside, precise on the inside. The
                    // collapsed header is read over someone's shoulder on a
                    // bus; the field labels are only seen once it is opened,
                    // and there they need to be unambiguous.
                    title: 'Fertility signs',
                    subtitle: 'Discharge and cervical notes, if you track them',
                    icon: Icons.opacity_rounded,
                    accent: phases.fertile.fill,
                    summary: _fertilitySummary(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChoiceWrap(
                          label: 'Discharge',
                          values: dischargeOptions,
                          selected: _discharge,
                          onSelected: (value) =>
                              _edit(() => _discharge = value),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ChoiceWrap(
                          label: 'Cervical mucus',
                          values: cervicalMucusOptions,
                          selected: _cervicalMucus,
                          onSelected: (value) =>
                              _edit(() => _cervicalMucus = value),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ChoiceWrap(
                          label: 'Cervical position',
                          values: cervicalPositionOptions,
                          selected: _cervicalPosition,
                          onSelected: (value) =>
                              _edit(() => _cervicalPosition = value),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ChoiceWrap(
                          label: 'Cervical firmness',
                          values: cervicalFirmnessOptions,
                          selected: _cervicalFirmness,
                          onSelected: (value) =>
                              _edit(() => _cervicalFirmness = value),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ChoiceWrap(
                          label: 'Cervical opening',
                          values: cervicalOpeningOptions,
                          selected: _cervicalOpening,
                          onSelected: (value) =>
                              _edit(() => _cervicalOpening = value),
                        ),
                      ],
                    ),
                  ),
                ),

                Reveal(
                  index: 6,
                  child: _CollapsibleSection(
                    title: 'Body and rest',
                    subtitle: 'Temperature, weight, sleep, water',
                    icon: Icons.monitor_heart_rounded,
                    accent: phases.ovulation.fill,
                    summary: _metricsSummary(),
                    child: Column(
                      children: [
                        _FieldPair(
                          first: _NumberField(
                            controller: _temperatureController,
                            label: 'Temp (°C)',
                            hint: '36.60',
                            onChanged: _markDirty,
                          ),
                          second: _NumberField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            hint: '60.0',
                            onChanged: _markDirty,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _StepperRow(
                          label: 'Sleep',
                          value: _sleepHours == null
                              ? '—'
                              : '${_sleepHours!.toStringAsFixed(1)}h',
                          semanticValue: _sleepHours == null
                              ? 'Not set'
                              : '${_sleepHours!.toStringAsFixed(1)} hours',
                          onDecrease: (_sleepHours ?? 0) <= 0
                              ? null
                              : () => _edit(() {
                                    _sleepHours =
                                        ((_sleepHours ?? 0) - 0.5).clamp(0, 16);
                                  }),
                          onIncrease: () => _edit(() {
                            _sleepHours =
                                ((_sleepHours ?? 6.5) + 0.5).clamp(0, 16);
                          }),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StepperRow(
                          label: 'Water',
                          value: _waterMl == 0
                              ? '—'
                              : '${(_waterMl / 250).round()} glasses',
                          caption: _waterMl == 0 ? null : '$_waterMl ml',
                          semanticValue: _waterMl == 0
                              ? 'Not set'
                              : '${(_waterMl / 250).round()} glasses, '
                                  '$_waterMl millilitres',
                          onDecrease: _waterMl <= 0
                              ? null
                              : () => _edit(() => _waterMl -= 250),
                          onIncrease: () => _edit(() => _waterMl += 250),
                        ),
                      ],
                    ),
                  ),
                ),

                Reveal(
                  index: 7,
                  child: _CollapsibleSection(
                    title: 'Medication',
                    subtitle: 'Anything you took today',
                    icon: Icons.medication_rounded,
                    accent: phases.luteal().fill,
                    summary: _medicineSummary(),
                    child: Column(
                      children: [
                        _ToggleRow(
                          label: 'Taken today',
                          value: _medicineTaken,
                          onChanged: (value) =>
                              _edit(() => _medicineTaken = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _medicineController,
                          onChanged: (_) => _markDirty(),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'Optional',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Reveal(
                  index: 8,
                  child: _Section(
                    icon: Icons.edit_note_rounded,
                    title: 'Notes',
                    child: TextField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 6,
                      onChanged: (_) => _markDirty(),
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Anything you want to remember about today?',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Option grids ──────────────────────────────────────────────────────────

  /// Mood chips: the common six, plus whatever is already chosen, plus the
  /// disclosure control. A selection is never hidden behind "See all".
  List<Widget> _moodChips() {
    final chips = <Widget>[];
    var hidden = 0;

    for (var index = 0; index < moodOptions.length; index++) {
      final mood = moodOptions[index];
      final isSelected = _mood == mood;
      if (_showAllMoods || index < _moodPreview || isSelected) {
        chips.add(
          SelectableChip(
            label: mood,
            selected: isSelected,
            onSelected: (selected) =>
                _edit(() => _mood = selected ? mood : null),
          ),
        );
      } else {
        hidden++;
      }
    }

    if (hidden > 0 || _showAllMoods) {
      chips.add(
        _ActionChip(
          label: _showAllMoods ? 'Show fewer' : 'See all ($hidden)',
          semanticLabel: _showAllMoods
              ? 'Show fewer mood options'
              : 'See all mood options, $hidden more',
          icon: _showAllMoods
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded,
          onTap: () => setState(() => _showAllMoods = !_showAllMoods),
        ),
      );
    }

    return chips;
  }

  /// Symptom chips: the common eight, every current selection, and — once
  /// expanded — the full list plus the user's own tags.
  List<Widget> _symptomChips(List<String> customTags) {
    final chips = <Widget>[];
    var hidden = 0;

    for (var index = 0; index < symptomOptions.length; index++) {
      final symptom = symptomOptions[index];
      final isSelected = _symptoms.contains(symptom);
      if (_showAllSymptoms || index < _symptomPreview || isSelected) {
        chips.add(
          SelectableChip(
            label: symptom,
            selected: isSelected,
            onSelected: (selected) => _toggleSymptom(symptom, selected),
          ),
        );
      } else {
        hidden++;
      }
    }

    // User-defined tags sit in the same grid as the built-ins. Segregating
    // them would imply they are second class, and they are usually the ones
    // that matter most to the person who added them.
    for (final tag in customTags) {
      final isSelected = _symptoms.contains(tag);
      if (_showAllSymptoms || isSelected) {
        chips.add(
          SelectableChip(
            label: tag,
            icon: Icons.star_rounded,
            selected: isSelected,
            onSelected: (selected) => _toggleSymptom(tag, selected),
          ),
        );
      } else {
        hidden++;
      }
    }

    // Anything saved on this entry that is no longer in either list — a tag
    // the user deleted, or an older build's wording. Shown so it can still be
    // switched off instead of silently riding along on every save.
    final known = {...symptomOptions, ...customTags};
    for (final orphan in _symptoms.where((tag) => !known.contains(tag)).toList()
      ..sort()) {
      chips.add(
        SelectableChip(
          label: orphan,
          icon: Icons.label_outline_rounded,
          selected: true,
          onSelected: (selected) => _toggleSymptom(orphan, selected),
        ),
      );
    }

    if (hidden > 0 || _showAllSymptoms) {
      chips.add(
        _ActionChip(
          label: _showAllSymptoms ? 'Show fewer' : 'See all ($hidden)',
          semanticLabel: _showAllSymptoms
              ? 'Show fewer symptom options'
              : 'See all symptom options, $hidden more',
          icon: _showAllSymptoms
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded,
          onTap: () => setState(() => _showAllSymptoms = !_showAllSymptoms),
        ),
      );
    }

    chips.add(
      _ActionChip(
        label: 'Add your own',
        semanticLabel: 'Add your own symptom',
        icon: Icons.add_rounded,
        onTap: _addCustomTag,
      ),
    );

    return chips;
  }

  void _toggleSymptom(String symptom, bool selected) {
    _edit(() {
      if (selected) {
        _symptoms.add(symptom);
      } else {
        _symptoms.remove(symptom);
      }
    });
  }

  // ─── Summaries for the collapsed sections ─────────────────────────────────

  String? _fertilitySummary() {
    final parts = [
      if (_discharge != null) _discharge!,
      if (_cervicalMucus != null) _cervicalMucus!,
      if (_cervicalPosition != null) _cervicalPosition!,
      if (_cervicalFirmness != null) _cervicalFirmness!,
      if (_cervicalOpening != null) _cervicalOpening!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? _metricsSummary() {
    final parts = [
      if (_temperatureController.text.trim().isNotEmpty)
        '${_temperatureController.text.trim()}°C',
      if (_weightController.text.trim().isNotEmpty)
        '${_weightController.text.trim()}kg',
      if (_sleepHours != null) '${_sleepHours!.toStringAsFixed(1)}h',
      if (_waterMl > 0) '${_waterMl}ml',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? _medicineSummary() {
    if (!_medicineTaken) return null;
    final name = _medicineController.text.trim();
    return name.isEmpty ? 'Taken' : 'Taken · $name';
  }

  /// Loads the stored log for the selected date into the form.
  ///
  /// Guarded on the date so a rebuild mid-edit can't wipe what the user is
  /// typing. Switching days is the only thing that re-runs it, and that path
  /// asks before discarding unsaved work.
  void _hydrateFromLog(CycleTrackerState data) {
    final selected = dateOnly(data.selectedDate);
    if (_loadedDate == selected) return;
    _loadedDate = selected;
    _dirty = false;
    _showAllMoods = false;
    _showAllSymptoms = false;

    final log = data.logFor(selected);
    _flow = log?.flow ?? FlowIntensity.none;
    _mood = log?.mood;
    _symptoms
      ..clear()
      ..addAll(log?.symptoms ?? const []);
    _painLevel = log?.painLevel ?? 0;
    _discharge = log?.discharge;
    _cervicalMucus = log?.cervicalMucus;
    _cervicalPosition = log?.cervicalPosition;
    _cervicalFirmness = log?.cervicalFirmness;
    _cervicalOpening = log?.cervicalOpening;
    _temperatureController.text =
        log?.temperatureCelsius?.toStringAsFixed(2) ?? '';
    _weightController.text = log?.weightKg?.toStringAsFixed(1) ?? '';
    _sleepHours = log?.sleepHours;
    _waterMl = log?.waterMl ?? 0;
    _medicineTaken = log?.medicineTaken ?? false;
    _medicineController.text = log?.medicineName ?? '';
    _notesController.text = log?.notes ?? '';
  }

  Future<void> _addCustomTag() async {
    final controller = TextEditingController();

    final tag = await showAppSheet<String>(
      context: context,
      title: 'Add your own symptom',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anything the built-in list is missing — it will be saved for '
            'future logs and included in your insights.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.mutedColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Symptom name',
              hintText: 'e.g. Jaw tension',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Add symptom',
            icon: Icons.add_rounded,
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          ),
        ],
      ),
    );

    controller.dispose();
    if (tag == null || tag.isEmpty) return;

    await ref.read(customTagsProvider.notifier).add(tag);
    if (!mounted) return;
    // Selecting it immediately is the only reason someone opened this sheet.
    _toggleSymptom(tag, true);
  }

  Future<void> _pickDate(DateTime selectedDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: _firstSelectableDate,
      lastDate: _lastSelectableDate,
      helpText: 'Pick a day to log',
    );
    if (picked == null || !mounted) return;
    await _selectDate(picked);
  }

  /// Moves the form to another day, confirming first if the current one has
  /// edits that were never saved.
  Future<void> _selectDate(DateTime date) async {
    final target = dateOnly(date);
    if (target == _loadedDate) return;
    if (target.isBefore(_firstSelectableDate) ||
        target.isAfter(_lastSelectableDate)) {
      return;
    }

    if (_dirty) {
      final discard = await _confirmDiscard();
      if (!discard || !mounted) return;
    }

    // Clearing the guard forces a re-hydrate for the newly selected day.
    setState(() => _loadedDate = null);
    await ref.read(cycleTrackerControllerProvider.notifier).selectDate(target);
  }

  Future<void> _save(DateTime selectedDate) async {
    if (_busy) return;
    setState(() => _saving = true);

    try {
      await ref.read(cycleTrackerControllerProvider.notifier).saveLog(
            DailyLog(
              date: selectedDate,
              flow: _flow,
              mood: _mood,
              symptoms: _symptoms.toList()..sort(),
              painLevel: _painLevel,
              discharge: _discharge,
              cervicalMucus: _cervicalMucus,
              cervicalPosition: _cervicalPosition,
              cervicalFirmness: _cervicalFirmness,
              cervicalOpening: _cervicalOpening,
              temperatureCelsius:
                  double.tryParse(_temperatureController.text.trim()),
              weightKg: double.tryParse(_weightController.text.trim()),
              sleepHours: _sleepHours,
              waterMl: _waterMl,
              medicineTaken: _medicineTaken,
              medicineName: _medicineController.text.trim().isEmpty
                  ? null
                  : _medicineController.text.trim(),
              notes: _notesController.text.trim(),
            ),
          );

      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
      });
      showAppToast(context, message: 'Log saved');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(
        context,
        message: 'Could not save this entry. Nothing was lost — try again.',
        kind: ToastKind.error,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _save(selectedDate),
        ),
      );
    }
  }

  Future<void> _deleteLog(DateTime selectedDate) async {
    if (_busy) return;

    final confirmed = await confirmAction(
      context,
      title: 'Delete this entry?',
      message: 'Everything recorded for '
          '${DateFormat.MMMMd().format(selectedDate)} will be removed.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(cycleTrackerControllerProvider.notifier)
          .deleteLog(selectedDate);
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _loadedDate = null;
      });
      showAppToast(context, message: 'Entry deleted', kind: ToastKind.info);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showAppToast(
        context,
        message: 'Could not delete this entry. Try again in a moment.',
        kind: ToastKind.error,
      );
    }
  }
}

// ─── Date context ────────────────────────────────────────────────────────────

/// The day being edited: named, steppable, pickable, and — where the type size
/// allows it — surrounded by its week.
class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.date,
    required this.hasEntry,
    required this.dayStatus,
    required this.onPick,
    required this.onPrevious,
    required this.onNext,
    required this.statusFor,
    required this.hasLogFor,
    required this.onSelected,
  });

  final DateTime date;
  final bool hasEntry;

  /// Where this day sits in the cycle, so the form is answered in context
  /// rather than in a vacuum.
  final DayStatus dayStatus;

  final VoidCallback onPick;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final DayStatus Function(DateTime day) statusFor;
  final bool Function(DateTime day) hasLogFor;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final relative = isSameDate(date, today)
        ? 'Today'
        : isSameDate(date, _shiftDays(today, -1))
            ? 'Yesterday'
            : isSameDate(date, _shiftDays(today, 1))
                ? 'Tomorrow'
                : DateFormat('EEEE').format(date);
    final fullDate = DateFormat.yMMMMd().format(date);
    final entryLabel = hasEntry ? 'Entry saved' : 'No entry yet';
    final cycle = _cycleBadge(context, dayStatus);
    final spokenStatus =
        cycle == null ? entryLabel : '$entryLabel, ${cycle.label}';

    // The strip is a shortcut, not the only way in. At very large type it
    // cannot stay legible inside a 52dp column, so it steps aside and the
    // arrows plus the picker carry the same job.
    final showStrip = _textScaleOf(context) <= 1.3;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous day',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Pressable(
                  onTap: onPick,
                  semanticLabel: '$relative, $fullDate',
                  semanticValue: spokenStatus,
                  semanticHint: 'Change the day you are logging',
                  excludeChildSemantics: true,
                  scale: 0.98,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        Text(
                          relative,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: context.inkColor,
                          ),
                        ),
                        Text(
                          fullDate,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.mutedColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Wrapped rather than a row: at large type the two
                        // pills stack instead of squeezing each other into
                        // ellipses.
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _StatusPill(
                              icon: hasEntry
                                  ? Icons.check_circle_rounded
                                  : Icons.edit_calendar_rounded,
                              label: entryLabel,
                              tone: hasEntry
                                  ? AppColors.success
                                  : context.mutedColor,
                            ),
                            if (cycle != null)
                              _StatusPill(
                                icon: cycle.icon,
                                label: cycle.label,
                                tone: cycle.tone,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next day',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          if (showStrip) ...[
            Divider(height: AppSpacing.lg, color: context.lineColor),
            WeekStrip(
              selectedDate: date,
              statusFor: statusFor,
              hasLogFor: hasLogFor,
              onSelected: onSelected,
            ),
          ],
        ],
      ),
    );
  }
}

/// Where the selected day sits in the cycle, as a label, a glyph and a hue.
///
/// Null on an ordinary day: a pill that says "nothing in particular" is noise.
/// The phase hues come from [PhaseColors] so this badge reads the same as the
/// calendar the user already learned, and the glyph carries the same meaning
/// for anyone who can't use the colour.
({String label, IconData icon, Color tone})? _cycleBadge(
  BuildContext context,
  DayStatus status,
) {
  final phases = PhaseColors.of(context);

  return switch (status) {
    DayStatus.period => (
        label: 'Period day',
        icon: Icons.water_drop_rounded,
        tone: phases.period.fill,
      ),
    DayStatus.predictedPeriod => (
        label: 'Period expected',
        icon: Icons.water_drop_outlined,
        tone: phases.predicted.fill,
      ),
    DayStatus.fertile => (
        label: 'Fertile window',
        icon: Icons.spa_rounded,
        tone: phases.fertile.fill,
      ),
    DayStatus.ovulation => (
        label: 'Ovulation',
        icon: Icons.auto_awesome_rounded,
        tone: phases.ovulation.fill,
      ),
    // "Before period" rather than the clinical acronym: it says the same thing
    // without diagnosing anyone.
    DayStatus.pms => (
        label: 'Before period',
        icon: Icons.nights_stay_rounded,
        tone: phases.luteal().fill,
      ),
    DayStatus.normal => null,
  };
}

/// Small tinted label. The tone only accents the glyph and the fill — the text
/// stays at full contrast so the pill is legible with the colour ignored.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final glyph = dark
        ? Color.lerp(tone, Colors.white, 0.24)!
        : Color.lerp(tone, AppColors.ink, 0.30)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tone.withOpacity(dark ? 0.22 : 0.11),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: tone.withOpacity(dark ? 0.42 : 0.30),
          width: AppStrokes.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: glyph),
          const SizedBox(width: AppSpacing.xs),
          // Flexible so a long label wraps inside the pill instead of pushing
          // past it at large text sizes.
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.inkColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section chrome ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.detail,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Color? accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: icon,
            title: title,
            detail: detail,
            accent: accent,
            isHeader: true,
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Shared heading: icon tile, title, and one supporting line. Used open and
/// collapsed so every group on the screen reads the same way.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    this.detail,
    this.accent,
    this.emphasizeDetail = false,
    this.isHeader = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final Color? accent;

  /// Set when [detail] is real content rather than a prompt, so it reads as
  /// data through weight and colour rather than colour alone.
  final bool emphasizeDetail;

  final bool isHeader;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: context.inkColor,
      ),
    );

    return Row(
      children: [
        _IconTile(icon: icon, tone: accent ?? context.accentColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isHeader)
                Semantics(header: true, child: titleText)
              else
                titleText,
              if (detail != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight:
                        emphasizeDetail ? FontWeight.w800 : FontWeight.w600,
                    color:
                        emphasizeDetail ? context.inkColor : context.mutedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    // The raw phase fills are pretty but several are too light to read as a
    // glyph. Pulled toward the surrounding text colour, the way PhaseColors
    // derives its own text role.
    final glyph = dark
        ? Color.lerp(tone, Colors.white, 0.24)!
        : Color.lerp(tone, AppColors.ink, 0.30)!;

    return Container(
      width: AppSpacing.huge,
      height: AppSpacing.huge,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.withOpacity(dark ? 0.24 : 0.13),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Icon(icon, size: 20, color: glyph),
    );
  }
}

/// Section that starts closed and shows a summary of its contents when it has
/// any, so the user can see what's inside without opening it.
class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.accent,
    this.summary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Color? accent;

  /// Rendered in place of [subtitle] when the section holds data.
  final String? summary;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final hasData = widget.summary != null;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppInsets.compactCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: Semantics(
              header: true,
              child: Pressable(
                onTap: () {
                  Haptics.selection();
                  setState(() => _open = !_open);
                },
                haptic: false,
                semanticLabel: widget.title,
                semanticValue: widget.summary,
                semanticHint: _open ? 'Collapse section' : 'Expand section',
                excludeChildSemantics: true,
                scale: 0.99,
                borderRadius: BorderRadius.circular(AppRadii.control),
                child: _SectionHeading(
                  icon: widget.icon,
                  title: widget.title,
                  accent: widget.accent,
                  detail: widget.summary ?? widget.subtitle,
                  emphasizeDetail: hasData,
                  // Rotates rather than swapping icons, so the control reads
                  // as one object turning instead of two states flickering.
                  trailing: AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: motion(AppDurations.fast),
                    curve: AppCurves.out,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: context.mutedColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: motion(AppDurations.fast),
            curve: AppCurves.out,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ─── Option controls ─────────────────────────────────────────────────────────

/// One wrapping grid of chips, sized to whatever it holds. The animation is
/// what makes "See all" feel like a reveal instead of a page jump.
class _ChipGrid extends StatelessWidget {
  const _ChipGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);

    return AnimatedSize(
      duration: motion(AppDurations.fast),
      curve: AppCurves.out,
      alignment: Alignment.topCenter,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: children,
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: context.mutedColor),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChipGrid(
          children: [
            for (final value in values)
              SelectableChip(
                label: value,
                selected: selected == value,
                onSelected: (isSelected) =>
                    onSelected(isSelected ? value : null),
              ),
          ],
        ),
      ],
    );
  }
}

/// Chip-shaped secondary action — "See all", "Show fewer", "Add your own".
///
/// Shares [SelectableChip]'s geometry so it lines up in the same grid, and
/// lives inside the wrap rather than in the section header: at 200% text it
/// reflows with the options instead of fighting the title for width.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tone = context.accentColor;
    final radius = BorderRadius.circular(AppRadii.pill);

    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel ?? label,
      excludeChildSemantics: true,
      scale: 0.96,
      borderRadius: radius,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppLayout.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: tone.withOpacity(0.55),
            width: AppStrokes.selected,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: tone),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: tone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Metric controls ─────────────────────────────────────────────────────────

/// Two fields side by side, stacked when the width or the type size makes a
/// row unreadable rather than merely tight.
class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final largeText = _textScaleOf(context) > 1.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (largeText || constraints.maxWidth < 260) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppSpacing.md),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.semanticValue,
    required this.onIncrease,
    this.onDecrease,
    this.caption,
  });

  static const double _valueWidth = AppSpacing.huge * 2;

  final String label;
  final String value;

  /// Spelled-out reading for assistive tech: "6.5 hours", not "6.5h".
  final String semanticValue;

  final String? caption;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final largeText = _textScaleOf(context) > 1.2;

    final labelBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.inkColor,
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.mutedColor,
            ),
          ),
      ],
    );

    final valueText = Text(
      value,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w900,
        color: context.inkColor,
      ),
    );

    final decrease = _StepButton(
      icon: Icons.remove_rounded,
      semanticLabel: 'Decrease $label',
      onTap: onDecrease,
    );
    final increase = _StepButton(
      icon: Icons.add_rounded,
      semanticLabel: 'Increase $label',
      onTap: onIncrease,
    );

    return Semantics(
      container: true,
      label: label,
      value: semanticValue,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (largeText || constraints.maxWidth < 260) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelBlock,
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    decrease,
                    Expanded(child: valueText),
                    increase,
                  ],
                ),
              ],
            );
          }

          // Flat row on purpose: every child is either flexible or a fixed
          // width, so nothing can overflow at 320dp.
          return Row(
            children: [
              Expanded(child: labelBlock),
              decrease,
              SizedBox(width: _valueWidth, child: valueText),
              increase,
            ],
          );
        },
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Pressable(
      onTap: enabled
          ? () {
              Haptics.selection();
              onTap!();
            }
          : null,
      haptic: false,
      enabled: enabled,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      scale: 0.88,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Center(
        child: Container(
          width: AppSpacing.huge,
          height: AppSpacing.huge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? context.accentColor.withOpacity(context.isDark ? 0.22 : 0.11)
                : context.lineColor.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? context.accentColor : context.subtleColor,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Merged so the switch is announced with its label instead of as a bare
    // "on/off" control.
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.inkColor,
                  ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (next) {
              Haptics.selection();
              onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      inputFormatters: [
        // Digits and a single decimal point. Prevents "36.6.5" reaching the
        // parser, where it would silently become null and drop the reading.
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

// ─── Save ────────────────────────────────────────────────────────────────────

/// Persistent save affordance. On a form this long, a button at the bottom of
/// the scroll is a button most people never reach.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.dirty,
    required this.enabled,
    required this.saving,
    required this.existing,
    required this.onSave,
  });

  /// Whether anything is waiting to be committed. Separate from [enabled],
  /// which also accounts for a write already being in flight.
  final bool dirty;

  final bool enabled;
  final bool saving;
  final bool existing;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    // Dropped outright at very large type: the button matters more than the
    // commentary, and it has to stay on screen.
    final showNote = (dirty || saving) && _textScaleOf(context) <= 1.5;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(
            color: context.lineColor.withOpacity(context.isDark ? 0.82 : 0.72),
            width: AppStrokes.hairline,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.32 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.md,
                gutter,
                AppSpacing.md,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  // The bar grows into the status line rather than snapping to
                  // a new height under the user's thumb.
                  child: AnimatedSize(
                    duration: motion(AppDurations.fast),
                    curve: AppCurves.out,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Only shown when there is something to say. A resting
                        // bar is one button, and at very large type the line is
                        // dropped entirely rather than pushing the button off
                        // the bottom of the screen.
                        if (showNote)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _PendingChangesNote(saving: saving),
                          ),
                        PrimaryButton(
                          label: !enabled && existing
                              ? 'Saved'
                              : existing
                                  ? 'Update log'
                                  : 'Save log',
                          icon: Icons.check_rounded,
                          loading: saving,
                          onPressed: enabled ? onSave : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One line above the save button, for the two moments the bar has something
/// to say: work is pending, or work is being written.
///
/// Announced on appearance rather than left as decoration — unsaved state is
/// the only thing on this screen that can actually be lost, so it should not
/// depend on noticing a colour change at the bottom of the viewport.
class _PendingChangesNote extends StatelessWidget {
  const _PendingChangesNote({required this.saving});

  final bool saving;

  @override
  Widget build(BuildContext context) {
    final label = saving ? 'Saving your changes' : 'Unsaved changes';
    final tone = context.accentColor;

    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            saving ? Icons.sync_rounded : Icons.edit_rounded,
            size: 14,
            color: tone,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
