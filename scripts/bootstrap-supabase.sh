#!/usr/bin/env bash
set -euo pipefail

SUPABASE_CMD=()
if command -v supabase >/dev/null 2>&1; then
  SUPABASE_CMD=(supabase)
elif command -v npx >/dev/null 2>&1; then
  SUPABASE_CMD=(npx supabase)
else
  echo "Supabase CLI is required: https://supabase.com/docs/guides/cli"
  exit 1
fi

PROJECT_REF="${PROJECT_REF:-<REPLACE_ME>}"
if [[ "${PROJECT_REF}" == "<REPLACE_ME>" ]]; then
  echo "Set PROJECT_REF before running, e.g. PROJECT_REF=abcd1234 ./scripts/bootstrap-supabase.sh"
  exit 1
fi

required_secrets=(
  TERRA_API_KEY
  TERRA_DEV_ID
  TERRA_WEBHOOK_SECRET
  TERRA_ENV
  TERRA_REDIRECT_URL
  ADMIN_ALLOWLIST_EMAILS
)

missing_secrets=()
for key in "${required_secrets[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    missing_secrets+=("${key}")
  fi
done

echo "Linking Supabase project ${PROJECT_REF}..."
"${SUPABASE_CMD[@]}" link --project-ref "${PROJECT_REF}"

echo "Pushing DB migrations..."
"${SUPABASE_CMD[@]}" db push

if [[ ${#missing_secrets[@]} -gt 0 ]]; then
  echo "Skipping secrets upload. Missing env vars: ${missing_secrets[*]}"
  echo "Export them and rerun this script to set function secrets."
else
  echo "Setting edge function secrets..."
  "${SUPABASE_CMD[@]}" secrets set \
    TERRA_API_KEY="${TERRA_API_KEY}" \
    TERRA_DEV_ID="${TERRA_DEV_ID}" \
    TERRA_WEBHOOK_SECRET="${TERRA_WEBHOOK_SECRET}" \
    TERRA_ENV="${TERRA_ENV}" \
    TERRA_REDIRECT_URL="${TERRA_REDIRECT_URL}" \
    ADMIN_ALLOWLIST_EMAILS="${ADMIN_ALLOWLIST_EMAILS}"
fi

echo "Deploying edge functions..."
"${SUPABASE_CMD[@]}" functions deploy terra-webhook
"${SUPABASE_CMD[@]}" functions deploy terra-connect
"${SUPABASE_CMD[@]}" functions deploy terra-status
"${SUPABASE_CMD[@]}" functions deploy admin-metrics

echo "Bootstrap complete."
