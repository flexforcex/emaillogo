-- Flex Force X - migration 003
-- Performance indexes, helper functions, and triggers

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', '')
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists trg_profiles_set_updated_at on public.profiles;
create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists trg_terra_connections_set_updated_at on public.terra_connections;
create trigger trg_terra_connections_set_updated_at
before update on public.terra_connections
for each row
execute function public.set_updated_at();

drop trigger if exists trg_biometrics_daily_set_updated_at on public.biometrics_daily;
create trigger trg_biometrics_daily_set_updated_at
before update on public.biometrics_daily
for each row
execute function public.set_updated_at();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

create or replace function public.current_user_is_admin()
returns boolean
language sql
stable
as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
    or (auth.jwt() -> 'app_metadata' -> 'roles') ? 'admin',
    false
  );
$$;

grant execute on function public.current_user_is_admin() to authenticated;

create index if not exists idx_profiles_trial_cohort
  on public.profiles (trial_cohort);

create index if not exists idx_terra_connections_user_status
  on public.terra_connections (user_id, status);

create index if not exists idx_terra_connections_last_sync
  on public.terra_connections (last_sync_at desc);

create index if not exists idx_biometrics_raw_user_ts
  on public.biometrics_raw (user_id, ts desc);

create index if not exists idx_biometrics_raw_metric_type_ts
  on public.biometrics_raw (metric_type, ts desc);

create index if not exists idx_biometrics_daily_date
  on public.biometrics_daily (date desc);

create index if not exists idx_events_audit_user_created
  on public.events_audit (user_id, created_at desc);

create index if not exists idx_events_audit_event_type_created
  on public.events_audit (event_type, created_at desc);

create index if not exists idx_ai_plans_daily_date
  on public.ai_plans_daily (date desc);

create index if not exists idx_terra_webhook_receipts_user_received
  on public.terra_webhook_receipts (user_id, received_at desc);

create index if not exists idx_terra_webhook_receipts_terra_user_received
  on public.terra_webhook_receipts (terra_user_id, received_at desc);
