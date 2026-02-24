-- Flex Force X local seed
-- Creates 3 deterministic trial users and synthetic biometrics.

with seed_users as (
  select *
  from (
    values
      ('11111111-1111-1111-1111-111111111111'::uuid, 'trial.user1@flexforcex.test', 'Trial User One', 'cohort_a'),
      ('22222222-2222-2222-2222-222222222222'::uuid, 'trial.user2@flexforcex.test', 'Trial User Two', 'cohort_a'),
      ('33333333-3333-3333-3333-333333333333'::uuid, 'trial.user3@flexforcex.test', 'Trial User Three', 'cohort_b')
  ) as t(user_id, email, full_name, trial_cohort)
)
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
select
  '00000000-0000-0000-0000-000000000000'::uuid as instance_id,
  su.user_id,
  'authenticated',
  'authenticated',
  su.email,
  crypt('FlexForceX!123', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('name', su.full_name),
  now(),
  now()
from seed_users su
on conflict (id) do update
set
  email = excluded.email,
  raw_user_meta_data = excluded.raw_user_meta_data,
  updated_at = now();

with seed_users as (
  select *
  from (
    values
      ('11111111-1111-1111-1111-111111111111'::uuid, 'trial.user1@flexforcex.test'),
      ('22222222-2222-2222-2222-222222222222'::uuid, 'trial.user2@flexforcex.test'),
      ('33333333-3333-3333-3333-333333333333'::uuid, 'trial.user3@flexforcex.test')
  ) as t(user_id, email)
)
insert into auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  created_at,
  updated_at
)
select
  gen_random_uuid(),
  su.user_id,
  jsonb_build_object('sub', su.user_id::text, 'email', su.email),
  'email',
  su.user_id::text,
  now(),
  now()
from seed_users su
on conflict (provider, provider_id) do update
set
  identity_data = excluded.identity_data,
  updated_at = now();

with seed_profiles as (
  select *
  from (
    values
      ('11111111-1111-1111-1111-111111111111'::uuid, 'Trial User One', 'cohort_a'),
      ('22222222-2222-2222-2222-222222222222'::uuid, 'Trial User Two', 'cohort_a'),
      ('33333333-3333-3333-3333-333333333333'::uuid, 'Trial User Three', 'cohort_b')
  ) as t(user_id, full_name, trial_cohort)
)
insert into public.profiles (user_id, name, trial_cohort)
select user_id, full_name, trial_cohort
from seed_profiles
on conflict (user_id) do update
set
  name = excluded.name,
  trial_cohort = excluded.trial_cohort,
  updated_at = now();

with seed_connections as (
  select *
  from (
    values
      ('11111111-1111-1111-1111-111111111111'::uuid, 'terra_trial_user_1', 'connected'::public.connection_status),
      ('22222222-2222-2222-2222-222222222222'::uuid, 'terra_trial_user_2', 'pending'::public.connection_status),
      ('33333333-3333-3333-3333-333333333333'::uuid, 'terra_trial_user_3', 'error'::public.connection_status)
  ) as t(user_id, terra_user_id, status)
)
insert into public.terra_connections (
  user_id,
  terra_user_id,
  provider,
  status,
  connected_at,
  last_sync_at,
  metadata
)
select
  user_id,
  terra_user_id,
  'apple_health',
  status,
  case when status = 'connected' then now() - interval '5 days' else null end,
  case when status = 'connected' then now() - interval '2 hours' else null end,
  jsonb_build_object('seeded', true)
from seed_connections
on conflict (user_id, provider) do update
set
  terra_user_id = excluded.terra_user_id,
  status = excluded.status,
  connected_at = excluded.connected_at,
  last_sync_at = excluded.last_sync_at,
  metadata = excluded.metadata,
  updated_at = now();

with days as (
  select (current_date - offs)::date as metric_date, offs
  from generate_series(0, 13) as offs
),
users as (
  select unnest(array[
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid
  ]) as user_id
)
insert into public.biometrics_daily (
  user_id,
  date,
  steps,
  sleep_minutes,
  hrv,
  rhr,
  calories,
  active_minutes
)
select
  u.user_id,
  d.metric_date,
  greatest(3500, 9000 - (d.offs * 125) + (abs(mod(hashtext(u.user_id::text), 7)) * 80)),
  greatest(320, 450 - (d.offs * 3)),
  round((35 + (d.offs * 0.4))::numeric, 2),
  round((58 + (d.offs * 0.2))::numeric, 2),
  greatest(1600, 2300 - (d.offs * 12)),
  greatest(25, 65 - d.offs)
from users u
cross join days d
on conflict (user_id, date) do update
set
  steps = excluded.steps,
  sleep_minutes = excluded.sleep_minutes,
  hrv = excluded.hrv,
  rhr = excluded.rhr,
  calories = excluded.calories,
  active_minutes = excluded.active_minutes,
  updated_at = now();

insert into public.events_audit (user_id, event_type, payload)
values
  (
    '11111111-1111-1111-1111-111111111111'::uuid,
    'seed.connection.created',
    jsonb_build_object('provider', 'apple_health', 'status', 'connected')
  ),
  (
    '22222222-2222-2222-2222-222222222222'::uuid,
    'seed.connection.created',
    jsonb_build_object('provider', 'apple_health', 'status', 'pending')
  ),
  (
    '33333333-3333-3333-3333-333333333333'::uuid,
    'seed.connection.created',
    jsonb_build_object('provider', 'apple_health', 'status', 'error')
  )
on conflict do nothing;
