import 'package:flutter_test/flutter_test.dart';
import 'package:cyclecare/core/utils/date_helpers.dart';

void main() {
  group('dateOnly', () {
    test('strips time component', () {
      final dt = DateTime(2024, 3, 15, 14, 30, 45);
      final result = dateOnly(dt);
      expect(result, DateTime(2024, 3, 15));
    });

    test('same day returns equal', () {
      final a = DateTime(2024, 3, 15, 8, 0);
      final b = DateTime(2024, 3, 15, 22, 59);
      expect(dateOnly(a), equals(dateOnly(b)));
    });
  });

  group('isSameDate', () {
    test('same date returns true', () {
      final a = DateTime(2024, 3, 15, 8, 0);
      final b = DateTime(2024, 3, 15, 22, 0);
      expect(isSameDate(a, b), isTrue);
    });

    test('different date returns false', () {
      final a = DateTime(2024, 3, 15);
      final b = DateTime(2024, 3, 16);
      expect(isSameDate(a, b), isFalse);
    });
  });

  group('shortDate', () {
    test('formats date correctly', () {
      final dt = DateTime(2024, 3, 15);
      final result = shortDate(dt);
      expect(result, isNotEmpty);
    });
  });
}
