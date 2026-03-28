import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../domain/entities/period.dart';
import '../../domain/repositories/period_repository.dart';

// Calendar state
class CalendarState {
  final List<Period> periods;
  final DateTime selectedDate;
  final bool isLoading;
  final String? error;

  CalendarState({
    this.periods = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    List<Period>? periods,
    DateTime? selectedDate,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      periods: periods ?? this.periods,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Calendar notifier
class CalendarNotifier extends StateNotifier<CalendarState> {
  final PeriodRepository _periodRepository;

  CalendarNotifier(this._periodRepository)
      : super(CalendarState(selectedDate: DateTime.now())) {
    loadPeriods();
  }

  Future<void> loadPeriods() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final periods = await _periodRepository.getAllPeriods();
      state = state.copyWith(periods: periods, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  Future<void> addPeriod(DateTime startDate, DateTime? endDate) async {
    try {
      final period = Period(
        id: 0, // Will be auto-generated
        startDate: startDate,
        endDate: endDate,
      );
      await _periodRepository.insertPeriod(period);
      await loadPeriods();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updatePeriod(Period period) async {
    try {
      await _periodRepository.updatePeriod(period);
      await loadPeriods();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deletePeriod(int id) async {
    try {
      await _periodRepository.deletePeriod(id);
      await loadPeriods();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Period? getPeriodForDate(DateTime date) {
    for (final period in state.periods) {
      if (date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          (period.endDate == null ||
              date.isBefore(period.endDate!.add(const Duration(days: 1))))) {
        return period;
      }
    }
    return null;
  }

  int? getCycleDayForDate(DateTime date) {
    final lastPeriod = _getLastPeriodBefore(date);
    if (lastPeriod == null) return null;
    return date.difference(lastPeriod.startDate).inDays + 1;
  }

  int? getDaysUntilNextPeriod(DateTime date) {
    final lastPeriod = _getLastPeriodBefore(date);
    if (lastPeriod == null) return null;
    
    // Assuming 28-day cycle (should come from settings)
    const averageCycleLength = 28;
    final nextPeriodDate = lastPeriod.startDate.add(Duration(days: averageCycleLength));
    final daysUntil = nextPeriodDate.difference(date).inDays;
    
    return daysUntil > 0 ? daysUntil : null;
  }

  Period? _getLastPeriodBefore(DateTime date) {
    final periodsBeforeDate = state.periods
        .where((p) => p.startDate.isBefore(date.add(const Duration(days: 1))))
        .toList();
    
    if (periodsBeforeDate.isEmpty) return null;
    
    periodsBeforeDate.sort((a, b) => b.startDate.compareTo(a.startDate));
    return periodsBeforeDate.first;
  }
}

// Provider
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final periodRepository = ref.watch(periodRepositoryProvider);
  return CalendarNotifier(periodRepository);
});

// Stream provider for watching periods
final periodsStreamProvider = StreamProvider<List<Period>>((ref) {
  final periodRepository = ref.watch(periodRepositoryProvider);
  return periodRepository.watchAllPeriods();
});
