# Deploy pipeline

## GitHub Actions workflows

### 1) Supabase backend deploy

Workflow: `.github/workflows/supabase-backend-deploy.yml`

Triggers:
- push to `main` affecting `supabase/**`
- manual dispatch

Steps:
1. Link project
2. Push migrations
3. Set function secrets
4. Deploy edge functions

Required repo secrets:

- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_PROJECT_REF`
- `SUPABASE_DB_PASSWORD`
- `TERRA_API_KEY`
- `TERRA_DEV_ID`
- `TERRA_WEBHOOK_SECRET`
- `TERRA_ENV`
- `TERRA_REDIRECT_URL`
- `ADMIN_ALLOWLIST_EMAILS`

### 2) Vercel web deploy

Workflow: `.github/workflows/web-vercel-deploy.yml`

Triggers:
- push to `main` affecting `web/**`
- manual dispatch

Steps:
1. Install deps
2. Lint + typecheck + build
3. Pull Vercel env
4. Build + deploy to Vercel production

Required repo secrets:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`

## Optional alternative

You can skip the web deploy workflow and use Vercel Git integration directly.
