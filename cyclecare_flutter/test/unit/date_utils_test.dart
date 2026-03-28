import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare_flutter/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('daysBetween calculates correctly', () {
      final a = DateTime(2026, 1, 1);
      final b = DateTime(2026, 1, 15);
      expect(AppDateUtils.daysBetween(a, b), 14);
    });

    test('isSameDay returns true for same day', () {
      final a = DateTime(2026, 3, 28, 10, 30);
      final b = DateTime(2026, 3, 28, 22, 15);
      expect(AppDateUtils.isSameDay(a, b), true);
    });

    test('isSameDay returns false for different days', () {
      final a = DateTime(2026, 3, 28);
      final b = DateTime(2026, 3, 29);
      expect(AppDateUtils.isSameDay(a, b), false);
    });

    test('gestationalAgeInWeeks calculates correctly', () {
      final lmp = DateTime.now().subtract(const Duration(days: 70));
      expect(AppDateUtils.gestationalAgeInWeeks(lmp), 10);
    });

    test('estimatedDueDate is 280 days from LMP', () {
      final lmp = DateTime(2026, 1, 1);
      final due = AppDateUtils.estimatedDueDate(lmp);
      expect(due.difference(lmp).inDays, 280);
    });

    test('cyclePhaseName returns correct phases', () {
      expect(AppDateUtils.cyclePhaseName(1, 28, 5), 'Menstrual');
      expect(AppDateUtils.cyclePhaseName(5, 28, 5), 'Menstrual');
      expect(AppDateUtils.cyclePhaseName(8, 28, 5), 'Follicular');
      expect(AppDateUtils.cyclePhaseName(14, 28, 5), 'Ovulation');
      expect(AppDateUtils.cyclePhaseName(20, 28, 5), 'Luteal');
    });

    test('isInFertileWindow detects fertile days', () {
      expect(AppDateUtils.isInFertileWindow(9, 28), true); // ovDay=14, window 9-15
      expect(AppDateUtils.isInFertileWindow(14, 28), true);
      expect(AppDateUtils.isInFertileWindow(5, 28), false);
      expect(AppDateUtils.isInFertileWindow(20, 28), false);
    });

    test('daysUntilNextPeriod calculates correctly', () {
      final lastPeriod = DateTime.now().subtract(const Duration(days: 20));
      expect(AppDateUtils.daysUntilNextPeriod(lastPeriod, 28), 8);
    });
  });

  group('DateTimeExtension', () {
    test('dateOnly strips time', () {
      final dt = DateTime(2026, 3, 28, 14, 30, 45);
      final dateOnly = dt.dateOnly;
      expect(dateOnly.hour, 0);
      expect(dateOnly.minute, 0);
      expect(dateOnly.second, 0);
    });

    test('isToday returns true for today', () {
      expect(DateTime.now().isToday, true);
    });
  });
}
