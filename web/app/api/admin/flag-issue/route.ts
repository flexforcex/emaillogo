import { NextResponse } from 'next/server';
import { getSupabaseAdminClient, requireAdminFromRequest } from '@/lib/admin-auth';

export const runtime = 'nodejs';

export async function POST(request: Request) {
  try {
    const admin = await requireAdminFromRequest(request);
    const body = await request.json();
    const userId = typeof body.user_id === 'string' ? body.user_id : '';
    const note = typeof body.note === 'string' ? body.note.trim() : '';

    if (!userId || !note) {
      return NextResponse.json({ error: 'user_id and note are required' }, { status: 400 });
    }

    const supabase = getSupabaseAdminClient();
    const { error } = await supabase.from('events_audit').insert({
      user_id: userId,
      event_type: 'admin.issue.flagged',
      payload: {
        note,
        flagged_by: admin.userId,
        flagged_by_email: admin.email,
        flagged_at: new Date().toISOString(),
      },
    });

    if (error) {
      throw new Error(`Failed to flag issue: ${error.message}`);
    }

    return NextResponse.json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unauthorized';
    const status = message === 'Forbidden' ? 403 : 401;
    return NextResponse.json({ error: message }, { status });
  }
}
