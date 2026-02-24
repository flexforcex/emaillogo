export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
};

export function getRequestId(req: Request): string {
  return req.headers.get('x-request-id') ?? crypto.randomUUID();
}

export function json(
  body: Record<string, unknown>,
  status = 200,
  headers: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
      ...headers,
    },
  });
}

export function methodNotAllowed(allowed: string[]): Response {
  return json(
    { error: `Method not allowed. Expected one of: ${allowed.join(', ')}` },
    405,
    { Allow: allowed.join(', ') },
  );
}

export function preflight(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  return null;
}
