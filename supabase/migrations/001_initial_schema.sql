-- CycleCare Supabase Schema
-- Run via: supabase db push
-- All tables have RLS enabled and restrict to auth.uid()

-- ─── Extensions ──────────────────────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ─── Profiles ────────────────────────────────────────────────────────────────
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  birth_year int,
  tracking_goal text default 'track_periods',
  average_cycle_length int default 28,
  average_period_length int default 5,
  onboarding_completed boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table profiles enable row level security;
create policy "Users can manage own profile"
  on profiles for all using (auth.uid() = id);

-- ─── Periods ─────────────────────────────────────────────────────────────────
create table if not exists periods (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  start_date date not null,
  end_date date,
  flow text default 'medium',
  symptoms text[] default '{}',
  notes text default '',
  synced boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table periods enable row level security;
create policy "Users can manage own periods"
  on periods for all using (auth.uid() = user_id);
create index periods_user_date on periods(user_id, start_date desc);

-- ─── Daily logs ───────────────────────────────────────────────────────────────
create table if not exists daily_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null,
  flow text,
  mood text,
  symptoms text[] default '{}',
  pain_level int default 0,
  discharge text,
  cervical_mucus text,
  temperature_celsius numeric(4,2),
  weight_kg numeric(5,2),
  sleep_hours numeric(4,1),
  water_ml int default 0,
  medicine_taken boolean default false,
  medicine_name text,
  notes text default '',
  synced boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, log_date)
);
alter table daily_logs enable row level security;
create policy "Users can manage own daily logs"
  on daily_logs for all using (auth.uid() = user_id);
create index daily_logs_user_date on daily_logs(user_id, log_date desc);

-- ─── Settings ─────────────────────────────────────────────────────────────────
create table if not exists settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  palette text default 'pinkRose',
  is_dark boolean default false,
  privacy_mode boolean default false,
  period_reminder_enabled boolean default true,
  ovulation_reminder_enabled boolean default false,
  daily_log_reminder_enabled boolean default false,
  pill_reminder_enabled boolean default false,
  reminder_hour int default 9,
  reminder_minute int default 0,
  fcm_token text,
  updated_at timestamptz default now()
);
alter table settings enable row level security;
create policy "Users can manage own settings"
  on settings for all using (auth.uid() = user_id);

-- ─── Birth control ────────────────────────────────────────────────────────────
create table if not exists birth_control (
  user_id uuid primary key references auth.users(id) on delete cascade,
  method text default 'none',
  streak int default 0,
  last_taken timestamptz,
  updated_at timestamptz default now()
);
alter table birth_control enable row level security;
create policy "Users can manage own birth control"
  on birth_control for all using (auth.uid() = user_id);

-- ─── Pill check-ins ───────────────────────────────────────────────────────────
create table if not exists pill_checkins (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  taken_at timestamptz not null,
  status text default 'taken', -- taken | missed | late | skipped
  created_at timestamptz default now()
);
alter table pill_checkins enable row level security;
create policy "Users can manage own pill checkins"
  on pill_checkins for all using (auth.uid() = user_id);

-- ─── Pregnancy data ───────────────────────────────────────────────────────────
create table if not exists pregnancy_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  is_active boolean default false,
  due_date date,
  kick_count int default 0,
  updated_at timestamptz default now()
);
alter table pregnancy_data enable row level security;
create policy "Users can manage own pregnancy data"
  on pregnancy_data for all using (auth.uid() = user_id);

-- ─── Pregnancy appointments ───────────────────────────────────────────────────
create table if not exists pregnancy_appointments (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  appointment_date timestamptz not null,
  notes text default '',
  created_at timestamptz default now()
);
alter table pregnancy_appointments enable row level security;
create policy "Users can manage own appointments"
  on pregnancy_appointments for all using (auth.uid() = user_id);

-- ─── Health conditions ────────────────────────────────────────────────────────
create table if not exists health_conditions (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  condition text not null, -- pcos | endometriosis | pmdd | perimenopause | amenorrhea
  diagnosed boolean default false,
  notes text default '',
  created_at timestamptz default now()
);
alter table health_conditions enable row level security;
create policy "Users can manage own health conditions"
  on health_conditions for all using (auth.uid() = user_id);

-- ─── Pain entries ─────────────────────────────────────────────────────────────
create table if not exists pain_entries (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  pain_level int not null check (pain_level between 0 and 10),
  location text,
  notes text default '',
  created_at timestamptz default now()
);
alter table pain_entries enable row level security;
create policy "Users can manage own pain entries"
  on pain_entries for all using (auth.uid() = user_id);

-- ─── Partner invites ──────────────────────────────────────────────────────────
create table if not exists partner_invites (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  partner_id uuid references auth.users(id) on delete set null,
  invite_code text unique not null,
  sharing_enabled boolean default true,
  share_cycle_phase boolean default true,
  share_period_prediction boolean default true,
  share_mood boolean default true,
  share_symptoms boolean default false,
  share_flow boolean default false,
  expires_at timestamptz default (now() + interval '24 hours'),
  accepted_at timestamptz,
  created_at timestamptz default now()
);
alter table partner_invites enable row level security;
create policy "Owners can manage their invites"
  on partner_invites for all using (auth.uid() = owner_id);
create policy "Partners can read their invite"
  on partner_invites for select using (auth.uid() = partner_id);

-- ─── Education bookmarks ──────────────────────────────────────────────────────
create table if not exists education_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  article_id text not null,
  created_at timestamptz default now(),
  primary key (user_id, article_id)
);
alter table education_bookmarks enable row level security;
create policy "Users can manage own bookmarks"
  on education_bookmarks for all using (auth.uid() = user_id);

-- ─── Pet states ───────────────────────────────────────────────────────────────
create table if not exists pet_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  pet_type text default 'bunny',
  pet_name text default 'Luna',
  xp int default 0,
  level int default 1,
  happiness int default 80,
  streak int default 0,
  achievements text[] default '{}',
  last_fed timestamptz,
  last_petted timestamptz,
  updated_at timestamptz default now()
);
alter table pet_states enable row level security;
create policy "Users can manage own pet"
  on pet_states for all using (auth.uid() = user_id);

-- ─── Achievements ─────────────────────────────────────────────────────────────
create table if not exists achievements (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null,
  unlocked_at timestamptz default now(),
  unique(user_id, achievement_id)
);
alter table achievements enable row level security;
create policy "Users can manage own achievements"
  on achievements for all using (auth.uid() = user_id);

-- ─── Reminders ────────────────────────────────────────────────────────────────
create table if not exists reminders (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  hour int not null,
  minute int not null,
  days_before int,
  enabled boolean default true,
  created_at timestamptz default now()
);
alter table reminders enable row level security;
create policy "Users can manage own reminders"
  on reminders for all using (auth.uid() = user_id);

-- ─── Updated_at trigger ───────────────────────────────────────────────────────
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_profiles_updated_at before update on profiles
  for each row execute function update_updated_at();
create trigger update_periods_updated_at before update on periods
  for each row execute function update_updated_at();
create trigger update_daily_logs_updated_at before update on daily_logs
  for each row execute function update_updated_at();
