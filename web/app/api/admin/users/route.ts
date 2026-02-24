import { NextResponse } from 'next/server';
import { getSupabaseAdminClient, requireAdminFromRequest } from '@/lib/admin-auth';

export const runtime = 'nodejs';

type TrialUserRow = {
  user_id: string;
  name: string;
  trial_cohort: string;
  connection_status: string;
  last_sync_at: string | null;
};

export async function GET(request: Request) {
  try {
    await requireAdminFromRequest(request);
    const supabase = getSupabaseAdminClient();

    const [{ data: profiles, error: profilesError }, { data: connections, error: connectionsError }] =
      await Promise.all([
        supabase
          .from('profiles')
          .select('user_id,name,trial_cohort')
          .order('created_at', { ascending: true }),
        supabase
          .from('terra_connections')
          .select('user_id,status,last_sync_at')
          .eq('provider', 'apple_health'),
      ]);

    if (profilesError) {
      throw new Error(`Failed to load profiles: ${profilesError.message}`);
    }
    if (connectionsError) {
      throw new Error(`Failed to load connection states: ${connectionsError.message}`);
    }

    const connectionByUser = new Map(
      (connections ?? []).map((connection) => [connection.user_id, connection]),
    );

    const rows: TrialUserRow[] = (profiles ?? []).map((profile) => {
      const connection = connectionByUser.get(profile.user_id);
      return {
        user_id: profile.user_id,
        name: profile.name || 'Unknown',
        trial_cohort: profile.trial_cohort,
        connection_status: connection?.status ?? 'disconnected',
        last_sync_at: connection?.last_sync_at ?? null,
      };
    });

    return NextResponse.json({ rows });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unauthorized';
    const status = message === 'Forbidden' ? 403 : 401;
    return NextResponse.json({ error: message }, { status });
  }
}
