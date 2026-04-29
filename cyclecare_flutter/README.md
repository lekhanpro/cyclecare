# CycleCare Flutter

CycleCare is a privacy-first menstrual cycle and period tracker built with Flutter. The current production scope is intentionally focused: onboarding, cycle prediction, a calendar-centric home screen, daily symptom logging, and basic settings.

## Requirements

- Flutter 3.16 or newer
- Dart 3.2 or newer
- Android SDK for Android builds
- Xcode and CocoaPods on macOS for iOS builds

## Tech Choices

- `flutter_riverpod`: app state, dependency injection, and screen updates.
- `shared_preferences`: simple offline persistence for periods, logs, and settings.
- `intl`: date labels and month formatting.
- `cupertino_icons`: iOS-style tab and action icons.

The app does not require an account, network API, analytics, or cloud sync.

## Project Structure

```text
lib/
  main.dart
  core/
    theme/
    utils/
  features/
    app/
    onboarding/
    settings/
    tracking/
      application/
      data/
      domain/
      presentation/
  widgets/
```

## Features

- Onboarding for last period date, average cycle length, and period length.
- Home screen with cycle day, next expected period, and compact monthly calendar.
- Full calendar with recorded period days, predicted period, fertile window, and ovulation marker.
- Daily log form for flow, mood, symptoms, and notes.
- Settings for cycle defaults, reminder UI, JSON export preview, and local data deletion.
- Local-only persistence with `SharedPreferences`.

## Run

```bash
flutter pub get
flutter run
```

## Android

```bash
flutter build apk --debug
flutter build apk --release
```

## iOS

Run from macOS:

```bash
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
```

## Notes

The original Kotlin Android app remains in the repository as source material for future feature ports such as notifications, biometric lock, birth-control tracking, pregnancy mode, and richer insights.
