import type { ConnectionStatus, DailyMetricPatch, NormalizedTerraEvent } from './types.ts';

type JsonRecord = Record<string, unknown>;

function asRecord(value: unknown): JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as JsonRecord)
    : {};
}

function getValueByPath(record: JsonRecord, path: string[]): unknown {
  let cursor: unknown = record;
  for (const segment of path) {
    if (typeof cursor !== 'object' || cursor === null || Array.isArray(cursor)) {
      return undefined;
    }
    cursor = (cursor as JsonRecord)[segment];
  }
  return cursor;
}

function firstString(record: JsonRecord, paths: string[][]): string | null {
  for (const path of paths) {
    const value = getValueByPath(record, path);
    if (typeof value === 'string' && value.trim().length > 0) {
      return value.trim();
    }
  }
  return null;
}

function firstNumber(record: JsonRecord, paths: string[][]): number | null {
  for (const path of paths) {
    const value = getValueByPath(record, path);
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }
    if (typeof value === 'string' && value.trim().length > 0) {
      const parsed = Number(value);
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }
  return null;
}

function toDateOnly(input: string): string | null {
  const parsed = new Date(input);
  if (Number.isNaN(parsed.valueOf())) {
    return null;
  }
  return parsed.toISOString().slice(0, 10);
}

function toIsoTimestamp(input: string | null): string {
  if (!input) {
    return new Date().toISOString();
  }
  const parsed = new Date(input);
  if (Number.isNaN(parsed.valueOf())) {
    return new Date().toISOString();
  }
  return parsed.toISOString();
}

function inferConnectionStatus(record: JsonRecord, eventType: string): ConnectionStatus | undefined {
  const explicit = firstString(record, [['status'], ['connection', 'status']])?.toLowerCase();
  if (explicit === 'connected' || explicit === 'pending' || explicit === 'error' ||
    explicit === 'disconnected') {
    return explicit;
  }

  if (eventType.includes('disconnect') || eventType.includes('revoked')) {
    return 'disconnected';
  }
  if (eventType.includes('error') || eventType.includes('fail')) {
    return 'error';
  }
  if (eventType.includes('auth') || eventType.includes('connect') || eventType.includes('sync')) {
    return 'connected';
  }
  return undefined;
}

function round(value: number): number {
  return Math.round(value * 100) / 100;
}

function coerceMetrics(record: JsonRecord, fallbackDate: string): DailyMetricPatch | null {
  const rawDate = firstString(record, [
    ['date'],
    ['day'],
    ['start_time'],
    ['start_date'],
    ['timestamp'],
    ['metadata', 'date'],
  ]);
  const date = rawDate ? toDateOnly(rawDate) ?? fallbackDate : fallbackDate;

  const steps = firstNumber(record, [['steps'], ['summary', 'steps'], ['distance_data', 'steps']]);

  const sleepMinutes = (() => {
    const asMinutes = firstNumber(record, [
      ['sleep_minutes'],
      ['sleep_duration_minutes'],
      ['sleep', 'total_sleep_duration_minutes'],
    ]);
    if (asMinutes !== null) {
      return round(asMinutes);
    }
    const asSeconds = firstNumber(record, [
      ['sleep_duration_seconds'],
      ['sleep', 'total_sleep_duration_seconds'],
    ]);
    return asSeconds !== null ? round(asSeconds / 60) : null;
  })();

  const hrv = firstNumber(record, [['hrv'], ['summary', 'hrv'], ['hrv_data', 'avg_rmssd'], ['rmssd']]);
  const rhr = firstNumber(record, [
    ['rhr'],
    ['resting_heart_rate'],
    ['summary', 'resting_heart_rate'],
    ['heart_rate_data', 'resting_heart_rate'],
  ]);

  const calories = firstNumber(record, [
    ['calories'],
    ['calories_burned'],
    ['active_calories'],
    ['summary', 'calories'],
  ]);

  const activeMinutes = (() => {
    const direct = firstNumber(record, [
      ['active_minutes'],
      ['active_duration_minutes'],
      ['summary', 'active_minutes'],
    ]);
    if (direct !== null) {
      return round(direct);
    }
    const asSeconds = firstNumber(record, [['active_duration_seconds'], ['active_time_seconds']]);
    return asSeconds !== null ? round(asSeconds / 60) : null;
  })();

  const hasMetrics = [steps, sleepMinutes, hrv, rhr, calories, activeMinutes].some((value) =>
    value !== null
  );
  if (!hasMetrics) {
    return null;
  }

  return {
    date,
    ...(steps !== null ? { steps: Math.max(0, Math.round(steps)) } : {}),
    ...(sleepMinutes !== null ? { sleepMinutes: Math.max(0, Math.round(sleepMinutes)) } : {}),
    ...(hrv !== null ? { hrv: Math.max(0, round(hrv)) } : {}),
    ...(rhr !== null ? { rhr: Math.max(0, round(rhr)) } : {}),
    ...(calories !== null ? { calories: Math.max(0, Math.round(calories)) } : {}),
    ...(activeMinutes !== null ? { activeMinutes: Math.max(0, Math.round(activeMinutes)) } : {}),
    payload: record,
  };
}

export function normalizeTerraWebhookPayload(payload: unknown): NormalizedTerraEvent {
  const root = asRecord(payload);

  const eventType = (firstString(root, [['type'], ['event'], ['event_type']]) ?? 'unknown')
    .toLowerCase();
  const eventId = firstString(root, [['id'], ['event_id'], ['event', 'id'], ['uuid']]);
  const terraUserId = firstString(root, [
    ['user', 'user_id'],
    ['user', 'id'],
    ['user_id'],
    ['terra_user_id'],
    ['athlete', 'user_id'],
    ['data', 'user_id'],
  ]);

  const occurredAt = toIsoTimestamp(
    firstString(root, [['timestamp'], ['created_at'], ['event_ts'], ['event_timestamp']]),
  );

  const status = inferConnectionStatus(root, eventType);
  const fallbackDate = occurredAt.slice(0, 10);

  const candidates = Array.isArray(root.data) ? root.data : [root];
  const metrics = candidates
    .map((entry) => coerceMetrics(asRecord(entry), fallbackDate))
    .filter((entry): entry is DailyMetricPatch => entry !== null);

  return {
    eventId,
    eventType,
    terraUserId,
    occurredAt,
    metrics,
    rawPayload: root,
    ...(status ? { connectionStatus: status } : {}),
  };
}
