# Supabase schema notes (MVP)

## Core tables

- `profiles`: app-level profile metadata keyed by `auth.users.id`.
- `terra_connections`: one row per user/provider integration status.
- `biometrics_raw`: optional low-level ingestion records (minimal retained payload).
- `biometrics_daily`: normalized daily aggregates consumed by iOS dashboard.
- `events_audit`: user/system events for observability and support.
- `ai_plans_daily`: placeholder JSON plans keyed by user/date.
- `terra_webhook_receipts`: dedupe and processing ledger for webhook idempotency.

## RLS model

- Authenticated users can access only rows where `user_id = auth.uid()`.
- `biometrics_raw` is user-readable but backend-write only.
- `terra_webhook_receipts` has no client policies (service role only path).

## Why this supports trial reliability

- Idempotency ledger prevents duplicate Terra event writes.
- Narrow ownership policies reduce accidental data leakage risk.
- Indexed query paths keep dashboard/admin list queries fast for trial scale.
