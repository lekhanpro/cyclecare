import 'package:intl/intl.dart';

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameDate(DateTime a, DateTime b) => dateOnly(a) == dateOnly(b);

Iterable<DateTime> daysInclusive(DateTime start, DateTime end) sync* {
  var cursor = dateOnly(start);
  final last = dateOnly(end);
  while (!cursor.isAfter(last)) {
    yield cursor;
    cursor = cursor.add(const Duration(days: 1));
  }
}

String monthLabel(DateTime value) => DateFormat('MMMM yyyy').format(value);

String shortDate(DateTime value) => DateFormat('MMM d').format(value);
