import { createClient } from '@supabase/supabase-js';
import { getEnv } from './env.ts';

export function getServiceRoleClient() {
  const env = getEnv();
  return createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
