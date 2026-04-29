# CycleCare Flutter Migration Analysis

## Overview
This document outlines the migration of CycleCare from Android (Kotlin + Jetpack Compose) to Flutter.

## Architecture Comparison

### Android (Original)
- **Language**: Kotlin
- **UI**: Jetpack Compose
- **Architecture**: MVVM + Clean Architecture
- **Database**: Room (SQLite)
- **DI**: Hilt / Dagger
- **State Management**: StateFlow / Flow
- **Async**: Coroutines
- **Notifications**: WorkManager

### Flutter (Migrated)
- **Language**: Dart
- **UI**: Flutter Widgets
- **Architecture**: Clean Architecture + Riverpod
- **Database**: Drift (SQLite)
- **DI**: Riverpod Providers
- **State Management**: Riverpod
- **Async**: Future / Stream
- **Notifications**: flutter_local_notifications

## Feature Parity

### Implemented ✅
1. **Onboarding Flow**
   - Welcome screen with privacy features
   - Last period date selection
   - Cycle length configuration
   - Period length configuration
   - Goal selection (track periods, TTC, pregnancy, perimenopause)

2. **Calendar Screen**
   - Interactive calendar view
   - Cycle day counter
   - Period countdown
   - Fertility status
   - Quick log actions

3. **Daily Log Screen**
   - Flow tracking
   - Mood tracking
   - Symptom tracking
   - Notes
   - Date selection

4. **Insights Screen**
   - Cycle statistics
   - Trend charts
   - Symptom frequency analysis
   - Regularity scoring

5. **Settings Screen**
   - Privacy & security settings
   - Notification preferences
   - Cycle configuration
   - Data export/delete
   - About information

### To Be Implemented 🚧
1. **Database Integration**
   - Complete Drift database setup
   - Repository implementations
   - Data persistence

2. **Amenorrhea Detection**
   - Detection engine
   - Alert UI
   - Severity levels
   - Recommendations

3. **Notifications**
   - Period reminders
   - Pill reminders
   - Health reminders
   - Notification channels

4. **Authentication**
   - PIN lock
   - Biometric authentication
   - Privacy mode

5. **Birth Control Tracking**
   - Pill tracking
   - Reminder system
   - Streak tracking

6. **Education Cards**
   - Health education content
   - Multilingual support
   - Contextual triggering

7. **Data Export**
   - CSV export
   - JSON export
   - Backup/restore

## Database Schema

### Tables
1. **periods**
   - id, startDate, endDate, symptoms, notes, createdAt

2. **daily_logs**
   - id, date, flow, mood, symptoms, discharge, weightKg, temperature
   - ovulationTest, pregnancyTest, intimacy, waterMl, cervicalMucus
   - sexualActivity, sleepHours, exerciseMinutes, notes, createdAt

3. **reminders**
   - id, type, title, message, time, enabled, repeatDays, createdAt

4. **settings**
   - id, theme, primaryColor, averageCycleLength, averagePeriodLength
   - lutealPhaseLength, temperatureUnit, dateFormat, language
   - isPinEnabled, pinHash, isBiometricEnabled, isPrivacyModeEnabled
   - hideNotificationContent, notificationsEnabled, quietHoursEnabled
   - quietHoursStart, quietHoursEnd, onboardingCompleted
   - profileName, profileBirthYear, profileTryingToConceive
   - pregnancyMode, breastfeedingMode, menopauseMode

5. **birth_control**
   - id, type, startDate, endDate, pillTime, reminderEnabled, notes, createdAt

## Key Differences

### State Management
- **Android**: ViewModel + StateFlow
- **Flutter**: Riverpod StateNotifier / AsyncNotifier

### Navigation
- **Android**: Jetpack Navigation Compose
- **Flutter**: Navigator 2.0 / go_router

### Dependency Injection
- **Android**: Hilt annotations
- **Flutter**: Riverpod providers

### Database
- **Android**: Room with annotations
- **Flutter**: Drift with code generation

## Migration Benefits

1. **Cross-Platform**: Single codebase for Android and iOS
2. **Hot Reload**: Faster development iteration
3. **Rich UI**: Flutter's widget system
4. **Performance**: Compiled to native code
5. **Community**: Large package ecosystem

## Privacy Guarantees (Maintained)

- ✅ 100% local storage
- ✅ No cloud sync
- ✅ No analytics or telemetry
- ✅ No internet permission required
- ✅ PIN + biometric lock
- ✅ Full data export capability

## Next Steps

1. Complete database integration with Drift
2. Implement Riverpod providers for state management
3. Add amenorrhea detection engine
4. Implement notification system
5. Add authentication (PIN + biometric)
6. Implement data export functionality
7. Add comprehensive testing
8. Optimize performance
9. Add localization support
10. Prepare for production release

## Testing Strategy

1. **Unit Tests**: Business logic, repositories, use cases
2. **Widget Tests**: UI components, screens
3. **Integration Tests**: End-to-end flows
4. **Golden Tests**: Visual regression testing

## Build & Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
flutter build ipa --release
```

## Authors

- Lekhan HR (Original Android version + Flutter migration)
- Mithun Gowda B <mithungowda.b7411@gmail.com> (Co-author)

## License

MIT License - Same as original Android version
