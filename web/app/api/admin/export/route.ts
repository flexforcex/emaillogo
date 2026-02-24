import { NextResponse } from 'next/server';
import { getSupabaseAdminClient, requireAdminFromRequest } from '@/lib/admin-auth';

export const runtime = 'nodejs';

function escapeCSV(value: unknown): string {
  if (value === null || value === undefined) return '';
  const raw = String(value);
  if (raw.includes(',') || raw.includes('"') || raw.includes('\n')) {
    return `"${raw.replaceAll('"', '""')}"`;
  }
  return raw;
}

export async function GET(request: Request) {
  try {
    await requireAdminFromRequest(request);
    const supabase = getSupabaseAdminClient();

    const { data, error } = await supabase
      .from('biometrics_daily')
      .select('user_id,date,steps,sleep_minutes,hrv,rhr,calories,active_minutes,updated_at')
      .order('user_id', { ascending: true })
      .order('date', { ascending: false });

    if (error) {
      throw new Error(`Failed to export biometrics: ${error.message}`);
    }

    const headers = [
      'user_id',
      'date',
      'steps',
      'sleep_minutes',
      'hrv',
      'rhr',
      'calories',
      'active_minutes',
      'updated_at',
    ];
    const rows = (data ?? []).map((row) =>
      headers.map((header) => escapeCSV((row as Record<string, unknown>)[header])).join(',')
    );
    const csv = [headers.join(','), ...rows].join('\n');

    return new NextResponse(csv, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': 'attachment; filename="biometrics_daily.csv"',
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unauthorized';
    const status = message === 'Forbidden' ? 403 : 401;
    return NextResponse.json({ error: message }, { status });
  }
}
