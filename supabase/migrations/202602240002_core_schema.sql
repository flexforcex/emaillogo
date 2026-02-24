-- Flex Force X - migration 002
-- Core trial schema

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  dob date null,
  trial_cohort text not null default 'cohort_a',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_trial_cohort_not_blank check (length(trim(trial_cohort)) > 0)
);

create table if not exists public.terra_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  terra_user_id text not null,
  provider text not null default 'apple_health',
  status public.connection_status not null default 'pending',
  connected_at timestamptz null,
  last_sync_at timestamptz null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint terra_connections_user_provider_unique unique (user_id, provider),
  constraint terra_connections_terra_user_unique unique (terra_user_id),
  constraint terra_connections_provider_not_blank check (length(trim(provider)) > 0)
);

create table if not exists public.biometrics_raw (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null default 'terra',
  metric_type text not null,
  ts timestamptz not null,
  value numeric not null,
  unit text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint biometrics_raw_dedupe unique (user_id, source, metric_type, ts, value, unit),
  constraint biometrics_raw_source_not_blank check (length(trim(source)) > 0),
  constraint biometrics_raw_metric_type_not_blank check (length(trim(metric_type)) > 0),
  constraint biometrics_raw_unit_not_blank check (length(trim(unit)) > 0)
);

create table if not exists public.biometrics_daily (
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  steps integer not null default 0,
  sleep_minutes integer not null default 0,
  hrv numeric(10, 2) null,
  rhr numeric(10, 2) null,
  calories integer not null default 0,
  active_minutes integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, date),
  constraint biometrics_daily_steps_non_negative check (steps >= 0),
  constraint biometrics_daily_sleep_non_negative check (sleep_minutes >= 0),
  constraint biometrics_daily_hrv_non_negative check (hrv is null or hrv >= 0),
  constraint biometrics_daily_rhr_non_negative check (rhr is null or rhr >= 0),
  constraint biometrics_daily_calories_non_negative check (calories >= 0),
  constraint biometrics_daily_active_minutes_non_negative check (active_minutes >= 0)
);

create table if not exists public.events_audit (
  id uuid primary key default gen_random_uuid(),
  user_id uuid null references auth.users(id) on delete set null,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint events_audit_event_type_not_blank check (length(trim(event_type)) > 0)
);

create table if not exists public.ai_plans_daily (
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  plan jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (user_id, date)
);

-- Dedicated idempotency table for Terra webhook events.
create table if not exists public.terra_webhook_receipts (
  event_id text primary key,
  terra_user_id text null,
  user_id uuid null references auth.users(id) on delete set null,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  received_at timestamptz not null default now(),
  processed_at timestamptz null,
  error_message text null,
  constraint terra_webhook_receipts_event_type_not_blank check (length(trim(event_type)) > 0)
);
