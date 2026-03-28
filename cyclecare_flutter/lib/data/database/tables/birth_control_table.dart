import 'package:drift/drift.dart';

class BirthControl extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get pillTime => text().nullable()();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
