# Flex Force X Monorepo (MVP Trial)

Production-lean monorepo for the Flex Force X 50-person trial.

## Repository structure

```text
.
├── ios/                              # SwiftUI iOS app (XcodeGen)
│   ├── project.yml
│   ├── Config/*.xcconfig
│   └── FlexForceX/
├── web/                              # Next.js admin portal (Vercel)
│   ├── app/
│   ├── lib/
│   └── package.json
├── supabase/
│   ├── migrations/                   # SQL schema + RLS
│   ├── functions/                    # Edge Functions
│   ├── seed.sql                      # 3 trial users + biometrics sample
│   └── .env.local.example
├── scripts/
│   ├── bootstrap-supabase.sh         # Link/push/deploy/secrets
│   └── replay-terra-webhook.mjs      # webhook replay runner
└── docs/
    ├── FIGMA_MAPPING.md
    └── SUPABASE_SCHEMA.md
```

## MVP currently implemented

- Supabase schema + RLS + local seed data
- Edge Functions:
  - `terra-webhook`
  - `terra-connect`
  - `terra-status`
  - `admin-metrics`
- Terra webhook signature verification + idempotency receipts table
- iOS app (SwiftUI):
  - Sign in with Apple + email/password
  - onboarding + Terra connect
  - connection status + last sync
  - dashboard + insights + settings + issue report
- Web admin portal (Next.js):
  - login
  - user list + connection state
  - flag issues
  - CSV export

## 1) Rebuild Supabase from start

### Local

```bash
supabase start
supabase db reset
cp supabase/.env.local.example supabase/.env.local
supabase functions serve --env-file ./supabase/.env.local
```

### Remote project bootstrap

```bash
export PROJECT_REF=<REPLACE_ME>
export TERRA_API_KEY=<REPLACE_ME>
export TERRA_DEV_ID=<REPLACE_ME>
export TERRA_WEBHOOK_SECRET=<REPLACE_ME>
export TERRA_ENV=sandbox
export TERRA_REDIRECT_URL=flexforcex://terra-callback
export ADMIN_ALLOWLIST_EMAILS=admin@flexforcex.com

./scripts/bootstrap-supabase.sh
```

This script performs:
1. `supabase link --project-ref`
2. `supabase db push`
3. `supabase secrets set ...`
4. `supabase functions deploy ...`

## 2) Terra webhook local test

1. Expose local functions URL with ngrok:
   - `ngrok http 54321`
2. In Terra dashboard (sandbox), set webhook URL to:
   - `https://<NGROK_ID>.ngrok-free.app/functions/v1/terra-webhook`
3. Replay included sample payload:

```bash
TERRA_WEBHOOK_SECRET=<REPLACE_ME> node scripts/replay-terra-webhook.mjs
```

## 3) Run iOS app

```bash
cd ios
brew install xcodegen
xcodegen generate
open FlexForceX.xcodeproj
```

Set `SUPABASE_URL` + `SUPABASE_ANON_KEY` in `ios/Config/*.xcconfig`.

Deep link callback configured as:
- `flexforcex://terra-callback`

## 4) Run admin web portal

```bash
cd web
cp .env.example .env.local
npm install
npm run dev
```

## 5) Deploy web portal to Vercel

1. Import repository into Vercel
2. Set root directory to `web`
3. Add env vars:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `ADMIN_ALLOWLIST_EMAILS`
4. Deploy from `main`

## 6) Edge function tests

```bash
cd supabase/functions
deno test tests
```

## Environment variables (full list)

### Supabase / Functions
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (client/mobile/web)
- `SUPABASE_SERVICE_ROLE_KEY` (server/functions only)

### Terra
- `TERRA_API_KEY`
- `TERRA_DEV_ID`
- `TERRA_WEBHOOK_SECRET`
- `TERRA_ENV` (`sandbox` or `production`)
- `TERRA_REDIRECT_URL` (`flexforcex://terra-callback`)

### Vercel / web
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ADMIN_ALLOWLIST_EMAILS`

### iOS xcconfig
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `APP_DEEP_LINK_SCHEME=flexforcex`

## Notes

- Supabase is the source of truth for users, connections, metrics, plans, and audit events.
- iOS does not persist raw HealthKit payloads.
- Terra endpoint path/body specifics are isolated in `supabase/functions/_shared/terra.ts` with TODO comments for final account-level confirmation.
