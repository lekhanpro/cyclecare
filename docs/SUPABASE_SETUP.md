# Supabase Setup Guide

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) → New project
2. Note your **Project URL** and **anon key** from Settings → API

## 2. Configure .env

```bash
cp .env.example .env
```

Edit `.env`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 3. Push database migrations

```bash
# Install Supabase CLI (already at D:\tools\supabase-cli\supabase.exe)
supabase login
supabase link --project-ref your-project-ref
supabase db push
```

## 4. Deploy Edge Functions

```bash
supabase functions deploy ai-assistant
supabase functions deploy send-push
supabase functions deploy partner-sync
```

## 5. Set secrets

```bash
# Groq API key (get from console.groq.com)
supabase secrets set GROQ_API_KEY=gsk_your_groq_key

# FCM server key (from Firebase Console → Project Settings → Cloud Messaging)
supabase secrets set FCM_SERVER_KEY=your_fcm_key
```

## 6. Enable Auth providers

In Supabase Dashboard → Authentication → Providers:
- Enable **Email** (enabled by default)
- Enable **Google** (add OAuth credentials from Google Cloud Console)

## 7. Wire up in Flutter

Once `.env` is configured, the app will automatically use Supabase for sync.
The offline-first architecture means the app works without Supabase — sync happens in the background.

## Tables created by migration

| Table | Description |
|-------|-------------|
| `profiles` | User profile and preferences |
| `periods` | Period records |
| `daily_logs` | Daily health logs |
| `settings` | App settings + FCM token |
| `birth_control` | BC method and streak |
| `pill_checkins` | Daily pill check-ins |
| `pregnancy_data` | Pregnancy mode data |
| `pregnancy_appointments` | Appointments |
| `health_conditions` | Tracked conditions |
| `pain_entries` | Pain diary |
| `partner_invites` | Partner sharing |
| `education_bookmarks` | Saved articles |
| `pet_states` | Virtual pet data |
| `achievements` | Unlocked achievements |
| `reminders` | Notification reminders |

All tables have **Row Level Security** enabled — users can only access their own data.
