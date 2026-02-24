import type { AppEnv } from './types.ts';

let cachedEnv: AppEnv | null = null;

function required(name: string): string {
  const value = Deno.env.get(name);
  if (!value || value.trim().length === 0) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function optional(name: string, fallback: string): string {
  const value = Deno.env.get(name);
  if (!value || value.trim().length === 0) {
    return fallback;
  }
  return value.trim();
}

export function getEnv(): AppEnv {
  if (cachedEnv) {
    return cachedEnv;
  }

  const terraEnvRaw = optional('TERRA_ENV', 'sandbox').toLowerCase();
  const terraEnv = terraEnvRaw === 'production' ? 'production' : 'sandbox';
  const defaultTerraBaseUrl = terraEnv === 'production'
    ? 'https://api.tryterra.co'
    : 'https://api.tryterra.co';

  const allowlist = optional('ADMIN_ALLOWLIST_EMAILS', '')
    .split(',')
    .map((entry) => entry.trim().toLowerCase())
    .filter(Boolean);

  cachedEnv = {
    SUPABASE_URL: required('SUPABASE_URL'),
    SUPABASE_SERVICE_ROLE_KEY: required('SUPABASE_SERVICE_ROLE_KEY'),
    TERRA_API_KEY: required('TERRA_API_KEY'),
    TERRA_DEV_ID: required('TERRA_DEV_ID'),
    TERRA_WEBHOOK_SECRET: required('TERRA_WEBHOOK_SECRET'),
    TERRA_ENV: terraEnv,
    TERRA_REDIRECT_URL: required('TERRA_REDIRECT_URL'),
    TERRA_BASE_URL: optional('TERRA_BASE_URL', defaultTerraBaseUrl),
    ADMIN_ALLOWLIST_EMAILS: allowlist,
  };

  return cachedEnv;
}
