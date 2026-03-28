import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/daily_log_repository.dart';

// Daily log state
class DailyLogState {
  final DailyLog? currentLog;
  final DateTime selectedDate;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  DailyLogState({
    this.currentLog,
    required this.selectedDate,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  DailyLogState copyWith({
    DailyLog? currentLog,
    DateTime? selectedDate,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) {
    return DailyLogState(
      currentLog: currentLog ?? this.currentLog,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Daily log notifier
class DailyLogNotifier extends StateNotifier<DailyLogState> {
  final DailyLogRepository _dailyLogRepository;

  DailyLogNotifier(this._dailyLogRepository)
      : super(DailyLogState(selectedDate: DateTime.now())) {
    loadLogForDate(DateTime.now());
  }

  Future<void> loadLogForDate(DateTime date) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedDate: date,
    );
    
    try {
      final log = await _dailyLogRepository.getDailyLogByDate(date);
      state = state.copyWith(
        currentLog: log,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> saveLog({
    String? flow,
    String? mood,
    List<String>? symptoms,
    String? notes,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    
    try {
      final log = DailyLog(
        id: state.currentLog?.id ?? 0,
        date: state.selectedDate,
        flow: flow ?? state.currentLog?.flow,
        mood: mood ?? state.currentLog?.mood,
        symptoms: symptoms ?? state.currentLog?.symptoms ?? [],
        notes: notes ?? state.currentLog?.notes ?? '',
      );

      if (state.currentLog == null) {
        await _dailyLogRepository.insertDailyLog(log);
      } else {
        await _dailyLogRepository.updateDailyLog(log);
      }

      await loadLogForDate(state.selectedDate);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Log saved successfully',
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isSaving: false,
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(
      error: null,
      successMessage: null,
    );
  }

  void selectDate(DateTime date) {
    loadLogForDate(date);
  }
}

// Provider
final dailyLogProvider =
    StateNotifierProvider<DailyLogNotifier, DailyLogState>((ref) {
  final dailyLogRepository = ref.watch(dailyLogRepositoryProvider);
  return DailyLogNotifier(dailyLogRepository);
});

// Stream provider for watching all logs
final dailyLogsStreamProvider = StreamProvider<List<DailyLog>>((ref) {
  final dailyLogRepository = ref.watch(dailyLogRepositoryProvider);
  return dailyLogRepository.watchAllDailyLogs();
});
