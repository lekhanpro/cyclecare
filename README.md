<div align="center">

<img src="assets/images/app_icon.svg" width="120" height="120" alt="CycleCare Logo" />

# CycleCare

**Privacy-first menstrual health, fertility & wellness companion**

[![CI](https://github.com/lekhanpro/cyclecare/actions/workflows/ci.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/ci.yml)
[![Release](https://github.com/lekhanpro/cyclecare/actions/workflows/build-release.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/build-release.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.5-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5.4-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-pink)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://github.com/lekhanpro/cyclecare/releases)

[**Download APK**](https://github.com/lekhanpro/cyclecare/releases/latest) · [**Report Bug**](https://github.com/lekhanpro/cyclecare/issues) · [**Request Feature**](https://github.com/lekhanpro/cyclecare/issues)

</div>

---

## Overview

CycleCare is a production-grade Flutter app combining the best ideas from Flo, Clue, MyCalendar, and Glow — built privacy-first, offline-first, and medically non-diagnostic. Your data lives on your device. Cloud sync is optional.

<div align="center">

| 🌸 Cycle Tracking | 📊 Insights | 🤖 AI Chat | 🐰 Virtual Pet |
|:-:|:-:|:-:|:-:|
| Prediction engine | fl_chart charts | Groq Llama AI | XP & achievements |

</div>

---

## Features

### Core
| Feature | Description |
|---------|-------------|
| 🌸 **Cycle Prediction** | Weighted moving average engine — adapts to your personal pattern over time |
| 📅 **Calendar** | Month view with period, fertile window, ovulation & PMS phase markers |
| 📝 **Daily Log** | Flow, mood, 16 symptoms, pain, BBT, cervical mucus, sleep, water, weight |
| 📊 **Insights** | Cycle length trends, symptom frequency, mood patterns, pain charts |
| 🤖 **AI Chat** | Phase-aware health education via Groq Llama (server-side, key never in app) |
| 🐰 **Virtual Pet** | Grows with your tracking streak — XP, levels, 9 achievements |

### Health Modules
| Module | Description |
|--------|-------------|
| 💊 **Birth Control** | Daily pill check-in with streak, supports 8 methods |
| 🤰 **Pregnancy** | Week-by-week tracker, kick counter, due date calculator |
| 💜 **Health Conditions** | PCOS, endometriosis, PMDD, perimenopause, amenorrhea education |
| 💑 **Partner Sharing** | Invite code system, read-only partner dashboard |
| 📚 **Education** | 5 evidence-based articles with bookmarks |

### Technical
| Feature | Implementation |
|---------|---------------|
| 🔒 **Privacy** | Offline-first, no account required, PIN + biometric lock |
| ☁️ **Cloud Sync** | Supabase with full Row Level Security on all 15 tables |
| 🔔 **Notifications** | Local reminders + FCM push notifications |
| 🎨 **Themes** | 8 pastel palettes, Material 3, light/dark mode |
| 🔐 **Auth** | Firebase Auth — email/password + Google Sign-In |

---

## Architecture

```
lib/
├── main.dart                    # Firebase + FCM init, app entry
├── core/
│   ├── providers/               # Auth, app settings (Riverpod)
│   ├── router/                  # GoRouter with StatefulShellRoute
│   ├── services/                # Auth, notifications, security
│   └── theme/                   # Material 3, 8 palettes, Nunito
├── features/
│   ├── tracking/                # Home, Calendar, Log, Insights
│   │   ├── domain/              # CyclePredictionService, models
│   │   ├── data/                # CycleRepository (SharedPreferences)
│   │   └── presentation/        # Screens + controllers
│   ├── ai/                      # AI chat with typing indicator
│   ├── pet/                     # XP system, achievements, animations
│   ├── birth_control/           # Daily check-in, streak
│   ├── pregnancy/               # Kick counter, week tracker
│   ├── health/                  # Condition education cards
│   ├── partner/                 # Invite code, sharing toggles
│   ├── education/               # Article library, bookmarks
│   ├── settings/                # Full settings + PIN lock
│   ├── auth/                    # Landing, sign-in, onboarding
│   └── app/                     # Shell, app lock, router
├── widgets/                     # SoftCard, CycleCalendar, etc.
└── domain/                      # Prediction engine, entities

supabase/
├── migrations/001_initial_schema.sql   # 15 tables, full RLS
└── functions/
    ├── ai-assistant/            # Groq proxy (key never in client)
    ├── send-push/               # FCM v1 sender
    └── partner-sync/            # Invite validation

.github/workflows/
├── ci.yml                       # Analyze + test on every push
└── build-release.yml            # Signed APK + AAB on version tag
```

**Design principles:**
- Presentation layer has zero knowledge of Supabase, Firebase, or network
- Domain layer is pure Dart — no Flutter imports
- All writes go local first → UI updates immediately → background sync
- Riverpod providers compose all dependencies

---

## Getting Started

### Prerequisites
- Flutter 3.24.5+ — [install guide](https://docs.flutter.dev/get-started/install)
- Android Studio with Android SDK 35
- Java 17+

### Run locally

```bash
# Clone
git clone https://github.com/lekhanpro/cyclecare.git
cd cyclecare

# Copy env (optional — app works fully offline without it)
cp .env.example .env

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

The app works **100% offline** without any backend credentials. Supabase and Firebase only add cloud sync and AI.

### Run tests

```bash
flutter test
```

### Build APK

```bash
flutter build apk --release
```

---

## Backend Setup

### Supabase (cloud sync + AI)

```bash
# Install Supabase CLI
# macOS: brew install supabase/tap/supabase
# Windows: download from github.com/supabase/cli/releases

supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push                              # Push all 15 tables
supabase functions deploy ai-assistant        # AI proxy
supabase functions deploy send-push           # FCM sender
supabase functions deploy partner-sync        # Partner invites
supabase secrets set GROQ_API_KEY=gsk_...     # Groq API key
```

Add to `.env`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

### Firebase (auth + push notifications)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT
```

Then uncomment Firebase packages in `pubspec.yaml`.

See [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) for full instructions.

### Groq AI

1. Get a free API key at [console.groq.com](https://console.groq.com)
2. `supabase secrets set GROQ_API_KEY=gsk_your_key`

The key is **never** in the Flutter client — only in the Supabase Edge Function.

---

## Database Schema

15 tables, all with Row Level Security:

| Table | Description |
|-------|-------------|
| `profiles` | User profile, preferences, tracking goal |
| `periods` | Period records with flow and symptoms |
| `daily_logs` | Daily health entries |
| `settings` | App settings + FCM token |
| `birth_control` | Method + streak |
| `pill_checkins` | Daily pill check-in history |
| `pregnancy_data` | Pregnancy mode + kick count |
| `pregnancy_appointments` | Appointment tracker |
| `health_conditions` | Tracked conditions |
| `pain_entries` | Pain diary |
| `partner_invites` | Invite codes + sharing config |
| `education_bookmarks` | Saved articles |
| `pet_states` | Virtual pet XP, level, happiness |
| `achievements` | Unlocked achievements |
| `reminders` | Notification schedule |

---

## CI/CD

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `ci.yml` | Push to `main` | Format check → analyze → test → debug APK |
| `build-release.yml` | Push tag `v*.*.*` | Signed APK + AAB → GitHub Release |

### Release a new version

```bash
git tag -a v2.1.0 -m "Release v2.1.0"
git push origin v2.1.0
```

The signed APK and AAB are automatically attached to the GitHub Release.

---

## Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded release keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon key |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.24.5 / Dart 3.5.4 |
| State management | Riverpod 2.x |
| Navigation | GoRouter 14.x |
| Local storage | SharedPreferences (offline-first) |
| Backend | Supabase (PostgreSQL + Edge Functions) |
| Auth | Firebase Auth |
| Push notifications | Firebase Cloud Messaging |
| AI | Groq Llama 3 (server-side proxy) |
| Charts | fl_chart |
| Fonts | Google Fonts (Nunito) |
| Icons | Material Icons + Cupertino Icons |
| CI/CD | GitHub Actions |

---

## Medical Disclaimer

CycleCare is for **educational and personal tracking purposes only**. It is not a medical device and does not provide medical advice, diagnosis, or treatment. Cycle predictions are estimates based on logged data. **Do not rely on CycleCare as a method of contraception.** Always consult a qualified healthcare professional for medical concerns.

---

## License

MIT License — see [LICENSE](LICENSE)

---

<div align="center">

Made with 🌸 by [lekhanpro](https://github.com/lekhanpro)

</div>
