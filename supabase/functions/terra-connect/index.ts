import { AuthError, requireAuthenticatedUser } from '../_shared/auth.ts';
import { getEnv } from '../_shared/env.ts';
import { getRequestId, json, methodNotAllowed, preflight } from '../_shared/http.ts';
import { logError, logInfo, logWarn } from '../_shared/logger.ts';
import { getServiceRoleClient } from '../_shared/supabase.ts';
import { TerraApiClient } from '../_shared/terra.ts';

type JsonObject = Record<string, unknown>;

function asObject(value: unknown): JsonObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as JsonObject)
    : {};
}

Deno.serve(async (req: Request) => {
  const preflightResponse = preflight(req);
  if (preflightResponse) {
    return preflightResponse;
  }

  if (req.method !== 'POST') {
    return methodNotAllowed(['POST', 'OPTIONS']);
  }

  const requestId = getRequestId(req);

  try {
    const env = getEnv();
    const supabase = getServiceRoleClient();
    const terraApi = new TerraApiClient();

    const { user } = await requireAuthenticatedUser(req, supabase, {
      adminAllowlist: env.ADMIN_ALLOWLIST_EMAILS,
    });

    const body = req.headers.get('content-length') === '0' ? {} : await req.json().catch(() => ({}));
    const bodyObject = asObject(body);
    const forceReconnect = bodyObject.force_reconnect === true;

    const { data: existingConnection, error: existingConnectionError } = await supabase
      .from('terra_connections')
      .select('terra_user_id,status,connected_at,metadata')
      .eq('user_id', user.id)
      .eq('provider', 'apple_health')
      .maybeSingle();

    if (existingConnectionError) {
      throw new Error(`Failed to fetch existing connection: ${existingConnectionError.message}`);
    }

    let terraUserId = existingConnection?.terra_user_id ?? null;
    if (!terraUserId || forceReconnect) {
      terraUserId = await terraApi.createUser(user.id);
    }

    const nowIso = new Date().toISOString();
    const mergedMetadata = {
      ...(asObject(existingConnection?.metadata)),
      last_connect_request_at: nowIso,
      source: 'terra-connect-function',
      force_reconnect: forceReconnect,
    };

    const { error: upsertConnectionError } = await supabase
      .from('terra_connections')
      .upsert(
        {
          user_id: user.id,
          terra_user_id: terraUserId,
          provider: 'apple_health',
          status: existingConnection?.status === 'connected' && !forceReconnect ? 'connected' : 'pending',
          connected_at: existingConnection?.status === 'connected' && !forceReconnect
            ? existingConnection.connected_at ?? nowIso
            : null,
          metadata: mergedMetadata,
        },
        { onConflict: 'user_id,provider' },
      );

    if (upsertConnectionError) {
      throw new Error(`Failed to upsert terra connection: ${upsertConnectionError.message}`);
    }

    const connectSession = await terraApi.createConnectSession(terraUserId);

    const { error: connectionUpdateError } = await supabase
      .from('terra_connections')
      .update({
        status: 'pending',
        metadata: {
          ...mergedMetadata,
          last_connect_session_generated_at: nowIso,
          connect_url_generated: !!connectSession.connectUrl,
        },
      })
      .eq('user_id', user.id)
      .eq('provider', 'apple_health');

    if (connectionUpdateError) {
      logWarn('Could not update connection metadata after connect session', {
        requestId,
        userId: user.id,
        error: connectionUpdateError.message,
      });
    }

    const { error: auditError } = await supabase.from('events_audit').insert({
      user_id: user.id,
      event_type: 'terra.connect.requested',
      payload: {
        request_id: requestId,
        provider: 'apple_health',
        terra_user_id: terraUserId,
        force_reconnect: forceReconnect,
      },
    });
    if (auditError) {
      logWarn('Failed to write terra connect audit event', {
        requestId,
        userId: user.id,
        error: auditError.message,
      });
    }

    logInfo('Terra connect session created', {
      requestId,
      userId: user.id,
      terraUserId,
      hasConnectUrl: !!connectSession.connectUrl,
    });

    return json({
      provider: connectSession.provider,
      terra_user_id: connectSession.terraUserId,
      status: 'pending',
      connect_url: connectSession.connectUrl,
      connect_token: connectSession.connectToken,
      redirect_url: env.TERRA_REDIRECT_URL,
    });
  } catch (error) {
    if (error instanceof AuthError) {
      return json({ error: error.message }, error.status);
    }

    const message = error instanceof Error ? error.message : 'Unknown error';
    logError('Terra connect function failed', { requestId, error: message });
    return json({ error: message, request_id: requestId }, 500);
  }
});
