# Supabase Edge Functions

Implemented functions:

- `terra-webhook`: receives Terra webhook events, validates signature, dedupes by event ID,
  upserts `biometrics_daily`, updates `terra_connections`, and writes `events_audit`.
- `terra-connect`: authenticated endpoint that creates/loads Terra user mapping and returns connect
  session URL/token.
- `terra-status`: authenticated endpoint returning provider connection status and `last_sync_at`.
- `admin-metrics`: authenticated admin-only aggregate metrics for trial operations.

## Local serve

```bash
supabase functions serve --env-file ./supabase/.env.local
```

## Local invoke examples

```bash
curl -X POST "http://127.0.0.1:54321/functions/v1/terra-connect" \
  -H "Authorization: Bearer <SUPABASE_JWT>"

curl "http://127.0.0.1:54321/functions/v1/terra-status" \
  -H "Authorization: Bearer <SUPABASE_JWT>"

curl "http://127.0.0.1:54321/functions/v1/admin-metrics" \
  -H "Authorization: Bearer <ADMIN_SUPABASE_JWT>"
```

## Webhook replay

Use the included replay runner:

```bash
TERRA_WEBHOOK_SECRET=<REPLACE_ME> node scripts/replay-terra-webhook.mjs
```
