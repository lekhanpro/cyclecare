import 'cycle_models.dart';

/// Counts for one calendar month, shown in the strip above the grid.
///
/// Takes the same `statusFor` / `hasLogFor` the grid paints with, so the
/// numbers always match the cells on screen.
class MonthSummary {
  const MonthSummary({
    required this.periodDays,
    required this.predictedPeriodDays,
    required this.fertileDays,
    required this.loggedDays,
    required this.daysInMonth,
  });

  /// Recorded period days.
  final int periodDays;

  /// Forecast period days, kept apart from [periodDays] so an estimate is
  /// never counted as a record.
  final int predictedPeriodDays;

  /// Fertile window days, including the ovulation day inside it.
  final int fertileDays;
  final int loggedDays;
  final int daysInMonth;

  static MonthSummary of(
    DateTime month, {
    required DayStatus Function(DateTime) statusFor,
    required bool Function(DateTime) hasLogFor,
  }) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    var period = 0, predicted = 0, fertile = 0, logged = 0;
    for (var d = 1; d <= days; d++) {
      final day = DateTime(month.year, month.month, d);
      switch (statusFor(day)) {
        case DayStatus.period:
          period++;
        case DayStatus.predictedPeriod:
          predicted++;
        case DayStatus.fertile:
        case DayStatus.ovulation:
          fertile++;
        case DayStatus.pms:
        case DayStatus.normal:
          break;
      }
      if (hasLogFor(day)) logged++;
    }
    return MonthSummary(
      periodDays: period,
      predictedPeriodDays: predicted,
      fertileDays: fertile,
      loggedDays: logged,
      daysInMonth: days,
    );
  }
}
