import 'package:cyclecare/features/tracking/domain/cycle_models.dart';
import 'package:cyclecare/features/tracking/domain/month_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts each state over the month it is given', () {
    DayStatus status(DateTime d) {
      if (d.day <= 5) return DayStatus.period;
      if (d.day >= 10 && d.day <= 15) return DayStatus.fertile;
      if (d.day == 16) return DayStatus.ovulation;
      if (d.day >= 28) return DayStatus.predictedPeriod;
      if (d.day >= 23) return DayStatus.pms;
      return DayStatus.normal;
    }

    final s = MonthSummary.of(
      DateTime(2026, 10),
      statusFor: status,
      hasLogFor: (d) => d.day.isEven,
    );

    expect(s.daysInMonth, 31);
    expect(s.periodDays, 5);
    expect(s.fertileDays, 7); // 10-15 plus ovulation on the 16th
    expect(s.predictedPeriodDays, 4); // 28-31
    expect(s.loggedDays, 15);
  });

  test('February uses its real length', () {
    final s = MonthSummary.of(
      DateTime(2028, 2),
      statusFor: (_) => DayStatus.normal,
      hasLogFor: (_) => true,
    );
    expect(s.daysInMonth, 29); // 2028 is a leap year
    expect(s.loggedDays, 29);
  });
}
