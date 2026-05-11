# CycleCare

A beautiful, privacy-first menstrual cycle tracking app. The actively developed Android app is now the Flutter project in `cyclecare_flutter/`; the original Kotlin/Jetpack Compose implementation remains in `app/` as the legacy native Android version.

[![Build APK](https://github.com/lekhanpro/cyclecare/actions/workflows/build-apk.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/build-apk.yml)
[![Deploy Pages](https://github.com/lekhanpro/cyclecare/actions/workflows/pages.yml/badge.svg)](https://lekhanpro.github.io/cyclecare/)
![Android](https://img.shields.io/badge/Android-7.0%2B-green)
![Flutter](https://img.shields.io/badge/Flutter-3.16%2B-blue)
![License](https://img.shields.io/badge/license-MIT-pink)

**[Landing Page](https://lekhanpro.github.io/cyclecare/)** | **[Download APK](https://github.com/lekhanpro/cyclecare/releases)** | **[Report Issue](https://github.com/lekhanpro/cyclecare/issues)**

---

## Features

**Cycle Tracking**
- Interactive calendar with color-coded period, fertile, and ovulation days
- AI-powered cycle predictions with confidence scoring
- Fertility window and ovulation tracking
- Cycle day counter and period countdown

**Daily Logging**
- 40+ symptom tracking options
- Mood, flow intensity, and discharge logging
- Body metrics: weight, temperature (BBT), sleep, water intake
- Intimacy logging and ovulation/pregnancy test results
- Notes and custom entries

**Health & Insights**
- Cycle length and period trend charts
- Symptom frequency analysis and mood patterns
- Temperature and weight trend visualization
- Cycle regularity scoring
- Birth control and pill tracking
- Health data monitoring

**Privacy & Security**
- 100% local storage — data never leaves your device
- PIN lock and biometric (fingerprint/face) authentication
- Data export in CSV and JSON formats
- No account required, no ads, no tracking

**Reminders**
- Period, pill, and hydration reminders
- Quiet hours support
- Customizable notification channels

## Tech Stack

| Layer | Active Flutter App |
|-------|--------------------|
| Language | Dart |
| UI | Flutter Material/Cupertino widgets |
| Architecture | Riverpod + feature-first clean structure |
| Storage | Local-first SharedPreferences repository |
| Optional Sync | Firebase Auth / Firestore |
| Notifications | flutter_local_notifications |
| Security | PIN / biometric via local_auth |
| Build | Flutter Android |

## Project Structure

```
cyclecare_flutter/lib/
  core/          # services, theme, providers, utilities
  features/      # active app screens and tracking flows
  data/          # local database compatibility layer
  domain/        # prediction entities/engines
  widgets/       # reusable UI components
app/src/main/    # legacy Kotlin/Compose Android implementation
landing-page/    # Static landing page (HTML/CSS/JS)
```

## Build

**Prerequisites:** Android Studio Hedgehog+, JDK 17

```bash
# Clone
git clone https://github.com/lekhanpro/cyclecare.git
cd cyclecare

# Build Flutter debug APK
cd cyclecare_flutter
flutter pub get
flutter build apk --debug

# Build Flutter release APK
flutter build apk --release

# Run tests
flutter test
```

The debug APK will be at `cyclecare_flutter/build/app/outputs/flutter-apk/app-debug.apk`.

## CI/CD

- **APK Build:** Every push to `main` triggers a GitHub Actions workflow that builds the APK and uploads it as an artifact. Tagged pushes also create a GitHub Release with the APK attached.
- **Landing Page:** The `landing-page/` directory is deployed to GitHub Pages automatically on every push.

## Download

1. Go to [Actions](https://github.com/lekhanpro/cyclecare/actions) and download the latest `app-debug.apk` artifact
2. Or check [Releases](https://github.com/lekhanpro/cyclecare/releases) for tagged builds
3. Enable "Install from unknown sources" on your Android device
4. Install the APK

## Privacy

- All core cycle data is stored locally on device
- Internet is used only for opt-in AI, Google sign-in, cloud sync, and partner sharing
- No analytics, telemetry, or data collection
- PIN + biometric gating for app access
- Full data export and deletion from Settings

## License

MIT License — see [LICENSE](LICENSE) file.

## Contributing

Contributions welcome. Please open an issue first to discuss changes.

---

Built as a Flutter app for private, local-first cycle care.
