# CycleCare Flutter

CycleCare is a privacy-first, AI-powered menstrual cycle and period tracker built with Flutter. It supports both local-only and optional cloud-connected modes via Google Sign-In and Firebase. The app prioritizes user privacy, stores health data locally by default, and never shares data with advertisers or analytics platforms.

## Features

- **Onboarding**: Last period date, average cycle length, and period length setup.
- **Cycle Tracking**: Home screen with cycle day, next expected period, and compact monthly calendar.
- **Calendar**: Full calendar with recorded period days, predicted period, fertile window, and ovulation markers.
- **Daily Logging**: Flow, mood, symptoms, cervical observations, BBT, water intake, sleep, exercise, sexual activity, and notes.
- **Insights**: Cycle statistics, trend charts, symptom frequency, mood patterns, BBT chart, and phase analysis.
- **AI Assistant**: Educational chatbot for menstrual health, fertility, PMS, and wellness. Includes strict privacy controls and medical disclaimers.
- **Reminders**: Local notifications for period, ovulation, pill, and custom reminders with full management UI.
- **Privacy & Security**: PIN / biometric app lock, hide-in-app-switcher mode, data export (JSON), and complete local data deletion.
- **Partner Sharing**: Optional Firestore-based sharing with granular permission controls and invite codes.
- **Cloud Sync**: Optional Google OAuth + Firebase Auth with two-way Firestore sync (local-first design).
- **Adaptive Predictions**: Weighted moving average predictions with irregular cycle support, perimenopause mode, and amenorrhea detection banners.

## Requirements

- Flutter 3.16 or newer
- Dart 3.2 or newer
- Android SDK for Android builds
- Xcode and CocoaPods on macOS for iOS builds
- Java 17 for Android builds

## Architecture

```text
lib/
  core/
    constants/        App constants (modes, symptoms, thresholds)
    providers/        Auth providers (Firebase Auth, Google Sign-In)
    services/         AI, notification, security, partner services
    theme/            Material 3 light & dark themes
    utils/            Date helpers
  data/
    database/         AppDatabase (SharedPreferences-backed with in-memory cache)
  domain/
    entities/         Period, DailyLog, AmenorrheaResult models
    engines/          CyclePredictionEngine (weighted moving average)
  features/
    ai/               AI chat screen
    app/              CycleCareApp root widget, MainShell navigation
    auth/             Landing screen with Google Sign-In and local-only option
    onboarding/       Onboarding flow
    partner/          Partner sharing dashboard and linking UI
    reminders/        Reminder management screen
    settings/         Settings with app lock, AI toggles, theme, data export/delete
    tracking/         Home, calendar, log, and insights screens
  presentation/       Legacy routing and providers (being consolidated into features/)
  widgets/            Reusable UI components
```

State management uses **Riverpod** with `StateNotifierProvider` for persistence-critical settings and `FutureProvider`/`StreamProvider` for async data. The data layer is local-first: all cycle and health data is stored on-device via `AppDatabase`. Optional Firebase sync pushes/pulls data only when the user is signed in.

## Setup

### 1. Install Flutter dependencies

```bash
cd cyclecare_flutter
flutter pub get
```

### 2. Configure Firebase (optional, for cloud sync and partner sharing)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add an Android app with your package name.
3. Download `google-services.json` and place it in `android/app/`.
4. Enable **Authentication** > **Google** sign-in provider.
5. Enable **Cloud Firestore** and create these collections: `partner_links`, `shared_cycle_data`, `user_cycles`, `user_daily_logs`.
6. Set Firestore security rules (see `docs/firestore_rules.md`).

### 3. Configure AI provider (optional, for AI assistant)

Create a `.env` file in `cyclecare_flutter/` with:

```bash
AI_API_KEY=your-openai-compatible-api-key
AI_BASE_URL=https://api.openai.com
```

Or pass them at build time:

```bash
flutter build apk --debug --dart-define=AI_API_KEY=your-key --dart-define=AI_BASE_URL=https://api.openai.com
```

If no key is provided, the AI assistant will show an offline/disabled state.

### 4. Configure Android build

In `android/app/build.gradle`, ensure:

```groovy
android {
    compileSdk 34
    defaultConfig {
        minSdkVersion 23
        targetSdkVersion 34
    }
}
```

## Run

```bash
flutter run
```

## Build

### Android Debug APK

```bash
flutter build apk --debug
```

### Android Release APK

```bash
flutter build apk --release
```

### iOS (macOS required)

```bash
cd ios
pod install
cd ..
flutter run -d ios
```

## Testing

```bash
flutter test
```

Key test coverage:
- `test/domain/engines/cycle_prediction_engine_test.dart` — cycle prediction logic
- `test/domain/entities/amenorrhea_result_test.dart` — amenorrhea severity rules
- `test/core/services/ai_service_test.dart` — AI context builder privacy checks
- `test/core/services/partner_service_test.dart` — partner permissions logic
- `test/presentation/screens/home_screen_test.dart` — widget rendering

## CI/CD

GitHub Actions workflows are in `.github/workflows/flutter_ci.yml`:

- **Analyze**: `flutter analyze --no-fatal-infos`
- **Test**: `flutter test`
- **Build Android (Debug)**: `flutter build apk --debug`
- **Build Android (Release)**: `flutter build apk --release`
- **Build Web**: `flutter build web`
- **Build iOS**: `flutter build ios --release --no-codesign`

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes with tests.
4. Run `flutter analyze` and `flutter test` locally.
5. Submit a pull request.

Please follow the existing code style and keep the privacy-first design principles in mind.

## Privacy & Security

- All cycle and health data is stored **locally** by default.
- Cloud sync is **opt-in** via Google Sign-In.
- AI assistant uses privacy-safe context building: personal data is only shared with the AI if the user explicitly enables it.
- App lock (PIN / biometric) and hide-in-app-switcher mode are available for sensitive environments.
- Data export (JSON) and complete local deletion are available in Settings.

## License

MIT License — see `LICENSE` for details.
