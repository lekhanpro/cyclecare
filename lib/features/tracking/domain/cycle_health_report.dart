import 'dart:math';

import 'cycle_models.dart';
import 'record_summaries.dart';

class HealthReportOptions {
  const HealthReportOptions({
    required this.start,
    required this.end,
    this.symptoms = const {},
    this.includeMedication = false,
    this.includeTests = false,
    this.includeEstimates = false,
  });
  final DateTime start;
  final DateTime end;
  final Set<String> symptoms;
  final bool includeMedication;
  final bool includeTests;
  final bool includeEstimates;
}

/// A readable report, separate from a complete restorable backup.
/// Sensitive details and estimates require an explicit selection for each report.
String buildCycleHealthReport({
  required List<CycleEvent> periods,
  required List<DailyLog> logs,
  required HealthReportOptions options,
  CyclePrediction? prediction,
  List<String> painDiaryRows = const [],
  DateTime? referenceDate,
}) {
  if (options.start.isAfter(options.end))
    throw ArgumentError('Invalid report dates');
  String day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  bool contains(DateTime d) =>
      day(d).compareTo(day(options.start)) >= 0 &&
      day(d).compareTo(day(options.end)) <= 0;
  final sorted = [...periods]
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  final entries = logs.where((l) => contains(l.date)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final today = day(referenceDate ?? DateTime.now());
  final report = StringBuffer(
    'CycleCare cycle-health report\n'
    '${day(options.start)} to ${day(options.end)} (inclusive)\n\n'
    'OBSERVATIONS — self-reported, not diagnoses\n'
    'Missing means not logged; it never means no symptoms or no bleeding.\n'
    'Period end missing means duration is unknown, not the configured average.\n\n'
    'Earlier app versions could fill period ends from settings. Verify saved dates with your care team.\n\n'
    'RECORDED PERIODS\n',
  );
  final inRange = sorted
      .where(
        (p) =>
            contains(p.startDate) ||
            (p.startDate.isBefore(options.start) &&
                p.endDate != null &&
                !p.endDate!.isBefore(options.start)),
      )
      .toList();
  if (inRange.isEmpty) report.writeln('No period records in this range.');
  for (final p in inRange) {
    final futureEnd = p.endDate != null && day(p.endDate!).compareTo(today) > 0;
    report.writeln(
      '${day(p.startDate)} to ${p.endDate == null ? 'end not logged' : day(p.endDate!)}; '
      'duration ${futureEnd
          ? 'unconfirmed (end date is in the future)'
          : p.endDate == null
          ? 'unknown'
          : '${calendarDays(p.startDate, p.endDate!) + 1} days'}; '
      'period flow category ${p.flow.label} (may use saved default); forecast learning ${p.excludeFromPredictions ? 'excluded' : 'included when eligible'}',
    );
  }
  final lengths = <int>[];
  for (var i = 1; i < sorted.length; i++) {
    if (!contains(sorted[i].startDate)) continue;
    final length = calendarDays(sorted[i - 1].startDate, sorted[i].startDate);
    lengths.add(length);
    report.writeln(
      'Recorded start-to-start interval: ${day(sorted[i - 1].startDate)} to '
      '${day(sorted[i].startDate)}: $length days',
    );
  }
  if (lengths.isNotEmpty) {
    final mean = lengths.reduce((a, b) => a + b) / lengths.length;
    final sd = sqrt(
      lengths.fold<double>(0, (s, v) => s + pow(v - mean, 2)) / lengths.length,
    );
    report.writeln(
      '${lengths.length} recorded intervals; mean ${mean.toStringAsFixed(1)} days; '
      'range ${lengths.reduce(min)}–${lengths.reduce(max)}; standard deviation ${sd.toStringAsFixed(1)} days. '
      'All recorded intervals shown, including excluded/unusually long gaps.',
    );
  }
  final days = calendarDays(options.start, options.end) + 1;
  final loggedDays = entries.map((l) => day(l.date)).toSet().length;
  report.writeln(
    '\nDAILY OBSERVATIONS\n$loggedDays of $days days have a daily entry; '
    '${days - loggedDays} days have no entry. Individual fields may still be missing.',
  );
  report.writeln(
    'Symptoms selected for this report: ${options.symptoms.isEmpty ? 'none' : options.symptoms.join(', ')}',
  );
  for (final l in entries) {
    final selected = l.symptoms.where(options.symptoms.contains).toList();
    report.writeln(
      '${day(l.date)} | bleeding: ${l.flow?.label ?? 'not logged'} | '
      'pain: ${l.painLevel == null ? 'not logged' : '${l.painLevel}/10'} | '
      'location: ${l.painLocations.isEmpty ? 'not logged' : l.painLocations.join(', ')} | '
      'activities: ${l.painInterference ?? 'not logged'} | '
      'selected symptoms: ${selected.isEmpty ? 'not recorded (absence not established)' : selected.join(', ')}',
    );
    if (options.includeMedication)
      report.writeln(
        '  Medication: '
        '${l.medicineTaken == null
            ? 'not logged'
            : l.medicineTaken!
            ? 'taken'
            : 'not taken'}; '
        '${l.medicineName ?? 'name not logged'}; ${l.medicineDose ?? 'dose not logged'}',
      );
    if (options.includeTests)
      report.writeln(
        '  Reproductive observations: '
        'LH ${l.ovulationTest ?? 'not logged'}; pregnancy test ${l.pregnancyTest ?? 'not logged'}; '
        'BBT ${l.temperatureCelsius == null ? 'not logged' : '${l.temperatureCelsius} °C'}; '
        'measurement context ${l.temperatureContext.isEmpty ? 'not logged' : l.temperatureContext.join(', ')}; '
        'cervical mucus ${l.cervicalMucus ?? 'not logged'}; test note ${l.testNote ?? 'not logged'}',
      );
  }
  final impact = PainImpactSummary(entries);
  report.writeln(
    '\nActivities affected on ${impact.interfered} of ${impact.assessed} assessed days; '
    '${impact.uncertain} uncertain responses. Unassessed days excluded.',
  );
  if (painDiaryRows.isNotEmpty) {
    report.writeln(
      '\nEXISTING PAIN DIARY — separate entries, may overlap daily logs',
    );
    for (final row in painDiaryRows) {
      report.writeln(row);
    }
  }
  report.writeln('\nSYMPTOM COUNTS — descriptive, no cause inferred');
  for (final s in symptomCycleSummaries(
    sorted,
    entries,
  ).where((s) => options.symptoms.contains(s.symptom))) {
    report.writeln(
      '${s.symptom}: logged in ${s.cyclesWithSymptom} of ${s.observedCycles} observed cycles; '
      '${s.daysWithSymptom} days with this symptom among ${s.observedDays} days with symptom entries. '
      'Blank symptom fields excluded.',
    );
  }
  if (options.includeEstimates) {
    report.writeln('\nESTIMATES — calendar calculations, not recorded events');
    report.writeln(
      prediction == null
          ? 'No estimate available.'
          : 'Next period estimate ${day(prediction.nextPeriodStart)}. ${prediction.estimateExplanation}',
    );
  }
  report.writeln(
    '\nPrepared on this device. Nothing is sent until you choose Copy or Share. '
    'This report cannot diagnose a condition, confirm ovulation, or establish contraceptive safe days.',
  );
  return report.toString();
}
