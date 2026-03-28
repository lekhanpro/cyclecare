import 'package:drift/drift.dart';

class PregnancyData extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get lmpDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get conceptionDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
}

class PregnancyAppointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pregnancyId => integer().references(PregnancyData, #id)();
  TextColumn get title => text()();
  TextColumn get doctorName => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  DateTimeColumn get appointmentDate => dateTime()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class KickCounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pregnancyId => integer().references(PregnancyData, #id)();
  DateTimeColumn get sessionStart => dateTime()();
  DateTimeColumn get sessionEnd => dateTime().nullable()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  IntColumn get targetCount => integer().withDefault(const Constant(10))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Contractions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pregnancyId => integer().references(PregnancyData, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get intervalSeconds => integer().nullable()();
  IntColumn get intensity => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
