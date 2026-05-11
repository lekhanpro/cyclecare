import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/soft_card.dart';
import '../../../widgets/symptom_chip.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_models.dart';
import '../domain/tracking_options.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  FlowIntensity _flow = FlowIntensity.none;
  String? _mood;
  String? _discharge;
  String? _cervicalMucus;
  String? _cervicalPosition;
  String? _cervicalFirmness;
  String? _cervicalOpening;
  final _symptoms = <String>{};
  double _painLevel = 0;
  double _sleepHours = 7;
  int _waterMl = 0;
  bool _medicineTaken = false;

  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicineController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _loadedDate;

  @override
  void dispose() {
    _temperatureController.dispose();
    _weightController.dispose();
    _medicineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleTrackerControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Log')),
      body: state.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) {
          _hydrateFromLog(data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              SoftCard(
                color: const Color(0xFFFFFCFB),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.calendar, color: CycleCareColors.rose),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Logging for ${shortDate(data.selectedDate)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: CycleCareColors.ink,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickDate(data.selectedDate),
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'Period Flow',
                subtitle: 'Choose the closest match for today.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final flow in FlowIntensity.values)
                      SymptomChip(
                        label: _labelForFlow(flow),
                        selected: _flow == flow,
                        onSelected: (_) => setState(() => _flow = flow),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Mood',
                subtitle: 'One word is enough. Patterns matter over time.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mood in moodOptions)
                      SymptomChip(
                        label: mood,
                        selected: _mood == mood,
                        onSelected: (selected) {
                          setState(() => _mood = selected ? mood : null);
                        },
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Symptoms',
                subtitle: 'Log anything noticeable, even if it feels minor.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final symptom in symptomOptions)
                      SymptomChip(
                        label: symptom,
                        selected: _symptoms.contains(symptom),
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? _symptoms.add(symptom)
                                : _symptoms.remove(symptom);
                          });
                        },
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Pain Level',
                subtitle: _painLevel == 0
                    ? 'No pain logged'
                    : '${_painLevel.round()} out of 10',
                child: Slider(
                  value: _painLevel,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '${_painLevel.round()}',
                  onChanged: (value) => setState(() => _painLevel = value),
                ),
              ),
              _Section(
                title: 'Discharge and Cervical Observations',
                subtitle: 'Optional fertility signs from the plan.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChoiceWrap(
                      label: 'Discharge',
                      values: dischargeOptions,
                      selected: _discharge,
                      onSelected: (value) => setState(() => _discharge = value),
                    ),
                    _ChoiceWrap(
                      label: 'Cervical mucus',
                      values: cervicalMucusOptions,
                      selected: _cervicalMucus,
                      onSelected: (value) => setState(() => _cervicalMucus = value),
                    ),
                    _ChoiceWrap(
                      label: 'Position',
                      values: cervicalPositionOptions,
                      selected: _cervicalPosition,
                      onSelected: (value) => setState(() => _cervicalPosition = value),
                    ),
                    _ChoiceWrap(
                      label: 'Firmness',
                      values: cervicalFirmnessOptions,
                      selected: _cervicalFirmness,
                      onSelected: (value) => setState(() => _cervicalFirmness = value),
                    ),
                    _ChoiceWrap(
                      label: 'Opening',
                      values: cervicalOpeningOptions,
                      selected: _cervicalOpening,
                      onSelected: (value) => setState(() => _cervicalOpening = value),
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Body Metrics',
                subtitle: 'Optional values for trends and insights.',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            controller: _temperatureController,
                            label: 'Temp (C)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NumberField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text('Sleep', style: TextStyle(fontWeight: FontWeight.w700)),
                        Expanded(
                          child: Slider(
                            value: _sleepHours,
                            min: 0,
                            max: 14,
                            divisions: 28,
                            label: '${_sleepHours.toStringAsFixed(1)}h',
                            onChanged: (value) => setState(() => _sleepHours = value),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${_sleepHours.toStringAsFixed(1)}h',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Water', style: TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Remove water',
                          onPressed: _waterMl <= 0
                              ? null
                              : () => setState(() => _waterMl -= 250),
                          icon: const Icon(CupertinoIcons.minus_circle),
                        ),
                        Text(
                          '${(_waterMl / 250).round()} glasses',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          tooltip: 'Add water',
                          onPressed: () => setState(() => _waterMl += 250),
                          icon: const Icon(CupertinoIcons.plus_circle_fill),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Medicine or Pill',
                subtitle: 'Useful for pill reminders and medication history.',
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _medicineTaken,
                      activeColor: CycleCareColors.rose,
                      title: const Text('Taken today'),
                      onChanged: (value) => setState(() => _medicineTaken = value),
                    ),
                    TextField(
                      controller: _medicineController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine or pill name',
                        hintText: 'Optional',
                      ),
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Notes',
                child: TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Anything you want to remember?',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Save log',
                      icon: CupertinoIcons.check_mark,
                      onPressed: () => _save(data.selectedDate),
                    ),
                  ),
                ],
              ),
              if (data.logFor(data.selectedDate) != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _deleteLog(data.selectedDate),
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Delete this log'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _hydrateFromLog(CycleTrackerState data) {
    final selected = dateOnly(data.selectedDate);
    if (_loadedDate == selected) return;
    _loadedDate = selected;
    final log = data.logFor(selected);
    _flow = log?.flow ?? FlowIntensity.none;
    _mood = log?.mood;
    _symptoms
      ..clear()
      ..addAll(log?.symptoms ?? const []);
    _painLevel = (log?.painLevel ?? 0).toDouble();
    _discharge = log?.discharge;
    _cervicalMucus = log?.cervicalMucus;
    _cervicalPosition = log?.cervicalPosition;
    _cervicalFirmness = log?.cervicalFirmness;
    _cervicalOpening = log?.cervicalOpening;
    _temperatureController.text = log?.temperatureCelsius?.toStringAsFixed(1) ?? '';
    _weightController.text = log?.weightKg?.toStringAsFixed(1) ?? '';
    _sleepHours = log?.sleepHours ?? 7;
    _waterMl = log?.waterMl ?? 0;
    _medicineTaken = log?.medicineTaken ?? false;
    _medicineController.text = log?.medicineName ?? '';
    _notesController.text = log?.notes ?? '';
  }

  Future<void> _pickDate(DateTime selectedDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null) return;
    await ref.read(cycleTrackerControllerProvider.notifier).selectDate(picked);
  }

  Future<void> _save(DateTime selectedDate) async {
    final controller = ref.read(cycleTrackerControllerProvider.notifier);
    await controller.saveLog(
      DailyLog(
        date: selectedDate,
        flow: _flow,
        mood: _mood,
        symptoms: _symptoms.toList()..sort(),
        painLevel: _painLevel.round(),
        discharge: _discharge,
        cervicalMucus: _cervicalMucus,
        cervicalPosition: _cervicalPosition,
        cervicalFirmness: _cervicalFirmness,
        cervicalOpening: _cervicalOpening,
        temperatureCelsius: double.tryParse(_temperatureController.text.trim()),
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log saved')),
      );
    }
  }

  Future<void> _deleteLog(DateTime selectedDate) async {
    await ref.read(cycleTrackerControllerProvider.notifier).deleteLog(selectedDate);
    setState(() => _loadedDate = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log deleted')),
      );
    }
  }

  String _labelForFlow(FlowIntensity flow) {
    return switch (flow) {
      FlowIntensity.none => 'None',
      FlowIntensity.spotting => 'Spotting',
      FlowIntensity.light => 'Light',
      FlowIntensity.medium => 'Medium',
      FlowIntensity.heavy => 'Heavy',
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CycleCareColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: CycleCareColors.muted,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CycleCareColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                SymptomChip(
                  label: value,
                  selected: selected == value,
                  onSelected: (isSelected) => onSelected(isSelected ? value : null),
                ),
            ],
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
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(labelText: label),
    );
  }
}
