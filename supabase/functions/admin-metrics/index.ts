import { AuthError, requireAuthenticatedUser } from '../_shared/auth.ts';
import { getEnv } from '../_shared/env.ts';
import { getRequestId, json, methodNotAllowed, preflight } from '../_shared/http.ts';
import { logError, logInfo } from '../_shared/logger.ts';
import { getServiceRoleClient } from '../_shared/supabase.ts';

function average(values: number[]): number | null {
  if (values.length === 0) {
    return null;
  }
  const total = values.reduce((sum, value) => sum + value, 0);
  return Math.round((total / values.length) * 100) / 100;
}

function isoDateDaysAgo(days: number): string {
  const now = new Date();
  now.setUTCDate(now.getUTCDate() - days);
  return now.toISOString().slice(0, 10);
}

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
    const auth = await requireAuthenticatedUser(req, supabase, {
      adminAllowlist: env.ADMIN_ALLOWLIST_EMAILS,
    });

    if (!auth.isAdmin) {
      return json({ error: 'Forbidden' }, 403);
    }

    const [{ count: totalProfiles, error: profilesCountError }, { data: connections, error: connectionsError }] =
      await Promise.all([
        supabase.from('profiles').select('user_id', { head: true, count: 'exact' }),
        supabase.from('terra_connections').select('user_id,status,last_sync_at,updated_at'),
      ]);

    if (profilesCountError) {
      throw new Error(`Failed to count profiles: ${profilesCountError.message}`);
    }
    if (connectionsError) {
      throw new Error(`Failed to load connection metrics: ${connectionsError.message}`);
    }

    const connectionRows = connections ?? [];
    const nowTs = Date.now();
    const twentyFourHoursMs = 24 * 60 * 60 * 1000;

    const statusCounts = {
      connected: connectionRows.filter((row) => row.status === 'connected').length,
      pending: connectionRows.filter((row) => row.status === 'pending').length,
      error: connectionRows.filter((row) => row.status === 'error').length,
      disconnected: connectionRows.filter((row) => row.status === 'disconnected').length,
    };

    const staleSyncCount = connectionRows.filter((row) => {
      if (row.status !== 'connected') {
        return false;
      }
      if (!row.last_sync_at) {
        return true;
      }
      return nowTs - new Date(row.last_sync_at).valueOf() > twentyFourHoursMs;
    }).length;

    const sevenDaysAgo = isoDateDaysAgo(6);
    const { data: biometrics, error: biometricsError } = await supabase
      .from('biometrics_daily')
      .select('date,steps,sleep_minutes,active_minutes,hrv,rhr')
      .gte('date', sevenDaysAgo);

    if (biometricsError) {
      throw new Error(`Failed to fetch biometric aggregates: ${biometricsError.message}`);
    }

    const rows = biometrics ?? [];
    const avgSteps = average(
      rows.map((row) => row.steps).filter((value): value is number => typeof value === 'number'),
    );
    const avgSleepMinutes = average(
      rows.map((row) => row.sleep_minutes).filter((value): value is number => typeof value === 'number'),
    );
    const avgActiveMinutes = average(
      rows.map((row) => row.active_minutes).filter((value): value is number => typeof value === 'number'),
    );

    const issueRows = connectionRows
      .filter((row) => row.status === 'error' || row.status === 'pending')
      .slice(0, 50);
    const issueUserIds = [...new Set(issueRows.map((row) => row.user_id))];

    let profileByUserId = new Map<string, { name: string; trial_cohort: string }>();
    if (issueUserIds.length > 0) {
      const { data: issueProfiles, error: issueProfilesError } = await supabase
        .from('profiles')
        .select('user_id,name,trial_cohort')
        .in('user_id', issueUserIds);

      if (issueProfilesError) {
        throw new Error(`Failed to load issue profile details: ${issueProfilesError.message}`);
      }

      profileByUserId = new Map(
        (issueProfiles ?? []).map((profile) => [
          profile.user_id,
          {
            name: profile.name,
            trial_cohort: profile.trial_cohort,
          },
        ]),
      );
    }

    const issues = issueRows.map((row) => ({
      user_id: row.user_id,
      name: profileByUserId.get(row.user_id)?.name ?? 'Unknown',
      trial_cohort: profileByUserId.get(row.user_id)?.trial_cohort ?? 'unknown',
      status: row.status,
      last_sync_at: row.last_sync_at,
      updated_at: row.updated_at,
    }));

    await supabase.from('events_audit').insert({
      user_id: auth.user.id,
      event_type: 'admin.metrics.viewed',
      payload: {
        request_id: requestId,
        profile_count: totalProfiles ?? 0,
      },
    });

    const responseBody = {
      generated_at: new Date().toISOString(),
      profile_count: totalProfiles ?? 0,
      connection_counts: statusCounts,
      stale_sync_count_24h: staleSyncCount,
      seven_day_averages: {
        steps: avgSteps,
        sleep_minutes: avgSleepMinutes,
        active_minutes: avgActiveMinutes,
      },
      open_issues: issues,
    };

    logInfo('Admin metrics requested', {
      requestId,
      adminUserId: auth.user.id,
      profileCount: totalProfiles ?? 0,
    });

    return json(responseBody);
  } catch (error) {
    if (error instanceof AuthError) {
      return json({ error: error.message }, error.status);
    }

    const message = error instanceof Error ? error.message : 'Unknown error';
    logError('Admin metrics function failed', { requestId, error: message });
    return json({ error: message, request_id: requestId }, 500);
  }
});
