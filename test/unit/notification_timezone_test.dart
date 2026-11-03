import 'package:cyclecare/core/services/notification_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'Android legacy IANA timezone aliases retain their real scheduling offset',
    () {
      final calcutta = notificationTimeZone('Asia/Calcutta');
      final kolkata = notificationTimeZone('Asia/Kolkata');
      final legacyPacific = notificationTimeZone('US/Pacific');
      final pacific = notificationTimeZone('America/Los_Angeles');
      final date = DateTime.utc(2026, 11, 3);
      expect(
        tz.TZDateTime.from(date, calcutta).timeZoneOffset,
        tz.TZDateTime.from(date, kolkata).timeZoneOffset,
      );
      expect(tz.TZDateTime.from(date, calcutta).hour, 5);
      expect(tz.TZDateTime.from(date, calcutta).minute, 30);
      expect(
        tz.TZDateTime.from(date, legacyPacific).timeZoneOffset,
        tz.TZDateTime.from(date, pacific).timeZoneOffset,
      );
      expect(
        tz.TZDateTime(legacyPacific, 2026, 7, 1).timeZoneOffset,
        isNot(tz.TZDateTime(legacyPacific, 2026, 1, 1).timeZoneOffset),
      );
    },
  );
}
