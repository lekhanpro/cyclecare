# CycleCare 🌸

A production-grade Flutter menstrual health, fertility, pregnancy, wellness, AI companion, and virtual pet app. Privacy-first, offline-first, and medically non-diagnostic.

[![CI](https://github.com/lekhanpro/cyclecare/actions/workflows/ci.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/ci.yml)

---

## Features

| Feature | Status |
|---------|--------|
| Cycle tracking & prediction | ✅ Complete |
| Calendar with phase visualization | ✅ Complete |
| Daily log (flow, mood, symptoms, BBT, sleep, water, weight) | ✅ Complete |
| Insights & charts | ✅ Complete |
| AI chat companion | ✅ Complete (requires Supabase Edge Function) |
| Virtual pet with XP & achievements | ✅ Complete |
| Birth control tracker | ✅ Complete |
| Pregnancy mode + kick counter | ✅ Complete |
| Health conditions education | ✅ Complete |
| Partner sharing | ✅ Complete (invite code UI) |
| Education library | ✅ Complete |
| Settings (palette, dark mode, privacy) | ✅ Complete |
| 8 color palettes | ✅ Complete |
| Offline-first (SharedPreferences) | ✅ Complete |
| Supabase sync | 🔧 Schema ready, runtime wiring pending credentials |
| Firebase Auth | 🔧 Stub ready, activate with `flutterfire configure` |
| Push notifications (FCM) | 🔧 Edge Function ready |
| Local notifications | ✅ Complete |
| App lock (PIN/biometric) | ✅ Complete |
| Data export | ✅ Complete |
| GitHub Actions CI/CD | ✅ Complete |

---

## Architecture

```
lib/
├── main.dart
├── core/
│   ├── providers/          # Auth, app settings
│   ├── router/             # GoRouter with StatefulShellRoute
│   ├── services/           # Notification, auth, security stubs
│   ├── theme/              # Material 3, 8 palettes, Nunito typography
│   └── utils/              # Date helpers
├── data/
│   └── database/           # SharedPreferences-backed local DB
├── domain/
│   ├── engines/            # CyclePredictionEngine
│   └── entities/           # Period, DailyLog, AmenorrheaResult
├── features/
│   ├── app/                # CycleCareApp, MainShell
│   ├── ai/                 # AI chat screen
│   ├── auth/               # Landing, sign-in
│   ├── birth_control/      # BC tracker
│   ├── education/          # Article library
│   ├── health/             # Health conditions
│   ├── onboarding/         # 5-step onboarding
│   ├── partner/            # Partner sharing
│   ├── pet/                # Virtual pet + XP
│   ├── pregnancy/          # Pregnancy mode
│   ├── reminders/          # Reminders screen
│   ├── settings/           # Full settings
│   ├── splash/             # Splash screen
│   └── tracking/           # Home, Calendar, Log, Insights
└── widgets/                # SoftCard, PrimaryButton, CycleCalendar, etc.

supabase/
├── migrations/             # Full schema with RLS
└── functions/
    ├── ai-assistant/       # Groq proxy (server-side only)
    ├── send-push/          # FCM push sender
    └── partner-sync/       # Partner invite validation

.github/workflows/
├── ci.yml                  # Analyze + test + debug APK
└── build-release.yml       # Signed APK + AAB on version tag
```

---

## Quick Start

### Prerequisites
- Flutter 3.24.5+ (`flutter --version`)
- Android Studio with Android SDK 35
- Java 17+

### Run locally

```bash
# 1. Clone
git clone https://github.com/lekhanpro/cyclecare.git
cd cyclecare

# 2. Copy env
cp .env.example .env
# Edit .env with your Supabase credentials (optional for local-only use)

# 3. Install dependencies
flutter pub get

# 4. Run
flutter run
```

The app works fully offline without any backend credentials.

---

## Required Secrets (for cloud features)

### .env (local development)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### GitHub Secrets (for CI/CD)
| Secret | Description |
|--------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon key |
| `KEYSTORE_BASE64` | Base64-encoded release keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |

---

## Supabase Setup

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Push migrations
supabase db push

# Deploy Edge Functions
supabase functions deploy ai-assistant
supabase functions deploy send-push
supabase functions deploy partner-sync

# Set Edge Function secrets
supabase secrets set GROQ_API_KEY=your-groq-key
supabase secrets set FCM_SERVER_KEY=your-fcm-key
```

---

## Firebase Setup (optional — for FCM push notifications)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure
flutterfire configure --project=your-firebase-project

# This generates lib/firebase_options.dart
# Then uncomment Firebase dependencies in pubspec.yaml
# and the Firebase plugin in android/app/build.gradle
```

---

## Build APK/AAB

```bash
# Debug APK
flutter build apk --debug

# Release APK (requires signing config)
flutter build apk --release

# Release AAB (for Play Store)
flutter build appbundle --release
```

APK output: `build/app/outputs/flutter-apk/`

---

## Run Tests

```bash
flutter test
```

---

## Release Build (Play Store)

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore cyclecare-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cyclecare
   ```

2. Create `android/key.properties`:
   ```
   storePassword=your-password
   keyPassword=your-key-password
   keyAlias=cyclecare
   storeFile=cyclecare-release.jks
   ```

3. Build:
   ```bash
   flutter build appbundle --release
   ```

4. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

---

## Medical Disclaimer

CycleCare is for educational and personal tracking purposes only. It is not a medical device and does not provide medical advice, diagnosis, or treatment. Cycle predictions are estimates. Do not rely on CycleCare as a method of contraception. Always consult a qualified healthcare professional for medical concerns.

---

## License

MIT License — see [LICENSE](LICENSE)
