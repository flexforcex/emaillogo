function normalizeSignature(value: string): string {
  return value.trim().replace(/^sha256=/i, '');
}

function toHex(bytes: Uint8Array): string {
  return [...bytes].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function toBase64(bytes: Uint8Array): string {
  const binary = String.fromCharCode(...bytes);
  return btoa(binary);
}

function toBase64Url(base64: string): string {
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const aBytes = enc.encode(a);
  const bBytes = enc.encode(b);
  const max = Math.max(aBytes.length, bBytes.length);

  let result = aBytes.length === bBytes.length ? 0 : 1;
  for (let i = 0; i < max; i += 1) {
    const av = i < aBytes.length ? aBytes[i] : 0;
    const bv = i < bBytes.length ? bBytes[i] : 0;
    result |= av ^ bv;
  }
  return result === 0;
}

async function hmacSha256(secret: string, payload: string): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(payload));
  return new Uint8Array(signature);
}

function extractHeaderSignatures(headers: Headers): string[] {
  const candidates = [
    headers.get('terra-signature'),
    headers.get('x-terra-signature'),
    headers.get('x-signature'),
    headers.get('signature'),
  ].filter((value): value is string => !!value);

  return candidates
    .flatMap((value) => value.split(','))
    .map((value) => normalizeSignature(value))
    .filter(Boolean);
}

export interface SignatureVerificationResult {
  isValid: boolean;
  signatures: string[];
  computedHex: string;
  computedBase64: string;
}

export async function verifyTerraSignature(
  rawBody: string,
  headers: Headers,
  secret: string,
): Promise<SignatureVerificationResult> {
  const signatures = extractHeaderSignatures(headers);
  if (signatures.length === 0) {
    return {
      isValid: false,
      signatures,
      computedHex: '',
      computedBase64: '',
    };
  }

  const digest = await hmacSha256(secret, rawBody);
  const computedHex = toHex(digest);
  const computedBase64 = toBase64(digest);
  const computedBase64Url = toBase64Url(computedBase64);

  const isValid = signatures.some((candidate) =>
    timingSafeEqual(candidate.toLowerCase(), computedHex.toLowerCase()) ||
    timingSafeEqual(candidate, computedBase64) ||
    timingSafeEqual(candidate, computedBase64Url)
  );

  return {
    isValid,
    signatures,
    computedHex,
    computedBase64,
  };
}
