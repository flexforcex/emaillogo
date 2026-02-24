import { AuthError, requireAuthenticatedUser } from '../_shared/auth.ts';
import { getEnv } from '../_shared/env.ts';
import { getRequestId, json, methodNotAllowed, preflight } from '../_shared/http.ts';
import { logError, logInfo } from '../_shared/logger.ts';
import { getServiceRoleClient } from '../_shared/supabase.ts';

Deno.serve(async (req: Request) => {
  const preflightResponse = preflight(req);
  if (preflightResponse) {
    return preflightResponse;
  }

  if (req.method !== 'GET') {
    return methodNotAllowed(['GET', 'OPTIONS']);
  }

  const requestId = getRequestId(req);
  try {
    const env = getEnv();
    const supabase = getServiceRoleClient();
    const { user } = await requireAuthenticatedUser(req, supabase, {
      adminAllowlist: env.ADMIN_ALLOWLIST_EMAILS,
    });

    const { data, error } = await supabase
      .from('terra_connections')
      .select('provider,status,connected_at,last_sync_at,terra_user_id,metadata')
      .eq('user_id', user.id)
      .eq('provider', 'apple_health')
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to fetch terra connection status: ${error.message}`);
    }

    if (!data) {
      return json({
        status: 'disconnected',
        provider: 'apple_health',
        connected_at: null,
        last_sync_at: null,
        terra_user_id: null,
      });
    }

    logInfo('Terra status fetched', {
      requestId,
      userId: user.id,
      status: data.status,
      lastSyncAt: data.last_sync_at,
    });

    return json({
      status: data.status,
      provider: data.provider,
      connected_at: data.connected_at,
      last_sync_at: data.last_sync_at,
      terra_user_id: data.terra_user_id,
      metadata: data.metadata,
    });
  } catch (error) {
    if (error instanceof AuthError) {
      return json({ error: error.message }, error.status);
    }

    const message = error instanceof Error ? error.message : 'Unknown error';
    logError('Terra status function failed', { requestId, error: message });
    return json({ error: message, request_id: requestId }, 500);
  }
});
