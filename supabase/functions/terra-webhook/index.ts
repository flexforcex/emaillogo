import { getEnv } from '../_shared/env.ts';
import { getRequestId, json, methodNotAllowed, preflight } from '../_shared/http.ts';
import { logError, logInfo, logWarn } from '../_shared/logger.ts';
import { verifyTerraSignature } from '../_shared/signature.ts';
import { getServiceRoleClient } from '../_shared/supabase.ts';
import { normalizeTerraWebhookPayload } from '../_shared/terraPayload.ts';
import type { ConnectionStatus, DailyMetricPatch } from '../_shared/types.ts';

type JsonObject = Record<string, unknown>;

function asObject(value: unknown): JsonObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as JsonObject)
    : {};
}

function toHex(bytes: Uint8Array): string {
  return [...bytes].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(input));
  return toHex(new Uint8Array(digest));
}

function isDuplicateInsertError(error: unknown): boolean {
  const err = asObject(error);
  return err.code === '23505' || String(err.message ?? '').toLowerCase().includes('duplicate');
}

function derivedStatus(
  eventStatus: ConnectionStatus | undefined,
  metricCount: number,
  currentStatus: ConnectionStatus,
): ConnectionStatus {
  if (eventStatus) {
    return eventStatus;
  }
  if (metricCount > 0) {
    return 'connected';
  }
  return currentStatus;
}

