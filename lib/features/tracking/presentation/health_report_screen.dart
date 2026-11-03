import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../widgets/widgets.dart';
import '../application/cycle_tracker_controller.dart';
import '../domain/cycle_health_report.dart';

class HealthReportScreen extends ConsumerStatefulWidget {
  const HealthReportScreen({super.key});

  @override
  ConsumerState<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends ConsumerState<HealthReportScreen> {
  late DateTimeRange _range;
  final _symptoms = <String>{};
  bool _medication = false;
  bool _tests = false;
  bool _estimates = false;
  bool _busy = false;
  String? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month - 5, 1),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> _prepare() async {
    final data = ref.read(cycleTrackerControllerProvider).valueOrNull;
    if (data == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final diary = <String>[];
      for (final raw
          in prefs.getStringList('cyclecare.pain_entries.v1') ?? <String>[]) {
        final entry = jsonDecode(raw) as Map<String, dynamic>;
        final date = DateTime.parse(entry['date'] as String);
        final day = DateTime(date.year, date.month, date.day);
        if (day.isBefore(_range.start) || day.isAfter(_range.end)) continue;
        diary.add(
          '${DateFormat('yyyy-MM-dd').format(day)}: pain ${entry['severity']}/10; '
          'locations ${(entry['locations'] as List<dynamic>? ?? []).join(', ')}; '
          'activities ${entry['painInterference'] ?? 'not logged'}',
        );
      }
      final report = buildCycleHealthReport(
        periods: data.periods,
        logs: data.logs,
        prediction: data.prediction,
        painDiaryRows: diary,
        options: HealthReportOptions(
          start: _range.start,
          end: _range.end,
          symptoms: Set.of(_symptoms),
          includeMedication: _medication,
          includeTests: _tests,
          includeEstimates: _estimates,
        ),
      );
      if (mounted) setState(() => _preview = report);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not read all report records. '
              'Your saved data is unchanged. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final text = _preview;
    if (text == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(text)),
            mimeType: 'text/plain',
            name: 'cyclecare-health-report.txt',
          ),
        ],
        fileNameOverrides: ['cyclecare-health-report.txt'],
        subject: 'CycleCare cycle-health report',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'The share sheet could not open. '
              'You can retry or copy the preview.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: _preview!));
      if (mounted) showAppToast(context, message: 'Report copied');
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not copy the report. Please try again.');
    }
  }

  Future<void> _chooseDates() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (selected != null && mounted) setState(() => _range = selected);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cycleTrackerControllerProvider);
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(title: const Text('Cycle-health report')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(cycleTrackerControllerProvider),
            child: const Text('Try loading records again'),
          ),
        ),
        data: (data) {
          final available = data.logs.expand((l) => l.symptoms).toSet().toList()
            ..sort();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (_preview == null) ...[
                    Text(
                      'Build your report',
                      style: AppTextStyles.heading(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Offline, with a preview before sharing. Sensitive details start off.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      icon: const Icon(AppIcons.calendar),
                      label: Text(
                        '${DateFormat.yMMMd().format(_range.start)} – ${DateFormat.yMMMd().format(_range.end)}',
                      ),
                      onPressed: _busy ? null : _chooseDates,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Selected symptoms',
                      style: AppTextStyles.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (available.isEmpty)
                      const Text('No symptoms recorded yet.'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in available)
                          FilterChip(
                            label: Text(s),
                            selected: _symptoms.contains(s),
                            onSelected: _busy
                                ? null
                                : (selected) => setState(() {
                                    if (selected) {
                                      _symptoms.add(s);
                                    } else {
                                      _symptoms.remove(s);
                                    }
                                  }),
                          ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include medication'),
                      value: _medication,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _medication = v!),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include reproductive observations'),
                      subtitle: const Text(
                        'LH and pregnancy tests, BBT, measurement context, mucus and test notes',
                      ),
                      value: _tests,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _tests = v!),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include calendar estimate'),
                      subtitle: const Text('In a separate estimates section'),
                      value: _estimates,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _estimates = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Preview report',
                      loading: _busy,
                      onPressed: _busy ? null : _prepare,
                    ),
                  ] else ...[
                    Text(
                      'Report preview',
                      style: AppTextStyles.heading(fontSize: 24),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Only this preview is copied or shared. The report is separate from your backup.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(AppIcons.sliders),
                          label: const Text('Edit selection'),
                          onPressed: _busy
                              ? null
                              : () => setState(() => _preview = null),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(AppIcons.copy),
                          label: const Text('Copy report'),
                          onPressed: _busy ? null : _copy,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Share report file',
                      icon: AppIcons.share,
                      loading: _busy,
                      onPressed: _busy ? null : _share,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      child: SelectableText(
                        _preview!,
                        style: AppTextStyles.body(fontSize: 14, height: 1.6),
                      ),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(_error!),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
