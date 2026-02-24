export type ConnectionStatus = 'pending' | 'connected' | 'error' | 'disconnected';

export interface AppEnv {
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  TERRA_API_KEY: string;
  TERRA_DEV_ID: string;
  TERRA_WEBHOOK_SECRET: string;
  TERRA_ENV: 'sandbox' | 'production';
  TERRA_REDIRECT_URL: string;
  TERRA_BASE_URL: string;
  ADMIN_ALLOWLIST_EMAILS: string[];
}

export interface RequestContext {
  requestId: string;
  path: string;
}

export interface TerraConnectResponse {
  terraUserId: string;
  provider: string;
  connectUrl: string | null;
  connectToken: string | null;
}

export interface DailyMetricPatch {
  date: string;
  steps?: number;
  sleepMinutes?: number;
  hrv?: number;
  rhr?: number;
  calories?: number;
  activeMinutes?: number;
  payload: Record<string, unknown>;
}

export interface NormalizedTerraEvent {
  eventId: string | null;
  eventType: string;
  terraUserId: string | null;
  occurredAt: string;
  metrics: DailyMetricPatch[];
  rawPayload: Record<string, unknown>;
  connectionStatus?: ConnectionStatus;
}