async function upsertDailyMetrics(
  supabase: ReturnType<typeof getServiceRoleClient>,
  userId: string,
  metrics: DailyMetricPatch[],
  occurredAtIso: string,
): Promise<void> {
  for (const metric of metrics) {
    const { data: existing, error: fetchError } = await supabase
      .from('biometrics_daily')
      .select('steps,sleep_minutes,hrv,rhr,calories,active_minutes')
      .eq('user_id', userId)
      .eq('date', metric.date)
      .maybeSingle();

    if (fetchError) {
      throw new Error(`Failed to load existing biometrics_daily row: ${fetchError.message}`);
    }

    const mergedRow = {
      user_id: userId,
      date: metric.date,
      steps: metric.steps ?? existing?.steps ?? 0,
      sleep_minutes: metric.sleepMinutes ?? existing?.sleep_minutes ?? 0,
      hrv: metric.hrv ?? existing?.hrv ?? null,
      rhr: metric.rhr ?? existing?.rhr ?? null,
      calories: metric.calories ?? existing?.calories ?? 0,
      active_minutes: metric.activeMinutes ?? existing?.active_minutes ?? 0,
    };

    const { error: upsertError } = await supabase
      .from('biometrics_daily')
      .upsert(mergedRow, { onConflict: 'user_id,date' });
    if (upsertError) {
      throw new Error(`Failed to upsert biometrics_daily row: ${upsertError.message}`);
    }

    const dailyTs = new Date(`${metric.date}T12:00:00.000Z`).toISOString();
    const rawRows = [
      metric.steps !== undefined
        ? {
          user_id: userId,
          source: 'terra',
          metric_type: 'steps',
          ts: dailyTs,
          value: metric.steps,
          unit: 'count',
          payload: metric.payload,
        }
        : null,
      metric.sleepMinutes !== undefined
        ? {
          user_id: userId,
          source: 'terra',
          metric_type: 'sleep_minutes',
          ts: dailyTs,
          value: metric.sleepMinutes,
          unit: 'minutes',
          payload: metric.payload,
        }
        : null,
      metric.hrv !== undefined
        ? {
          user_id: userId,
          source: 'terra',
          metric_type: 'hrv',
          ts: occurredAtIso,
          value: metric.hrv,
          unit: 'ms',
          payload: metric.payload,
        }
        : null,
      metric.rhr !== undefined
        ? {
          user_id: userId,
          source: 'terra',
          metric_type: 'rhr',
          ts: occurredAtIso,
          value: metric.rhr,
          unit: 'bpm',
          payload: metric.payload,
        }
        : null,
      metric.calories !== undefined
        ? {
          user_id: userId,
          source: 'terra',
          metric_type: 'calories',
          ts: dailyTs,
          value: metric.calories,
          unit: 'kcal',
          payload: metric.payload,
        }
        : null,
      metric.activeMinutes !== undefined
        ? {
          user_id: userId,
          source: 'terra',
          metric_type: 'active_minutes',
          ts: dailyTs,
          value: metric.activeMinutes,
          unit: 'minutes',
          payload: metric.payload,
        }
        : null,
    ].filter((entry): entry is Record<string, unknown> => !!entry);

    if (rawRows.length > 0) {
      const { error: rawError } = await supabase
        .from('biometrics_raw')
        .upsert(rawRows, {
          onConflict: 'user_id,source,metric_type,ts,value,unit',
        });
      if (rawError) {
        throw new Error(`Failed to upsert biometrics_raw rows: ${rawError.message}`);
      }
    }
  }
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
  const supabase = getServiceRoleClient();
  let eventIdForError: string | null = null;

  try {
    const env = getEnv();
    const rawBody = await req.text();
    const signature = await verifyTerraSignature(rawBody, req.headers, env.TERRA_WEBHOOK_SECRET);

    if (!signature.isValid) {
      logWarn('Terra signature validation failed', {
        requestId,
        providedSignatures: signature.signatures,
      });
      return json({ error: 'Invalid signature' }, 401);
    }

    let payload: unknown;
    try {
      payload = JSON.parse(rawBody);
    } catch {
      return json({ error: 'Invalid JSON payload' }, 400);
    }

    const normalized = normalizeTerraWebhookPayload(payload);
    const eventId = normalized.eventId ?? `hash-${await sha256Hex(rawBody)}`;
    eventIdForError = eventId;

    const receiptInsertPayload = {
      event_id: eventId,
      terra_user_id: normalized.terraUserId,
      event_type: normalized.eventType,
      payload: normalized.rawPayload,
    };

    const { error: receiptInsertError } = await supabase
      .from('terra_webhook_receipts')
      .insert(receiptInsertPayload);

    if (receiptInsertError) {
      if (isDuplicateInsertError(receiptInsertError)) {
        logInfo('Duplicate Terra webhook ignored', { requestId, eventId });
        return json({ ok: true, duplicate: true, event_id: eventId });
      }
      throw new Error(`Failed to insert webhook receipt: ${receiptInsertError.message}`);
    }

    if (!normalized.terraUserId) {
      await supabase
        .from('terra_webhook_receipts')
        .update({
          processed_at: new Date().toISOString(),
          error_message: 'Missing terra_user_id in payload',
        })
        .eq('event_id', eventId);

      logWarn('Webhook payload missing terra user id', { requestId, eventId });
      return json({ ok: true, skipped: true, reason: 'missing_terra_user_id' }, 202);
    }

    const { data: connection, error: connectionError } = await supabase
      .from('terra_connections')
      .select('id,user_id,status,connected_at,metadata')
      .eq('terra_user_id', normalized.terraUserId)
      .eq('provider', 'apple_health')
      .maybeSingle();

    if (connectionError) {
      throw new Error(`Failed to resolve terra connection: ${connectionError.message}`);
    }

    if (!connection) {
      await supabase
        .from('terra_webhook_receipts')
        .update({
          processed_at: new Date().toISOString(),
          error_message: 'No local terra connection mapping found',
        })
        .eq('event_id', eventId);

      const { error: unmappedAuditError } = await supabase.from('events_audit').insert({
        event_type: 'terra.webhook.unmapped',
        payload: {
          request_id: requestId,
          event_id: eventId,
          terra_user_id: normalized.terraUserId,
          event_type: normalized.eventType,
        },
      });
      if (unmappedAuditError) {
        logWarn('Failed to write unmapped webhook audit', {
          requestId,
          eventId,
          error: unmappedAuditError.message,
        });
      }

      return json({ ok: true, skipped: true, reason: 'unmapped_terra_user' }, 202);
    }

    await upsertDailyMetrics(supabase, connection.user_id, normalized.metrics, normalized.occurredAt);

    const status = derivedStatus(
      normalized.connectionStatus,
      normalized.metrics.length,
      connection.status as ConnectionStatus,
    );
    const nowIso = new Date().toISOString();
    const connectedAt = status === 'connected'
      ? (connection.connected_at ?? nowIso)
      : connection.connected_at;
    const metadata = {
      ...asObject(connection.metadata),
      last_webhook_event_id: eventId,
      last_webhook_event_type: normalized.eventType,
      last_webhook_received_at: nowIso,
    };

    const { error: connectionUpdateError } = await supabase
      .from('terra_connections')
      .update({
        status,
        connected_at: connectedAt,
        last_sync_at: nowIso,
        metadata,
      })
      .eq('id', connection.id);

    if (connectionUpdateError) {
      throw new Error(`Failed to update terra connection status: ${connectionUpdateError.message}`);
    }

    const { error: auditError } = await supabase.from('events_audit').insert({
      user_id: connection.user_id,
      event_type: 'terra.webhook.processed',
      payload: {
        request_id: requestId,
        event_id: eventId,
        event_type: normalized.eventType,
        metric_days_upserted: normalized.metrics.length,
        terra_user_id: normalized.terraUserId,
      },
    });

    if (auditError) {
      logWarn('Failed to write processed webhook audit event', {
        requestId,
        eventId,
        error: auditError.message,
      });
    }

    const { error: receiptUpdateError } = await supabase
      .from('terra_webhook_receipts')
      .update({
        user_id: connection.user_id,
        processed_at: nowIso,
        error_message: null,
      })
      .eq('event_id', eventId);

    if (receiptUpdateError) {
      logWarn('Failed to mark webhook receipt processed', {
        requestId,
        eventId,
        error: receiptUpdateError.message,
      });
    }

    logInfo('Terra webhook processed', {
      requestId,
      eventId,
      eventType: normalized.eventType,
      userId: connection.user_id,
      metricDays: normalized.metrics.length,
      status,
    });

    return json({
      ok: true,
      event_id: eventId,
      user_id: connection.user_id,
      metric_days_upserted: normalized.metrics.length,
      status,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    logError('Terra webhook function failed', { requestId, eventId: eventIdForError, error: message });

    if (eventIdForError) {
      await supabase
        .from('terra_webhook_receipts')
        .update({
          processed_at: new Date().toISOString(),
          error_message: message,
        })
        .eq('event_id', eventIdForError);
    }

    return json({ error: message, request_id: requestId }, 500);
  }
});
