import 'package:drift/drift.dart';

class HealthConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get conditionType => text()(); // PCOS, Endometriosis, PMDD
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get diagnosedDate => dateTime().nullable()();
  TextColumn get medications => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class HealthConditionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conditionId => integer().references(HealthConditions, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get severityScore => integer().withDefault(const Constant(5))(); // 1-10
  TextColumn get symptoms => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get painLocations => text().withDefault(const Constant('[]'))(); // JSON body locations
  IntColumn get painIntensity => integer().withDefault(const Constant(0))(); // 0-10
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class HealthData extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weight => real().nullable()();
  RealColumn get bmi => real().nullable()();
  RealColumn get waterIntakeMl => real().withDefault(const Constant(0))();
  RealColumn get sleepHours => real().nullable()();
  IntColumn get sleepQuality => integer().nullable()(); // 1-5
  TextColumn get exerciseType => text().withDefault(const Constant(''))();
  IntColumn get exerciseMinutes => integer().withDefault(const Constant(0))();
  RealColumn get temperature => real().nullable()(); // BBT
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
