import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../domain/cycle_models.dart';
import '../domain/logging_catalog.dart';
import '../domain/tracking_options.dart';
import 'log_tiles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Log field controls
//
// One control per LogFieldKind, each reading and writing a DailyLog only
// through the field's catalogue binding, so this screen cannot drift from the
// data layer.
//
// Three states stay visibly distinct everywhere:
//   • not logged: no tile selected, an empty input showing "—", and the word
//     "Not logged" beside the field. Never a zero, never a "no".
//   • none / zero / false: a selected tile ("None", "0", "Not taken") or a
//     typed 0. It is a recorded observation and counts as one.
//   • unknown: a selected "Not sure"-style tile, also a recorded answer.
// ─────────────────────────────────────────────────────────────────────────────

/// Number of recorded observations [field] holds on [log], counted the same
/// way as `DailyLog.observationCount`: one per value, one per selected item.
int logFieldCount(LogField field, DailyLog log) {
  final value = field.binding.read(log);
  if (value == null) return 0;
  if (value is List) return value.length;
  return 1;
}

int logGroupCount(LogGroup group, DailyLog log) =>
    group.fields.fold(0, (sum, field) => sum + logFieldCount(field, log));

String _canon(LogField field, String value) =>
    canonicalOption(field.jsonKey, value);

bool _matches(LogField field, LogOption option, Object? stored) {
  if (stored == null) return false;
  if (stored is String) {
    return stored == option.value || _canon(field, stored) == option.label;
  }
  return stored == option.value;
}

/// Whether [option] is recorded for [field] on [log].
bool logOptionSelected(LogField field, LogOption option, DailyLog log) {
  final value = field.binding.read(log);
  if (value is List) {
    return value.any((item) => _matches(field, option, item));
  }
  return _matches(field, option, value);
}

/// Stored values that match no catalogue option (older or hand-entered
/// records). They are shown as their own selected tiles so nothing stored
/// becomes unreadable.
List<LogOption> _legacyOptions(LogField field, DailyLog log) {
  final value = field.binding.read(log);
  final values = value is List ? value : [value];
  return [
    for (final item in values)
      if (item is String &&
          !field.options.any((option) => _matches(field, option, item)))
        LogOption(value: item, label: item, icon: 'tag', implemented: true),
  ];
}

String formatLogNumber(num value) {
  if (value is int) return '$value';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// A short, readable description of what [field] records on [log], or null
/// when it is not logged.
String? logFieldSummary(LogField field, DailyLog log) {
  final value = field.binding.read(log);
  if (value == null) return null;
  switch (field.kind) {
    case LogFieldKind.scale:
      return '${field.label} $value/${field.max ?? 10}';
    case LogFieldKind.number:
      final unit = field.unit == null ? '' : ' ${field.unit}';
      return '${field.label} ${formatLogNumber(value as num)}$unit';
    case LogFieldKind.textarea:
      return 'Note added';
    case LogFieldKind.text:
      return '${field.label}: $value';
    case LogFieldKind.date:
      return null;
    case LogFieldKind.single:
    case LogFieldKind.multi:
    case LogFieldKind.custom:
      final values = value is List ? value : [value];
      return [
        for (final item in values)
          field.options
                  .where((option) => _matches(field, option, item))
                  .map((option) => option.label)
                  .firstOrNull ??
              '$item',
      ].join(', ');
  }
}

String logGroupSummary(LogGroup group, DailyLog log) {
  final parts = [
    for (final field in group.fields) ?logFieldSummary(field, log),
  ];
  return parts.isEmpty ? 'Nothing recorded' : parts.join(' · ');
}

TextStyle _noteStyle(BuildContext context) =>
    AppTextStyles.body(fontSize: 12, height: 1.5)
        .copyWith(color: context.mutedColor);

/// Field label with either a Clear action (logged) or "Not logged".
class LogFieldHeading extends StatelessWidget {
  const LogFieldHeading({
    super.key,
    required this.label,
    required this.logged,
    required this.onClear,
    this.icon,
  });

  final String label;
  final bool logged;
  final VoidCallback onClear;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppLayout.minTouchTarget),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: context.accent.text),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(fontSize: 13, fontWeight: FontWeight.w600)
                  .copyWith(color: context.inkColor),
            ),
          ),
          if (logged)
            TextButton(
              onPressed: onClear,
              child: Text('Clear', semanticsLabel: 'Clear $label'),
            )
          else
            Text(
              'Not logged',
              style: AppTextStyles.body(fontSize: 11)
                  .copyWith(color: context.mutedColor),
            ),
        ],
      ),
    );
  }
}

