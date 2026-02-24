#!/usr/bin/env bash
set -euo pipefail

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI is required: https://supabase.com/docs/guides/cli"
  exit 1
fi

PROJECT_REF="${PROJECT_REF:-<REPLACE_ME>}"

if [[ "${PROJECT_REF}" == "<REPLACE_ME>" ]]; then
  echo "Set PROJECT_REF before running, e.g. PROJECT_REF=abcd1234 ./scripts/bootstrap-supabase.sh"
  exit 1
fi

echo "Linking Supabase project ${PROJECT_REF}..."
supabase link --project-ref "${PROJECT_REF}"

echo "Pushing DB migrations..."
supabase db push

echo "Deploying edge functions..."
# Functions will be added in subsequent steps.
# supabase functions deploy terra-webhook
# supabase functions deploy terra-connect
# supabase functions deploy terra-status
# supabase functions deploy admin-metrics

echo "Bootstrap complete (functions currently scaffold-only)."
