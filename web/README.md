# Trial Admin Portal (Next.js + Vercel)

This folder contains the trial operations portal:

- Supabase-authenticated admin login
- trial user list
- Terra connection status + sync health
- issue flagging into `events_audit`
- CSV export for `biometrics_daily`

## Local development

```bash
cd web
cp .env.example .env.local
npm install
npm run dev
```

Open `http://localhost:3000`.

## Required env vars

```text
NEXT_PUBLIC_SUPABASE_URL=<REPLACE_ME>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<REPLACE_ME>
SUPABASE_SERVICE_ROLE_KEY=<REPLACE_ME>
ADMIN_ALLOWLIST_EMAILS=admin1@flexforcex.com,admin2@flexforcex.com
```

## Deploy (Vercel)

1. Import repo in Vercel.
2. Set root directory to `web`.
3. Add environment variables above in Vercel project settings.
4. Deploy from `main` branch.

Recommended Vercel build settings:

- Install command: `npm install`
- Build command: `npm run build`
- Output directory: `.next`