class LogFieldError extends StatelessWidget {
  const LogFieldError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = AccentRoles.dangerText(Theme.of(context).brightness);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.warning, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body(fontSize: 12, height: 1.4)
                    .copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single, multi and scale fields as a grid of tiles.
class LogChoiceField extends StatelessWidget {
  const LogChoiceField({
    super.key,
    required this.field,
    required this.log,
    required this.onChanged,
    required this.showHeading,
    required this.showAll,
    required this.onToggleShowAll,
    this.error,
  });

  final LogField field;
  final DailyLog log;
  final ValueChanged<DailyLog> onChanged;
  final bool showHeading;
  final bool showAll;
  final VoidCallback onToggleShowAll;
  final String? error;

  int get _columns {
    if (field.kind == LogFieldKind.scale) return 6;
    return switch (field.id) {
      'flow' => 5,
      'mood' => 4,
      _ => 3,
    };
  }

  void _tap(LogOption option, bool selected) {
    final binding = field.binding;
    if (field.kind == LogFieldKind.multi) {
      final current = <String>[...?(binding.read(log) as List<String>?)];
      if (selected) {
        current.removeWhere((item) => _matches(field, option, item));
      } else {
        current.add(option.value as String);
      }
      onChanged(binding.write(log, current));
      return;
    }
    // Re-tapping the recorded answer leaves the field unlogged.
    onChanged(selected ? binding.clear(log) : binding.write(log, option.value));
  }

  @override
  Widget build(BuildContext context) {
    final logged = field.binding.isLogged(log);
    final legacy = _legacyOptions(field, log);
    final preview = field.preview;
    final collapsible = field.kind != LogFieldKind.scale &&
        preview != null &&
        field.options.length > preview;
    final options = [
      for (var i = 0; i < field.options.length; i++)
        if (!collapsible ||
            showAll ||
            i < preview ||
            logOptionSelected(field, field.options[i], log))
          field.options[i],
      ...legacy,
    ];
    final scale = field.kind == LogFieldKind.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading)
          LogFieldHeading(
            label: field.label,
            logged: logged,
            onClear: () => onChanged(field.binding.clear(log)),
          ),
        if (field.note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(field.note!, style: _noteStyle(context)),
          ),
        LogTileGrid(
          columns: _columns,
          minTileWidth: scale ? 40 : 60,
          children: [
            for (final option in options)
              Builder(builder: (context) {
                final selected = logOptionSelected(field, option, log) ||
                    legacy.contains(option);
                return LogTile(
                  key: ValueKey('log-option-${field.id}-${option.label}'),
                  icon: scale ? null : AppIcons.named(option.icon),
                  label: option.label,
                  selected: selected,
                  semanticHint: field.kind == LogFieldKind.multi
                      ? (selected
                          ? 'Selected. Tap to remove'
                          : 'Not logged. Tap to add')
                      : null,
                  onTap: () => _tap(option, selected),
                );
              }),
          ],
        ),
        if (scale)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            // Flexible: at 360 px with large text the two end labels together
            // are wider than the row, which overflowed by a few pixels.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    field.id == 'painLevel' ? 'No pain' : '${field.min}',
                    style: _noteStyle(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    field.id == 'painLevel' ? 'Severe pain' : '${field.max}',
                    style: _noteStyle(context),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        if (collapsible)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onToggleShowAll,
              icon: Icon(showAll ? AppIcons.up : AppIcons.down, size: 14),
              label: Text(
                showAll
                    ? 'Show fewer'
                    : 'See all ${field.options.length} choices',
              ),
            ),
          ),
        if (error != null) LogFieldError(message: error!),
      ],
    );
  }
}

/// A number with its unit. The text is parsed by the screen, which owns the
/// draft; an empty box means not logged, a typed 0 is a recorded zero.
class LogNumberField extends StatefulWidget {
  const LogNumberField({
    super.key,
    required this.field,
    required this.initial,
    required this.onChanged,
    this.error,
  });

  final LogField field;

  /// The screen's draft text, so a group closed and reopened keeps it.
  final String initial;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  State<LogNumberField> createState() => _LogNumberFieldState();
}

class _LogNumberFieldState extends State<LogNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final decimal = (field.step ?? 1) < 1;
    final empty = _controller.text.trim().isEmpty;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    final label = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(AppIcons.named(field.icon),
              size: 19, color: context.accent.text),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: AppTextStyles.body(
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ).copyWith(color: context.inkColor),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                empty ? 'Not logged' : (field.hint ?? ''),
                style: AppTextStyles.body(fontSize: 11, height: 1.35)
                    .copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ],
    );

    final input = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 76 * textScale.clamp(1.0, 1.5),
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              hintText: '—',
              isDense: true,
              hintStyle: TextStyle(color: context.mutedColor),
            ),
            onChanged: (value) {
              setState(() {});
              widget.onChanged(value);
            },
          ),
        ),
        if (field.unit != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            field.unit!,
            style: AppTextStyles.body(fontSize: 12)
                .copyWith(color: context.mutedColor),
          ),
        ],
      ],
    );

    return Semantics(
      label: '${field.label} in ${field.unit ?? ''}',
      value: empty ? 'Not logged' : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (textScale > 1.6) ...[
              label,
              const SizedBox(height: AppSpacing.sm),
              Align(alignment: AlignmentDirectional.centerEnd, child: input),
            ] else
              Row(
                children: [
                  Expanded(child: label),
                  const SizedBox(width: AppSpacing.md),
                  input,
                ],
              ),
            if (widget.error != null) LogFieldError(message: widget.error!),
          ],
        ),
      ),
    );
  }
}

