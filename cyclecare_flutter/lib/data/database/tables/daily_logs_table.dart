import 'package:drift/drift.dart';

class DailyLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  TextColumn get flow => text().nullable()();
  TextColumn get mood => text().nullable()();
  TextColumn get symptoms => text().withDefault(const Constant('[]'))();
  TextColumn get discharge => text().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get temperature => real().nullable()();
  TextColumn get ovulationTest => text().withDefault(const Constant(''))();
  TextColumn get pregnancyTest => text().withDefault(const Constant(''))();
  BoolColumn get intimacy => boolean().withDefault(const Constant(false))();
  IntColumn get waterMl => integer().withDefault(const Constant(0))();
  TextColumn get cervicalMucus => text().nullable()();
  BoolColumn get sexualActivity => boolean().withDefault(const Constant(false))();
  RealColumn get sleepHours => real().nullable()();
  IntColumn get exerciseMinutes => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
