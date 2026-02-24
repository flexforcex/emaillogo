import { createClient } from '@supabase/supabase-js';

type VerifiedAdmin = {
  userId: string;
  email: string | null;
  accessToken: string;
};

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing environment variable ${name}`);
  }
  return value;
}

function parseBearerToken(headerValue: string | null): string {
  if (!headerValue) {
    throw new Error('Missing Authorization header');
  }
  const [scheme, token] = headerValue.split(' ');
  if (!scheme || !token || scheme.toLowerCase() !== 'bearer') {
    throw new Error('Authorization header must be Bearer token');
  }
  return token;
}

function isAdminRole(appMetadata: Record<string, unknown> | undefined): boolean {
  if (!appMetadata) {
    return false;
  }
  const role = typeof appMetadata.role === 'string' ? appMetadata.role.toLowerCase() : '';
  const roles = Array.isArray(appMetadata.roles)
    ? appMetadata.roles.map((entry) => String(entry).toLowerCase())
    : [];
  return role === 'admin' || roles.includes('admin');
}

function allowlistEmails(): string[] {
  return (process.env.ADMIN_ALLOWLIST_EMAILS ?? '')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

function getAdminClient() {
  return createClient(
    requiredEnv('NEXT_PUBLIC_SUPABASE_URL'),
    requiredEnv('SUPABASE_SERVICE_ROLE_KEY'),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}

export async function requireAdminFromRequest(request: Request): Promise<VerifiedAdmin> {
  const accessToken = parseBearerToken(request.headers.get('authorization'));
  const supabaseAdmin = getAdminClient();
  const { data, error } = await supabaseAdmin.auth.getUser(accessToken);

  if (error || !data.user) {
    throw new Error('Invalid or expired auth token');
  }

  const email = data.user.email ?? null;
  const allowlist = allowlistEmails();
  const allowlisted = !!email && allowlist.includes(email.toLowerCase());
  const adminRole = isAdminRole(data.user.app_metadata);
  if (!allowlisted && !adminRole) {
    throw new Error('Forbidden');
  }

  return {
    userId: data.user.id,
    email,
    accessToken,
  };
}

export function getSupabaseAdminClient() {
  return getAdminClient();
}

export function getSupabasePublicConfig() {
  return {
    url: requiredEnv('NEXT_PUBLIC_SUPABASE_URL'),
    anonKey: requiredEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
  };
}
