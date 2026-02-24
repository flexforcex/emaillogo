import { NextResponse } from 'next/server';
import { getSupabasePublicConfig, requireAdminFromRequest } from '@/lib/admin-auth';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const admin = await requireAdminFromRequest(request);
    const { url, anonKey } = getSupabasePublicConfig();

    const response = await fetch(`${url}/functions/v1/admin-metrics`, {
      headers: {
        Authorization: `Bearer ${admin.accessToken}`,
        apikey: anonKey,
        'Content-Type': 'application/json',
      },
      method: 'GET',
      cache: 'no-store',
    });

    const responseText = await response.text();
    if (!response.ok) {
      return new NextResponse(responseText, { status: response.status });
    }

    return new NextResponse(responseText, {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unauthorized';
    const status = message === 'Forbidden' ? 403 : 401;
    return NextResponse.json({ error: message }, { status });
  }
}
