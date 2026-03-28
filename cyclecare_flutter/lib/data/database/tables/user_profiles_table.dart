import 'package:drift/drift.dart';

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get avatar => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get pin => text().withDefault(const Constant(''))();
  BoolColumn get biometricEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get mode => text().withDefault(const Constant('track_periods'))();
  IntColumn get cycleLength => integer().withDefault(const Constant(28))();
  IntColumn get periodLength => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PartnerSharing extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(UserProfiles, #id)();
  TextColumn get partnerEmail => text()();
  TextColumn get inviteCode => text()();
  BoolColumn get isAccepted => boolean().withDefault(const Constant(false))();
  BoolColumn get shareCyclePhase => boolean().withDefault(const Constant(true))();
  BoolColumn get sharePeriodPrediction => boolean().withDefault(const Constant(true))();
  BoolColumn get shareMoodSummary => boolean().withDefault(const Constant(false))();
  BoolColumn get shareSymptoms => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class EducationalBookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get articleId => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
