import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../providers/app_providers.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  late DateTime _selectedDate;
  String? _selectedFlow;
  final Set<String> _selectedMoods = {};
  final Set<String> _selectedSymptoms = {};

  // Cervical observations
  String? _mucusType;
  String? _cervicalPosition;
  String? _cervicalFirmness;
  String? _cervicalOpening;

  // Temperature
  final TextEditingController _tempController = TextEditingController();

  // Water intake
  int _waterGlasses = 0;

  // Sleep
  double _sleepHours = 7;

  // Exercise
  String? _exerciseType;
  double _exerciseMinutes = 0;

  // Sexual activity
  String? _sexualActivity;

  // Notes
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadExistingLog();
  }

  @override
  void dispose() {
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLog() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final log = await db.getDailyLogForDate(_selectedDate);
      final cervical = await db.getCervicalForDate(_selectedDate);

      if (log != null) {
        setState(() {
          _selectedFlow = log.flow;
          _selectedMoods.clear();
          if (log.mood != null && log.mood!.isNotEmpty) {
            _selectedMoods.addAll(log.mood!.split(','));
          }
          _selectedSymptoms.clear();
          try {
            final symptoms = jsonDecode(log.symptoms) as List;
            _selectedSymptoms.addAll(symptoms.cast<String>());
          } catch (_) {}
          if (log.temperature != null) {
            _tempController.text = log.temperature!.toStringAsFixed(1);
          } else {
            _tempController.clear();
          }
          _waterGlasses = (log.waterMl / AppConstants.glassSize).round();
          _sleepHours = log.sleepHours ?? 7;
          _exerciseMinutes = log.exerciseMinutes.toDouble();
          _notesController.text = log.notes;
          _sexualActivity = log.sexualActivity
              ? 'Unprotected'
              : (log.intimacy ? 'Protected' : 'None');
        });
      } else {
        _resetForm();
      }

      if (cervical != null) {
        setState(() {
          _mucusType =
              cervical.mucusType.isEmpty ? null : cervical.mucusType;
          _cervicalPosition =
              cervical.position.isEmpty ? null : cervical.position;
          _cervicalFirmness =
              cervical.firmness.isEmpty ? null : cervical.firmness;
          _cervicalOpening =
              cervical.opening.isEmpty ? null : cervical.opening;
        });
      } else {
        setState(() {
          _mucusType = null;
          _cervicalPosition = null;
          _cervicalFirmness = null;
          _cervicalOpening = null;
        });
      }
    } catch (_) {
      _resetForm();
    }
    setState(() => _isLoading = false);
  }

  void _resetForm() {
    setState(() {
      _selectedFlow = null;
      _selectedMoods.clear();
      _selectedSymptoms.clear();
      _tempController.clear();
      _waterGlasses = 0;
      _sleepHours = 7;
      _exerciseType = null;
      _exerciseMinutes = 0;
      _sexualActivity = null;
      _notesController.clear();
      _mucusType = null;
      _cervicalPosition = null;
      _cervicalFirmness = null;
      _cervicalOpening = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadExistingLog();
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final date = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final existingLog = await db.getDailyLogForDate(date);
      final temp = double.tryParse(_tempController.text);

      final logCompanion = DailyLogsCompanion(
        date: Value(date),
        flow: Value(_selectedFlow),
        mood: Value(_selectedMoods.join(',')),
        symptoms: Value(jsonEncode(_selectedSymptoms.toList())),
        temperature: Value(temp),
        waterMl: Value((_waterGlasses * AppConstants.glassSize).round()),
        sleepHours: Value(_sleepHours),
        exerciseMinutes: Value(_exerciseMinutes.round()),
        sexualActivity: Value(_sexualActivity == 'Unprotected'),
        intimacy: Value(
          _sexualActivity == 'Protected' ||
              _sexualActivity == 'Unprotected',
        ),
        notes: Value(_notesController.text),
        cervicalMucus: Value(_mucusType),
      );

      if (existingLog != null) {
        await db.updateDailyLog(
          existingLog.copyWith(
            flow: Value(_selectedFlow),
            mood: Value(_selectedMoods.join(',')),
            symptoms: jsonEncode(_selectedSymptoms.toList()),
            temperature: Value(temp),
            waterMl: (_waterGlasses * AppConstants.glassSize).round(),
            sleepHours: Value(_sleepHours),
            exerciseMinutes: _exerciseMinutes.round(),
            sexualActivity:
                _sexualActivity == 'Unprotected',
            intimacy:
                _sexualActivity == 'Protected' ||
                _sexualActivity == 'Unprotected',
            notes: _notesController.text,
            cervicalMucus: Value(_mucusType),
          ),
        );
      } else {
        await db.insertDailyLog(logCompanion);
      }

      // Save cervical observations
      final existingCervical = await db.getCervicalForDate(date);
      if (existingCervical == null &&
          (_mucusType != null ||
              _cervicalPosition != null ||
              _cervicalFirmness != null ||
              _cervicalOpening != null)) {
        await db.insertCervicalObservation(
          CervicalObservationsCompanion(
            date: Value(date),
            mucusType: Value(_mucusType ?? ''),
            position: Value(_cervicalPosition ?? ''),
            firmness: Value(_cervicalFirmness ?? ''),
            opening: Value(_cervicalOpening ?? ''),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily log saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving log: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Log'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Date picker
                _buildDatePicker(colorScheme),
                const SizedBox(height: 16),

                // Flow level
                _buildSectionCard(
                  title: 'Flow Level',
                  icon: Icons.water_drop_outlined,
                  child: _buildFlowChips(),
                ),

                // Mood
                _buildSectionCard(
                  title: 'Mood',
                  icon: Icons.emoji_emotions_outlined,
                  child: _buildMoodChips(),
                ),

                // Symptoms
                _buildSectionCard(
                  title: 'Symptoms',
                  icon: Icons.healing_outlined,
                  child: _buildSymptomChips(),
                ),

                // Cervical observations
                _buildSectionCard(
                  title: 'Cervical Observations',
                  icon: Icons.visibility_outlined,
                  child: _buildCervicalSection(),
                ),

                // Temperature
                _buildSectionCard(
                  title: 'Temperature (BBT)',
                  icon: Icons.thermostat_outlined,
                  child: _buildTemperatureField(),
                ),

                // Water intake
                _buildSectionCard(
                  title: 'Water Intake',
                  icon: Icons.local_drink_outlined,
                  child: _buildWaterIntake(colorScheme),
                ),

                // Sleep
                _buildSectionCard(
                  title: 'Sleep',
                  icon: Icons.bedtime_outlined,
                  child: _buildSleepSlider(colorScheme),
                ),

                // Exercise
                _buildSectionCard(
                  title: 'Exercise',
                  icon: Icons.fitness_center_outlined,
                  child: _buildExerciseSection(colorScheme),
                ),

                // Sexual activity
                _buildSectionCard(
                  title: 'Sexual Activity',
                  icon: Icons.favorite_outline,
                  child: _buildSexualActivityChips(),
                ),

                // Notes
                _buildSectionCard(
                  title: 'Notes',
                  icon: Icons.notes_outlined,
                  child: _buildNotesField(),
                ),

                const SizedBox(height: 16),

                // Save button
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Log'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ── Date Picker ──

  Widget _buildDatePicker(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Card ──

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // ── Flow Chips ──

  Widget _buildFlowChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AppConstants.flowLevels.map((level) {
          final selected = _selectedFlow == level;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(level),
              selected: selected,
              onSelected: (val) {
                setState(() => _selectedFlow = val ? level : null);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Mood Chips ──

  Widget _buildMoodChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: AppConstants.moods.map((mood) {
        final selected = _selectedMoods.contains(mood);
        return FilterChip(
          label: Text(mood),
          selected: selected,
          onSelected: (val) {
            setState(() {
              if (val) {
                _selectedMoods.add(mood);
              } else {
                _selectedMoods.remove(mood);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ── Symptom Chips ──

  Widget _buildSymptomChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: AppConstants.symptoms.map((symptom) {
        final selected = _selectedSymptoms.contains(symptom);
        return FilterChip(
          label: Text(symptom),
          selected: selected,
          onSelected: (val) {
            setState(() {
              if (val) {
                _selectedSymptoms.add(symptom);
              } else {
                _selectedSymptoms.remove(symptom);
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ── Cervical Observations ──

  Widget _buildCervicalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCervicalSubSection(
          'Mucus Type',
          AppConstants.cervicalMucusTypes,
          _mucusType,
          (v) => setState(() => _mucusType = v),
        ),
        const SizedBox(height: 12),
        _buildCervicalSubSection(
          'Position',
          AppConstants.cervicalPositions,
          _cervicalPosition,
          (v) => setState(() => _cervicalPosition = v),
        ),
        const SizedBox(height: 12),
        _buildCervicalSubSection(
          'Firmness',
          AppConstants.cervicalFirmness,
          _cervicalFirmness,
          (v) => setState(() => _cervicalFirmness = v),
        ),
        const SizedBox(height: 12),
        _buildCervicalSubSection(
          'Opening',
          AppConstants.cervicalOpening,
          _cervicalOpening,
          (v) => setState(() => _cervicalOpening = v),
        ),
      ],
    );
  }

  Widget _buildCervicalSubSection(
    String label,
    List<String> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = selected == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (val) => onChanged(val ? option : null),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Temperature ──

  Widget _buildTemperatureField() {
    return TextFormField(
      controller: _tempController,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: 'e.g. 36.5',
        suffixText: '\u00B0C',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // ── Water Intake ──

  Widget _buildWaterIntake(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          onPressed: _waterGlasses > 0
              ? () => setState(() => _waterGlasses--)
              : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          children: [
            Text(
              '$_waterGlasses',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
            Text(
              'glasses (${(_waterGlasses * AppConstants.glassSize).round()} ml)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(width: 16),
        IconButton.filled(
          onPressed: () => setState(() => _waterGlasses++),
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }

  // ── Sleep Slider ──

  Widget _buildSleepSlider(ColorScheme colorScheme) {
    return Column(
      children: [
        Slider(
          value: _sleepHours,
          min: 0,
          max: 12,
          divisions: 24,
          label: '${_sleepHours.toStringAsFixed(1)} hrs',
          onChanged: (val) => setState(() => _sleepHours = val),
        ),
        Text(
          '${_sleepHours.toStringAsFixed(1)} hours',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  // ── Exercise ──

  Widget _buildExerciseSection(ColorScheme colorScheme) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _exerciseType,
          decoration: InputDecoration(
            hintText: 'Select type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: AppConstants.exerciseTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (val) => setState(() => _exerciseType = val),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _exerciseMinutes,
          min: 0,
          max: 180,
          divisions: 36,
          label: '${_exerciseMinutes.round()} min',
          onChanged: (val) =>
              setState(() => _exerciseMinutes = val),
        ),
        Text(
          '${_exerciseMinutes.round()} minutes',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  // ── Sexual Activity ──

  Widget _buildSexualActivityChips() {
    const options = ['None', 'Protected', 'Unprotected'];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((option) {
        final selected = _sexualActivity == option;
        return FilterChip(
          label: Text(option),
          selected: selected,
          onSelected: (val) {
            setState(
              () => _sexualActivity = val ? option : null,
            );
          },
        );
      }).toList(),
    );
  }

  // ── Notes ──

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Any additional notes...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
