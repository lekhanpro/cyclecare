import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static DateTime get today => DateTime.now().dateOnly;

  static String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  static String formatShortDate(DateTime date) => DateFormat('MMM d').format(date);
  static String formatDayMonth(DateTime date) => DateFormat('d MMM').format(date);
  static String formatFullDate(DateTime date) => DateFormat('EEEE, MMMM d, yyyy').format(date);
  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

  static int daysBetween(DateTime a, DateTime b) =>
      b.dateOnly.difference(a.dateOnly).inDays;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int gestationalAgeInDays(DateTime lmpDate) =>
      today.difference(lmpDate.dateOnly).inDays;

  static int gestationalAgeInWeeks(DateTime lmpDate) =>
      gestationalAgeInDays(lmpDate) ~/ 7;

  static DateTime estimatedDueDate(DateTime lmpDate) =>
      lmpDate.add(const Duration(days: 280));

  static int cycleDay(DateTime periodStart) =>
      today.difference(periodStart.dateOnly).inDays + 1;

  static String cyclePhaseName(int cycleDay, int cycleLength, int periodLength) {
    if (cycleDay <= periodLength) return 'Menstrual';
    final ovulationDay = cycleLength - 14;
    if (cycleDay < ovulationDay - 2) return 'Follicular';
    if (cycleDay <= ovulationDay + 2) return 'Ovulation';
    return 'Luteal';
  }

  static bool isInFertileWindow(int cycleDay, int cycleLength) {
    final ovulationDay = cycleLength - 14;
    return cycleDay >= ovulationDay - 5 && cycleDay <= ovulationDay + 1;
  }

  static int daysUntilNextPeriod(DateTime lastPeriodStart, int cycleLength) {
    final nextPeriod = lastPeriodStart.add(Duration(days: cycleLength));
    final days = nextPeriod.difference(today).inDays;
    return days < 0 ? 0 : days;
  }
}

extension DateTimeExtension on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isFuture => isAfter(DateTime.now());
  bool get isPast => isBefore(DateTime.now().dateOnly);
}
