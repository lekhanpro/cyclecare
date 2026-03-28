# CycleCare Flutter

A beautiful, privacy-first menstrual cycle tracking app built with Flutter.

## ⚠️ Project Status

This is a **work-in-progress** Flutter migration. The project structure has been created but requires Flutter SDK to be properly initialized.

### To Initialize This Project

```bash
# Install Flutter SDK first
# https://docs.flutter.dev/get-started/install

# Then run:
cd cyclecare_flutter
flutter create . --org com.cyclecare
flutter pub get
```

This will generate the necessary platform-specific files (Android, iOS, Web).

## Features

- **Cycle Tracking**: Interactive calendar with period, fertile, and ovulation predictions
- **Daily Logging**: Track 40+ symptoms, mood, flow, and health metrics
- **Amenorrhea Detection**: AI-powered detection of missed periods with severity levels
- **Health Insights**: Cycle trends, symptom analysis, and pattern recognition
- **Privacy First**: 100% local storage, no cloud sync, PIN + biometric lock
- **Multilingual**: Support for English, Hindi, Tamil, Telugu, Kannada
- **Education Cards**: Contextual health education content
- **Birth Control Tracking**: Pill reminders with streak tracking

## Architecture

- **State Management**: Riverpod
- **Database**: Drift (SQLite)
- **Local Storage**: Shared Preferences
- **Notifications**: flutter_local_notifications
- **Biometric Auth**: local_auth
- **Charts**: fl_chart

## Project Structure

```
lib/
├── core/              # Core utilities, constants, themes
├── data/              # Data layer (database, repositories)
│   ├── models/        # Data models
│   ├── database/      # Drift database
│   └── repositories/  # Repository implementations
├── domain/            # Business logic
│   ├── entities/      # Domain entities
│   ├── repositories/  # Repository interfaces
│   └── usecases/      # Use cases
├── presentation/      # UI layer
│   ├── screens/       # App screens
│   ├── widgets/       # Reusable widgets
│   └── providers/     # Riverpod providers
└── main.dart          # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.16.0 or higher
- Dart 3.2.0 or higher

### Installation

```bash
cd cyclecare_flutter
flutter pub get

# Format code (recommended before committing)
dart format .

# Run the app
flutter run
```

### Build

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Privacy

- All data stored locally using Drift (SQLite)
- No internet permission required
- No analytics or telemetry
- PIN + biometric authentication
- Full data export capability

## License

MIT License

## Authors

- Lekhan HR
- Mithun Gowda B <mithungowda.b7411@gmail.com>
