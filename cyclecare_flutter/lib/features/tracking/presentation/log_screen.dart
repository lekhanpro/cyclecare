import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cyclecare_theme.dart';
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
  FlowIntensity? _flow;
  String? _mood;
  final _symptoms = <String>{};
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleTrackerControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: state.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) => ListView(
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
                      'Logging for ${data.selectedDate.month}/${data.selectedDate.day}/${data.selectedDate.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: CycleCareColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Flow',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final flow in FlowIntensity.values)
                    SymptomChip(
                      label: _labelForFlow(flow),
                      selected: _flow == flow,
                      onSelected: (selected) {
                        setState(() => _flow = selected ? flow : null);
                      },
                    ),
                ],
              ),
            ),
            _Section(
              title: 'Mood',
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
                          selected ? _symptoms.add(symptom) : _symptoms.remove(symptom);
                        });
                      },
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
            PrimaryButton(
              label: 'Save log',
              icon: CupertinoIcons.check_mark,
              onPressed: () async {
                final controller = ref.read(cycleTrackerControllerProvider.notifier);
                await controller.saveLog(
                  DailyLog(
                    date: data.selectedDate,
                    flow: _flow,
                    mood: _mood,
                    symptoms: _symptoms.toList(),
                    notes: _notesController.text.trim(),
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Log saved')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _labelForFlow(FlowIntensity flow) {
    return switch (flow) {
      FlowIntensity.spotting => 'Spotting',
      FlowIntensity.light => 'Light',
      FlowIntensity.medium => 'Medium',
      FlowIntensity.heavy => 'Heavy',
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
