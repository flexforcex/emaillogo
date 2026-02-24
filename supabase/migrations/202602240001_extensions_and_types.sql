-- Flex Force X - migration 001
-- Extensions and shared enum types

create extension if not exists pgcrypto;

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'connection_status'
      and n.nspname = 'public'
  ) then
    create type public.connection_status as enum (
      'pending',
      'connected',
      'error',
      'disconnected'
    );
  end if;
end
$$;