/// Free text and the note area. Blank text is not an observation.
class LogTextField extends StatefulWidget {
  const LogTextField({
    super.key,
    required this.field,
    required this.initial,
    required this.onChanged,
    this.error,
  });

  final LogField field;
  final String initial;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  State<LogTextField> createState() => _LogTextFieldState();
}

class _LogTextFieldState extends State<LogTextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final area = field.kind == LogFieldKind.textarea;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(AppIcons.named(field.icon),
                    size: 17, color: context.accent.text),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    field.label,
                    style: AppTextStyles.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ).copyWith(color: context.inkColor),
                  ),
                ),
                if (field.private)
                  Text(
                    'Only on this phone',
                    style: AppTextStyles.body(fontSize: 11)
                        .copyWith(color: context.mutedColor),
                  ),
              ],
            ),
          ),
          TextField(
            controller: _controller,
            minLines: area ? 3 : 1,
            maxLines: area ? 6 : 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: field.placeholder),
            onChanged: widget.onChanged,
          ),
          if (widget.error != null) LogFieldError(message: widget.error!),
        ],
      ),
    );
  }
}

/// Custom tags: the saved tag library as tiles plus an add box. A tag stored
/// on a day stays visible and selected even if it was removed from the
/// library, so older records stay readable and editable.
class LogCustomTagsField extends StatefulWidget {
  const LogCustomTagsField({
    super.key,
    required this.field,
    required this.library,
    required this.log,
    required this.onChanged,
    required this.onAddToLibrary,
    required this.onRemoveFromLibrary,
  });

  final LogField field;
  final List<String> library;
  final DailyLog log;
  final ValueChanged<DailyLog> onChanged;
  final Future<void> Function(String tag) onAddToLibrary;
  final Future<void> Function(String tag) onRemoveFromLibrary;

  @override
  State<LogCustomTagsField> createState() => _LogCustomTagsFieldState();
}

class _LogCustomTagsFieldState extends State<LogCustomTagsField> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _selected =>
      [...?(widget.field.binding.read(widget.log) as List<String>?)];

  void _toggle(String tag) {
    final selected = _selected;
    if (!selected.remove(tag)) selected.add(tag);
    widget.onChanged(widget.field.binding.write(widget.log, selected));
  }

  Future<void> _add() async {
    final tag = _controller.text.trim();
    if (tag.isEmpty) {
      setState(() => _error = 'Type a word first.');
      return;
    }
    if (catalogueSymptomOptions.contains(canonicalOption('symptoms', tag))) {
      setState(() => _error = '“$tag” is already in Symptoms above.');
      return;
    }
    final existing = [...widget.library, ..._selected].firstWhere(
      (item) => item.toLowerCase() == tag.toLowerCase(),
      orElse: () => tag,
    );
    setState(() => _error = null);
    _controller.clear();
    await widget.onAddToLibrary(existing);
    if (!mounted) return;
    if (!_selected.contains(existing)) _toggle(existing);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final tags = <String>{...widget.library, ...selected}.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogFieldHeading(
          label: widget.field.label,
          logged: selected.isNotEmpty,
          onClear: () =>
              widget.onChanged(widget.field.binding.clear(widget.log)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            widget.field.note ?? 'Add a word that fits your own experience.',
            style: _noteStyle(context),
          ),
        ),
        if (tags.isNotEmpty) ...[
          LogTileGrid(
            columns: 3,
            minTileWidth: 60,
            children: [
              for (final tag in tags)
                LogTile(
                  key: ValueKey('log-tag-$tag'),
                  icon: AppIcons.tag,
                  label: tag,
                  selected: selected.contains(tag),
                  semanticHint: widget.library.contains(tag)
                      ? 'Tap to record. Long-press to remove from your list'
                      : null,
                  onTap: () => _toggle(tag),
                  onLongPress: widget.library.contains(tag)
                      ? () => widget.onRemoveFromLibrary(tag)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Name a symptom or feeling',
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: AppLayout.minTouchTarget,
              height: AppLayout.minTouchTarget,
              child: IconButton.filledTonal(
                tooltip: 'Add custom symptom',
                onPressed: _add,
                icon: const Icon(AppIcons.plus, size: 18),
              ),
            ),
          ],
        ),
        if (_error != null) LogFieldError(message: _error!),
      ],
    );
  }
}
