import 'package:drift/drift.dart';

class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get theme => text().withDefault(const Constant('system'))();
  TextColumn get primaryColor => text().withDefault(const Constant('#E91E63'))();
  IntColumn get averageCycleLength => integer().withDefault(const Constant(28))();
  IntColumn get averagePeriodLength => integer().withDefault(const Constant(5))();
  IntColumn get lutealPhaseLength => integer().withDefault(const Constant(14))();
  TextColumn get temperatureUnit => text().withDefault(const Constant('celsius'))();
  TextColumn get dateFormat => text().withDefault(const Constant('MMM dd, yyyy'))();
  TextColumn get language => text().withDefault(const Constant('en'))();
  BoolColumn get isPinEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get pinHash => text().withDefault(const Constant(''))();
  BoolColumn get isBiometricEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get isPrivacyModeEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get hideNotificationContent => boolean().withDefault(const Constant(true))();
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get quietHoursEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get quietHoursStart => text().withDefault(const Constant('22:00'))();
  TextColumn get quietHoursEnd => text().withDefault(const Constant('07:00'))();
  BoolColumn get onboardingCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get profileName => text().withDefault(const Constant(''))();
  IntColumn get profileBirthYear => integer().nullable()();
  BoolColumn get profileTryingToConceive => boolean().withDefault(const Constant(false))();
  BoolColumn get pregnancyMode => boolean().withDefault(const Constant(false))();
  BoolColumn get breastfeedingMode => boolean().withDefault(const Constant(false))();
  BoolColumn get menopauseMode => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}
