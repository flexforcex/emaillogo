import { getEnv } from './env.ts';
import { logWarn } from './logger.ts';
import type { TerraConnectResponse } from './types.ts';

type JsonObject = Record<string, unknown>;

function asObject(value: unknown): JsonObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as JsonObject)
    : {};
}

function ensureTrailingSlashless(url: string): string {
  return url.endsWith('/') ? url.slice(0, -1) : url;
}

function header(name: string, value: string): [string, string] {
  return [name, value];
}

export class TerraApiClient {
  private baseUrl: string;
  private apiKey: string;
  private devId: string;

  constructor() {
    const env = getEnv();
    this.baseUrl = ensureTrailingSlashless(env.TERRA_BASE_URL);
    this.apiKey = env.TERRA_API_KEY;
    this.devId = env.TERRA_DEV_ID;
  }

  private async request(
    path: string,
    body: JsonObject,
  ): Promise<JsonObject> {
    const url = `${this.baseUrl}${path}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: Object.fromEntries([
        header('Content-Type', 'application/json'),
        header('x-api-key', this.apiKey),
        header('dev-id', this.devId),
      ]),
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const responseText = await response.text();
      throw new Error(`Terra API error ${response.status}: ${responseText}`);
    }

    const payload = await response.json();
    return asObject(payload);
  }

  async createUser(externalUserId: string): Promise<string> {
    // TODO: verify endpoint/body contract against final Terra account docs.
    const payload = await this.request('/v2/auth/generateUserId', {
      reference_id: externalUserId,
    });

    const userId = payload.user_id ?? payload.terra_user_id ??
      asObject(payload.user).user_id;
    if (typeof userId !== 'string' || userId.trim().length === 0) {
      throw new Error('Terra create user did not return user_id');
    }

    return userId.trim();
  }

  async createConnectSession(terraUserId: string): Promise<TerraConnectResponse> {
    const env = getEnv();

    // TODO: verify endpoint/body contract against final Terra account docs.
    const payload = await this.request('/v2/auth/generateWidgetSession', {
      language: 'en',
      providers: ['APPLE_HEALTH'],
      auth_success_redirect_url: env.TERRA_REDIRECT_URL,
      auth_failure_redirect_url: env.TERRA_REDIRECT_URL,
      reference_id: terraUserId,
      user_id: terraUserId,
    });

    const connectUrl = payload.url ?? payload.widget_url ?? payload.auth_url ?? null;
    const connectToken = payload.token ?? payload.session_id ?? null;

    if (!connectUrl && !connectToken) {
      logWarn('Terra connect session missing URL/token', { terraUserId, payload });
    }

    return {
      terraUserId,
      provider: 'apple_health',
      connectUrl: typeof connectUrl === 'string' ? connectUrl : null,
      connectToken: typeof connectToken === 'string' ? connectToken : null,
    };
  }
}
