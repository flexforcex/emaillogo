# Flex Force X Monorepo (MVP Trial)

Production-lean monorepo for the Flex Force X 50-person iOS trial.

## Monorepo layout

```text
.
├── ios/                   # SwiftUI iOS app
├── web/                   # Next.js trial admin portal (Vercel)
├── supabase/              # Database migrations, seed data, edge functions
│   ├── functions/
│   └── migrations/
└── docs/                  # Architecture and implementation docs
```

## Current implementation phase

This commit bootstraps:

- monorepo structure
- Supabase schema migrations
- Row Level Security (RLS) policies
- local SQL seed data for trial simulation

## Quick start (Supabase local)

1. Install Supabase CLI:
   - https://supabase.com/docs/guides/cli
2. From repo root:
   - `supabase start`
   - `supabase db reset` (applies migrations + `supabase/seed.sql`)
3. Inspect generated API:
   - Studio: `http://127.0.0.1:54323`
   - API: `http://127.0.0.1:54321`

## Environment variables

Create `.env.example`-style files for each app module (full wiring added in next steps):

- Supabase
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
- Terra
  - `TERRA_API_KEY`
  - `TERRA_DEV_ID`
  - `TERRA_WEBHOOK_SECRET`
  - `TERRA_ENV`
  - `TERRA_REDIRECT_URL`
- Web (Vercel)
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
- iOS (xcconfig)
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - deep link scheme: `flexforcex://terra-callback`

## Notes

- Supabase is the source of truth for user, connection, and biometrics data.
- HealthKit raw data is ingested through Terra webhook flows into Supabase.
- iOS client reads normalized tables (`biometrics_daily`, `terra_connections`) only.
