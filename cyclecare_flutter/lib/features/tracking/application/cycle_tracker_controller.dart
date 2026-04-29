import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_helpers.dart';
import '../data/cycle_repository.dart';
import '../domain/cycle_models.dart';
import '../domain/cycle_prediction_service.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final cycleRepositoryProvider = FutureProvider<CycleRepository>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return CycleRepository(preferences);
});

final cycleTrackerControllerProvider =
    AsyncNotifierProvider<CycleTrackerController, CycleTrackerState>(
  CycleTrackerController.new,
);

class CycleTrackerState {
  const CycleTrackerState({
    required this.periods,
    required this.logs,
    required this.preferences,
    required this.prediction,
    required this.selectedDate,
  });

  final List<CycleEvent> periods;
  final List<DailyLog> logs;
  final CyclePreferences preferences;
  final CyclePrediction? prediction;
  final DateTime selectedDate;

  DailyLog? logFor(DateTime date) {
    final target = dateOnly(date);
    for (final log in logs) {
      if (dateOnly(log.date) == target) {
        return log;
      }
    }
    return null;
  }

  DayStatus statusFor(DateTime day) {
    final target = dateOnly(day);
    for (final period in periods) {
      final end = period.endDate ??
          period.startDate.add(Duration(days: preferences.averagePeriodLength - 1));
      if (!target.isBefore(dateOnly(period.startDate)) && !target.isAfter(dateOnly(end))) {
        return DayStatus.period;
      }
    }

    final forecast = prediction;
    if (forecast == null) {
      return DayStatus.normal;
    }
    if (isSameDate(target, forecast.ovulationDate)) {
      return DayStatus.ovulation;
    }
    if (!target.isBefore(forecast.fertileWindowStart) &&
        !target.isAfter(forecast.fertileWindowEnd)) {
      return DayStatus.fertile;
    }
    if (!target.isBefore(forecast.nextPeriodStart) &&
        !target.isAfter(forecast.nextPeriodEnd)) {
      return DayStatus.predictedPeriod;
    }
    return DayStatus.normal;
  }

  CycleTrackerState copyWith({
    List<CycleEvent>? periods,
    List<DailyLog>? logs,
    CyclePreferences? preferences,
    CyclePrediction? prediction,
    DateTime? selectedDate,
  }) {
    return CycleTrackerState(
      periods: periods ?? this.periods,
      logs: logs ?? this.logs,
      preferences: preferences ?? this.preferences,
      prediction: prediction ?? this.prediction,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class CycleTrackerController extends AsyncNotifier<CycleTrackerState> {
  final _predictionService = const CyclePredictionService();

  @override
  Future<CycleTrackerState> build() async {
    final repository = await ref.watch(cycleRepositoryProvider.future);
    final periods = repository.loadPeriods();
    final preferences = repository.loadPreferences();
    final logs = repository.loadLogs();
    return _buildState(
      periods: periods,
      logs: logs,
      preferences: preferences,
      selectedDate: DateTime.now(),
    );
  }

  Future<void> selectDate(DateTime date) async {
    final current = await future;
    state = AsyncData(current.copyWith(selectedDate: dateOnly(date)));
  }

  Future<void> saveLog(DailyLog log) async {
    final current = await future;
    final repository = await ref.read(cycleRepositoryProvider.future);
    final target = dateOnly(log.date);
    final logs = [
      for (final existing in current.logs)
        if (dateOnly(existing.date) != target) existing,
      log.copyWith(date: target),
    ]..sort((a, b) => b.date.compareTo(a.date));
    await repository.saveLogs(logs);
    state = AsyncData(current.copyWith(logs: logs, selectedDate: target));
  }

  Future<void> logPeriodStart(DateTime startDate) async {
    final current = await future;
    final repository = await ref.read(cycleRepositoryProvider.future);
    final start = dateOnly(startDate);
    final event = CycleEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startDate: start,
      endDate: start.add(Duration(days: current.preferences.averagePeriodLength - 1)),
    );
    final periods = [event, ...current.periods]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    await repository.savePeriods(periods);
    state = AsyncData(_buildState(
      periods: periods,
      logs: current.logs,
      preferences: current.preferences,
      selectedDate: start,
    ));
  }

  Future<void> updatePreferences(CyclePreferences preferences) async {
    final current = await future;
    final repository = await ref.read(cycleRepositoryProvider.future);
    await repository.savePreferences(preferences);
    state = AsyncData(_buildState(
      periods: current.periods,
      logs: current.logs,
      preferences: preferences,
      selectedDate: current.selectedDate,
    ));
  }

  Future<void> completeOnboarding({
    required DateTime lastPeriodStart,
    required int cycleLength,
    required int periodLength,
  }) async {
    final repository = await ref.read(cycleRepositoryProvider.future);
    final start = dateOnly(lastPeriodStart);
    final preferences = CyclePreferences(
      averageCycleLength: cycleLength,
      averagePeriodLength: periodLength,
      onboardingCompleted: true,
    );
    final period = CycleEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startDate: start,
      endDate: start.add(Duration(days: periodLength - 1)),
    );
    await repository.savePreferences(preferences);
    await repository.savePeriods([period]);
    state = AsyncData(_buildState(
      periods: [period],
      logs: const [],
      preferences: preferences,
      selectedDate: DateTime.now(),
    ));
  }

  Future<String> exportJson() async {
    final repository = await ref.read(cycleRepositoryProvider.future);
    return repository.exportJson();
  }

  Future<void> deleteAllData() async {
    final repository = await ref.read(cycleRepositoryProvider.future);
    await repository.deleteAll();
    state = AsyncData(_buildState(
      periods: const [],
      logs: const [],
      preferences: const CyclePreferences(),
      selectedDate: DateTime.now(),
    ));
  }

  CycleTrackerState _buildState({
    required List<CycleEvent> periods,
    required List<DailyLog> logs,
    required CyclePreferences preferences,
    required DateTime selectedDate,
  }) {
    final prediction = _predictionService.buildPrediction(
      periods: periods,
      preferences: preferences,
    );
    return CycleTrackerState(
      periods: periods,
      logs: logs,
      preferences: preferences,
      prediction: prediction,
      selectedDate: dateOnly(selectedDate),
    );
  }
}
