import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/cyclecare_theme.dart';
import '../../../widgets/widgets.dart';
import '../domain/cycle_models.dart';
import '../domain/record_summaries.dart';

class RecordSummaryCard extends StatelessWidget {
  const RecordSummaryCard({
    super.key,
    required this.periods,
    required this.logs,
  });
  final List<CycleEvent> periods;
  final List<DailyLog> logs;

  @override
  Widget build(BuildContext context) {
    final summaries = symptomCycleSummaries(periods, logs);
    final impact = PainImpactSummary(logs);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your observed patterns',
            style: AppTextStyles.heading(fontSize: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'Activities affected on ${impact.interfered} of ${impact.assessed} assessed days. '
            '${impact.uncertain} uncertain responses. Days without an activity-impact response are excluded.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Symptom counts describe your entries. Blank symptom fields do not mean symptom-free. '
            'Cycles excluded from forecasting remain in these observations.',
          ),
          if (summaries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Select symptoms in daily logs to build a history.'),
            ),
          for (final s in summaries.take(12))
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.symptom),
              subtitle: Text(
                'Logged in ${s.cyclesWithSymptom} of '
                '${s.observedCycles} observed cycles; ${s.daysWithSymptom} of ${s.observedDays} days with symptom entries',
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'By cycle day (occurrence counts):\n'
                    '${(s.byCycleDay.keys.toList()..sort()).map((d) => 'Day $d: ${s.byCycleDay[d]}').join(' · ')}\n\n'
                    'Before the next recorded period (completed cycles only):\n'
                    '${s.beforeNextPeriod.isEmpty ? 'No next period recorded for these entries yet.' : (s.beforeNextPeriod.keys.toList()..sort()).map((d) => '$d days before: ${s.beforeNextPeriod[d]}').join(' · ')}\n'
                    'These are counts, not probabilities or causes. Missing days are excluded.\n\n'
                    'Across recorded cycles:\n'
                    '${(s.cycleObservedDays.keys.toList()..sort()).map((date) => 'Starting ${DateFormat.yMMMd().format(date)}: ${s.cycleCounts[date] ?? 0} '
                        'days with this symptom; ${s.cycleObservedDays[date]} days with symptom entries').join('\n')}',
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          OutlinedButton.icon(
            icon: const Icon(AppIcons.share),
            label: const Text('Prepare cycle-health report'),
            onPressed: () => context.push('/health-report'),
          ),
          const SizedBox(height: 12),
          const RecordCareGuidance(),
        ],
      ),
    );
  }
}

class RecordCareGuidance extends StatelessWidget {
  const RecordCareGuidance({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'If periods or pain disrupt everyday life, speak with a healthcare professional. '
        'Seek urgent local medical advice for severe or worsening period/pelvic pain when pain relief has not helped. '
        'These prompts do not diagnose a condition.',
      ),
      Wrap(
        spacing: 8,
        children: [
          for (final item in const [
            ('NHS: period pain', 'https://www.nhs.uk/symptoms/period-pain/'),
            (
              'NHS: heavy periods',
              'https://www.nhs.uk/conditions/heavy-periods/',
            ),
          ])
            TextButton(
              onPressed: () async {
                try {
                  final opened = await launchUrl(
                    Uri.parse(item.$2),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted)
                    showAppToast(
                      context,
                      message:
                          'Could not open the source. Try again when connected.',
                    );
                } catch (_) {
                  if (context.mounted)
                    showAppToast(
                      context,
                      message:
                          'Could not open the source. Try again when connected.',
                    );
                }
              },
              child: Text(item.$1),
            ),
        ],
      ),
    ],
  );
}
