<div align="center">

<img src="assets/images/app_icon.svg" width="120" height="120" alt="CycleCare Logo"/>

# CycleCare

**The privacy-first menstrual health, fertility & wellness companion**

[![CI](https://github.com/lekhanpro/cyclecare/actions/workflows/ci.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/ci.yml)
[![Release](https://github.com/lekhanpro/cyclecare/actions/workflows/build-release.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/build-release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5.4-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-pink)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://play.google.com)

[**Download APK**](https://github.com/lekhanpro/cyclecare/releases/latest) • [**Documentation**](#documentation) • [**Contributing**](#contributing)

</div>

---

## What is CycleCare?

CycleCare is a production-grade Flutter application for menstrual health tracking, fertility awareness, pregnancy support, and holistic wellness. Built with a privacy-first, offline-first architecture — your data lives on your device and is never sold or shared.

Inspired by the best ideas from Flo, Clue, MyCalendar, and Glow — but open source, ad-free, and fully under your control.

---

## Screenshots

> Coming soon — run the app locally to see the full UI.

---

## Features

### Core Tracking
| Feature | Description |
|---------|-------------|
| 🌸 **Cycle Prediction** | Weighted moving average engine with confidence scoring |
| 📅 **Calendar View** | Period days, fertile window, ovulation, PMS phase visualization |
| 📝 **Daily Log** | Flow, mood, symptoms, BBT, sleep, water, weight, cervical data |
| 📊 **Insights** | Charts for cycle length, symptoms, mood, pain, BBT trends |

### Wellness & Companion
| Feature | Description |
|---------|-------------|
| 🤖 **AI Chat** | Groq Llama model via Supabase Edge Function — never exposes API keys |
| 🐰 **Virtual Pet** | XP system, levels, achievements, happiness tracking |
| 💊 **Birth Control** | Daily pill check-in with streak tracking |
| �� **Pregnancy Mode** | Week-by-week tracker, kick counter, due date calculator |

### Health & Education
| Feature | Description |
|---------|-------------|
| 💜 **Health Conditions** | PCOS, endometriosis, PMDD, perimenopause, amenorrhea info |
| 📚 **Education Library** | Evidence-based articles with bookmarks |
| 💑 **Partner Sharing** | Read-only partner dashboard with invite codes |
| 🔔 **Smart Reminders** | Period, pill, ovulation, daily log notifications |

### Privacy & Security
| Feature | Description |
|---------|-------------|
| 🔒 **App Lock** | PIN + biometric authentication |
| 🛡️ **Privacy Mode** | Hides content when app is in background |
| 📱 **Offline-First** | All data stored locally, cloud sync is optional |
| 🗑️ **Data Control** | Full export and delete at any time |

---

## Architecture

```
lib/
├── main.dart                    # Firebase + FCM + app bootstrap
├── core/
│   ├── providers/               # Auth, app settings (Riverpod)
│   ├── router/                  # GoRouter with StatefulShellRoute
│   ├── services/                # Firebase, notifications, security
│   └── theme/                   # Material 3, 8 palettes, Nunito
├── features/
│   ├── tracking/                # Home, Calendar, Log, Insights
│   │   ├── domain/              # CyclePredictionService, models
│   │   ├── data/                # CycleRepository (SharedPreferences)
│   │   ├── application/         # CycleTrackerController (Riverpod)
│   │   └── presentation/        # Screens
│   ├── ai/                      # AI chat with Groq proxy
│   ├── pet/                     # Virtual pet XP system
│   ├── birth_control/           # BC tracker
│   ├── pregnancy/               # Pregnancy mode
│   ├── partner/                 # Partner sharing
│   ├── health/                  # Health conditions
│   ├── education/               # Article library
│   └── settings/                # Full settings screen
├── widgets/                     # SoftCard, CycleCalendar, etc.
supabase/
├── migrations/                  # Full schema, 15 tables, RLS
└── functions/                   # ai-assistant, send-push, partner-sync
```

**Tech stack:**
- **Flutter 3.24.5** + **Dart 3.5.4**
- **Riverpod 2.x** — state management
- **GoRouter 14.x** — navigation
- **Firebase Auth** — authentication
- **Firebase Messaging** — push notifications
- **Supabase** — backend, database, Edge Functions
- **SharedPreferences** — offline-first local storage
- **fl_chart** — data visualization
- **Material 3** — design system

---

## Getting Started

### Prerequisites

- Flutter 3.24.5+ ([install](https://flutter.dev/docs/get-started/install))
- Android Studio with Android SDK 35
- Java 17+

### Run locally

```bash
# Clone
git clone https://github.com/lekhanpro/cyclecare.git
cd cyclecare

# Copy env (app works without real values)
cp .env.example .env

# Install dependencies
flutter pub get

# Run
flutter run
```

The app works **fully offline** without any backend credentials.

### Environment variables

Create `.env` in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

---

## Backend Setup

### Supabase

```bash
# Install Supabase CLI
npm install -g supabase

# Login and link
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Push database schema (15 tables, full RLS)
supabase db push

# Deploy Edge Functions
supabase functions deploy ai-assistant
supabase functions deploy send-push
supabase functions deploy partner-sync

# Set secrets
supabase secrets set GROQ_API_KEY=gsk_your_groq_key
```

See [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) for full instructions.

### Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (generates lib/firebase_options.dart)
flutterfire configure --project=your-firebase-project
```

See [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) for full instructions.

### Groq AI

1. Get a free API key at [console.groq.com](https://console.groq.com)
2. `supabase secrets set GROQ_API_KEY=gsk_your_key`

The Groq key is **never** in the Flutter client — only in the Supabase Edge Function.

See [docs/GROQ_SETUP.md](docs/GROQ_SETUP.md) for full instructions.

---

## Build

```bash
# Debug APK
flutter build apk --debug

# Release APK (requires signing config)
flutter build apk --release

# Release AAB (Play Store)
flutter build appbundle --release
```

### Release signing

```bash
# Generate keystore (one time)
keytool -genkey -v -keystore android/app/cyclecare-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias cyclecare

# Create android/key.properties
storePassword=your-password
keyPassword=your-key-password
keyAlias=cyclecare
storeFile=cyclecare-release.jks
```

---

## CI/CD

| Workflow | Trigger | Output |
|----------|---------|--------|
| `ci.yml` | Push to main | Analyze + test + debug APK |
| `build-release.yml` | Push tag `v*.*.*` | Signed APK + AAB + GitHub Release |

### GitHub Secrets required for release

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded release keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon key |

---

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

Current: **12/12 tests passing**

---

## Database Schema

15 tables with Row Level Security:

`profiles` · `periods` · `daily_logs` · `settings` · `birth_control` · `pill_checkins` · `pregnancy_data` · `pregnancy_appointments` · `health_conditions` · `pain_entries` · `partner_invites` · `education_bookmarks` · `pet_states` · `achievements` · `reminders`

All tables restrict access to `auth.uid()` — users can only access their own data.

---

## Medical Disclaimer

CycleCare is for **educational and personal tracking purposes only**. It is not a medical device and does not provide medical advice, diagnosis, or treatment. Cycle predictions are estimates based on logged data. **Do not rely on CycleCare as a method of contraception.** Always consult a qualified healthcare professional for medical concerns.

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'feat: add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## License

MIT License — see [LICENSE](LICENSE)

---

<div align="center">

Made with 💗 by [lekhanpro](https://github.com/lekhanpro)

**[⬆ Back to top](#cyclecare)**

</div>
