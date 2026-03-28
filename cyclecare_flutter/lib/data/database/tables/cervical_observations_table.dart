import 'package:drift/drift.dart';

class CervicalObservations extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mucusType => text().withDefault(const Constant(''))();
  TextColumn get position => text().withDefault(const Constant(''))();
  TextColumn get firmness => text().withDefault(const Constant(''))();
  TextColumn get opening => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
