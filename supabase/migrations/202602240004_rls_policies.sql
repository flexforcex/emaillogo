-- Flex Force X - migration 004
-- Row Level Security policies

alter table public.profiles enable row level security;
alter table public.terra_connections enable row level security;
alter table public.biometrics_raw enable row level security;
alter table public.biometrics_daily enable row level security;
alter table public.events_audit enable row level security;
alter table public.ai_plans_daily enable row level security;
alter table public.terra_webhook_receipts enable row level security;

alter table public.profiles force row level security;
alter table public.terra_connections force row level security;
alter table public.biometrics_raw force row level security;
alter table public.biometrics_daily force row level security;
alter table public.events_audit force row level security;
alter table public.ai_plans_daily force row level security;
alter table public.terra_webhook_receipts force row level security;

-- profiles
drop policy if exists p_profiles_select_own on public.profiles;
create policy p_profiles_select_own
on public.profiles
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists p_profiles_insert_own on public.profiles;
create policy p_profiles_insert_own
on public.profiles
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists p_profiles_update_own on public.profiles;
create policy p_profiles_update_own
on public.profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists p_profiles_delete_own on public.profiles;
create policy p_profiles_delete_own
on public.profiles
for delete
to authenticated
using (auth.uid() = user_id);

-- terra_connections (connection status ownership)
drop policy if exists p_terra_connections_select_own on public.terra_connections;
create policy p_terra_connections_select_own
on public.terra_connections
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists p_terra_connections_insert_own on public.terra_connections;
create policy p_terra_connections_insert_own
on public.terra_connections
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists p_terra_connections_update_own on public.terra_connections;
create policy p_terra_connections_update_own
on public.terra_connections
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists p_terra_connections_delete_own on public.terra_connections;
create policy p_terra_connections_delete_own
on public.terra_connections
for delete
to authenticated
using (auth.uid() = user_id);

-- biometrics_raw (read-only for users; writes are expected from backend ingestion)
drop policy if exists p_biometrics_raw_select_own on public.biometrics_raw;
create policy p_biometrics_raw_select_own
on public.biometrics_raw
for select
to authenticated
using (auth.uid() = user_id);

-- biometrics_daily (normalized metrics for app dashboard)
drop policy if exists p_biometrics_daily_select_own on public.biometrics_daily;
create policy p_biometrics_daily_select_own
on public.biometrics_daily
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists p_biometrics_daily_insert_own on public.biometrics_daily;
create policy p_biometrics_daily_insert_own
on public.biometrics_daily
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists p_biometrics_daily_update_own on public.biometrics_daily;
create policy p_biometrics_daily_update_own
on public.biometrics_daily
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists p_biometrics_daily_delete_own on public.biometrics_daily;
create policy p_biometrics_daily_delete_own
on public.biometrics_daily
for delete
to authenticated
using (auth.uid() = user_id);

-- events_audit
drop policy if exists p_events_audit_select_own on public.events_audit;
create policy p_events_audit_select_own
on public.events_audit
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists p_events_audit_insert_own on public.events_audit;
create policy p_events_audit_insert_own
on public.events_audit
for insert
to authenticated
with check (auth.uid() = user_id);

-- ai_plans_daily
drop policy if exists p_ai_plans_daily_select_own on public.ai_plans_daily;
create policy p_ai_plans_daily_select_own
on public.ai_plans_daily
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists p_ai_plans_daily_insert_own on public.ai_plans_daily;
create policy p_ai_plans_daily_insert_own
on public.ai_plans_daily
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists p_ai_plans_daily_update_own on public.ai_plans_daily;
create policy p_ai_plans_daily_update_own
on public.ai_plans_daily
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists p_ai_plans_daily_delete_own on public.ai_plans_daily;
create policy p_ai_plans_daily_delete_own
on public.ai_plans_daily
for delete
to authenticated
using (auth.uid() = user_id);

-- No client-side access policy is created for terra_webhook_receipts.
-- Service role writes bypass RLS by design.
