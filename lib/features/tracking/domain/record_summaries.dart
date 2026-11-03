import '../../../core/utils/date_helpers.dart';
import 'cycle_models.dart';

int calendarDays(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

class SymptomCycleSummary {
  const SymptomCycleSummary(
    this.symptom,
    this.cyclesWithSymptom,
    this.observedCycles,
    this.observedDays,
    this.daysWithSymptom,
    this.byCycleDay,
    this.beforeNextPeriod,
    this.cycleCounts,
    this.cycleObservedDays,
  );
  final String symptom;
  final int cyclesWithSymptom;
  final int observedCycles;
  final int observedDays;
  final int daysWithSymptom;
  final Map<int, int> byCycleDay;
  final Map<int, int> beforeNextPeriod;
  final Map<DateTime, int> cycleCounts;
  final Map<DateTime, int> cycleObservedDays;
}

/// Descriptive counts only. Blank symptom lists do not establish symptom absence.
/// All recorded cycles remain available, including cycles excluded from forecasts.
List<SymptomCycleSummary> symptomCycleSummaries(
  List<CycleEvent> periods,
  List<DailyLog> logs,
) {
  final starts = periods.map((p) => dateOnly(p.startDate)).toSet().toList()
    ..sort();
  final assessed = <DateTime, DailyLog>{
    for (final log in logs)
      if (log.symptoms.isNotEmpty) dateOnly(log.date): log,
  };
  final observations = <({int cycle, int day, int? before, DailyLog log})>[];
  for (final entry in assessed.entries) {
    final index = starts.lastIndexWhere((s) => !s.isAfter(entry.key));
    if (index < 0) continue;
    observations.add((
      cycle: index,
      day: calendarDays(starts[index], entry.key) + 1,
      before: index + 1 < starts.length
          ? calendarDays(entry.key, starts[index + 1])
          : null,
      log: entry.value,
    ));
  }
  final observedCycles = observations.map((o) => o.cycle).toSet().length;
  final symptoms = observations
      .expand((o) => o.log.symptoms)
      .where((s) => s != 'None')
      .toSet();
  final summaries = <SymptomCycleSummary>[];
  for (final symptom in symptoms) {
    final matched = observations
        .where((o) => o.log.symptoms.contains(symptom))
        .toList();
    final days = <int, int>{};
    final before = <int, int>{};
    final cycleCounts = <DateTime, int>{};
    final cycleObservedDays = <DateTime, int>{};
    for (final o in observations) {
      cycleObservedDays.update(
        starts[o.cycle],
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    for (final o in matched) {
      days.update(o.day, (n) => n + 1, ifAbsent: () => 1);
      cycleCounts.update(starts[o.cycle], (n) => n + 1, ifAbsent: () => 1);
      if (o.before != null)
        before.update(o.before!, (n) => n + 1, ifAbsent: () => 1);
    }
    summaries.add(
      SymptomCycleSummary(
        symptom,
        matched.map((o) => o.cycle).toSet().length,
        observedCycles,
        observations.length,
        matched.length,
        days,
        before,
        cycleCounts,
        cycleObservedDays,
      ),
    );
  }
  summaries.sort((a, b) => b.daysWithSymptom.compareTo(a.daysWithSymptom));
  return summaries;
}

class PainImpactSummary {
  PainImpactSummary(List<DailyLog> logs) {
    for (final log in logs) {
      if (log.painInterference == null) continue;
      responses++;
      if (log.painInterference == 'Not sure') {
        uncertain++;
        continue;
      }
      assessed++;
      if (log.painInterference != 'No interference') interfered++;
    }
  }
  int responses = 0;
  int assessed = 0;
  int interfered = 0;
  int uncertain = 0;
}
