import 'package:drift/drift.dart';

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // period, pill, health, appointment
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get time => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get repeatDays => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
