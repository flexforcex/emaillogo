# Supabase Backend

This directory contains:

- `migrations/`: versioned SQL schema and policy migrations
- `functions/`: Supabase Edge Functions (Terra webhook/connect/status/admin metrics)
- `seed.sql`: local trial data seeding

## Local usage

```bash
supabase start
supabase db reset
```

`db reset` applies migrations and `seed.sql`.

## Edge function env vars

Create `supabase/.env.local` for local function runtime:

```bash
SUPABASE_URL=<REPLACE_ME>
SUPABASE_SERVICE_ROLE_KEY=<REPLACE_ME>
TERRA_API_KEY=<REPLACE_ME>
TERRA_DEV_ID=<REPLACE_ME>
TERRA_WEBHOOK_SECRET=<REPLACE_ME>
TERRA_ENV=sandbox
TERRA_REDIRECT_URL=flexforcex://terra-callback
ADMIN_ALLOWLIST_EMAILS=admin1@flexforcex.com,admin2@flexforcex.com
```

Serve functions locally:

```bash
supabase functions serve --env-file ./supabase/.env.local
```

Run unit tests:

```bash
cd supabase/functions
deno test tests
```
