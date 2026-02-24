import type { SupabaseClient, User } from '@supabase/supabase-js';

export class AuthError extends Error {
  status: number;

  constructor(message: string, status = 401) {
    super(message);
    this.name = 'AuthError';
    this.status = status;
  }
}

export interface AuthenticatedContext {
  user: User;
  accessToken: string;
  isAdmin: boolean;
}

function parseBearerToken(headerValue: string | null): string {
  if (!headerValue) {
    throw new AuthError('Missing Authorization header');
  }

  const [scheme, token] = headerValue.split(' ');
  if (!scheme || !token || scheme.toLowerCase() !== 'bearer') {
    throw new AuthError('Authorization must be a Bearer token');
  }

  return token;
}

function userHasAdminRole(user: User, allowlist: string[]): boolean {
  const appMetadata = user.app_metadata ?? {};
  const role = typeof appMetadata.role === 'string' ? appMetadata.role.toLowerCase() : null;
  const roles = Array.isArray(appMetadata.roles)
    ? appMetadata.roles.map((entry) => String(entry).toLowerCase())
    : [];

  if (role === 'admin' || roles.includes('admin')) {
    return true;
  }

  const email = user.email?.toLowerCase();
  return !!email && allowlist.includes(email);
}

export async function requireAuthenticatedUser(
  req: Request,
  supabase: SupabaseClient,
  options: { adminAllowlist?: string[] } = {},
): Promise<AuthenticatedContext> {
  const accessToken = parseBearerToken(req.headers.get('authorization'));
  const { data, error } = await supabase.auth.getUser(accessToken);

  if (error || !data?.user) {
    throw new AuthError('Invalid or expired auth token');
  }

  const allowlist = options.adminAllowlist ?? [];
  return {
    user: data.user,
    accessToken,
    isAdmin: userHasAdminRole(data.user, allowlist),
  };
}
