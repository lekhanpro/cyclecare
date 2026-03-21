# CycleCare

A beautiful, privacy-first menstrual cycle tracking app for Android built with Kotlin and Jetpack Compose.

[![Build APK](https://github.com/lekhanpro/cyclecare/actions/workflows/build-apk.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/build-apk.yml)
[![Deploy Pages](https://github.com/lekhanpro/cyclecare/actions/workflows/pages.yml/badge.svg)](https://lekhanpro.github.io/cyclecare/)
![Android](https://img.shields.io/badge/Android-7.0%2B-green)
![Kotlin](https://img.shields.io/badge/Kotlin-1.9-blue)
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

| Layer | Technology |
|-------|-----------|
| Language | Kotlin |
| UI | Jetpack Compose + Material Design 3 |
| Architecture | MVVM + Clean Architecture |
| Database | Room (7 tables) |
| DI | Hilt / Dagger |
| Async | Coroutines + Flow / StateFlow |
| Notifications | WorkManager |
| Auth | Biometric API |
| Build | Gradle KTS + KSP |

## Project Structure

```
app/src/main/java/com/cyclecare/app/
  data/          # Room entities, DAOs, repositories, workers
  domain/        # Models, repository interfaces, prediction engine
  presentation/  # Compose screens, ViewModels, theme, navigation
  di/            # Hilt dependency injection modules
landing-page/    # Static landing page (HTML/CSS/JS)
```

## Build

**Prerequisites:** Android Studio Hedgehog+, JDK 17

```bash
# Clone
git clone https://github.com/lekhanpro/cyclecare.git
cd cyclecare

# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease

# Run tests
./gradlew test
```

The debug APK will be at `app/build/outputs/apk/debug/app-debug.apk`.

## CI/CD

- **APK Build:** Every push to `main` triggers a GitHub Actions workflow that builds the APK and uploads it as an artifact. Tagged pushes also create a GitHub Release with the APK attached.
- **Landing Page:** The `landing-page/` directory is deployed to GitHub Pages automatically on every push.

## Download

1. Go to [Actions](https://github.com/lekhanpro/cyclecare/actions) and download the latest `app-debug.apk` artifact
2. Or check [Releases](https://github.com/lekhanpro/cyclecare/releases) for tagged builds
3. Enable "Install from unknown sources" on your Android device
4. Install the APK

## Privacy

- All data stored locally in Room database on device
- No internet permission required for core functionality
- No analytics, telemetry, or data collection
- PIN + biometric gating for app access
- Full data export and deletion from Settings

## License

MIT License — see [LICENSE](LICENSE) file.

## Contributing

Contributions welcome. Please open an issue first to discuss changes.

---

Built with Kotlin + Jetpack Compose for private health tracking.
