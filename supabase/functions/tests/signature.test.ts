import { assertEquals } from '@std/assert';
import { verifyTerraSignature } from '../_shared/signature.ts';

async function hmacHex(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const digest = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

Deno.test('verifyTerraSignature validates hex signature', async () => {
  const secret = 'test_secret';
  const body = JSON.stringify({ hello: 'world' });
  const signature = await hmacHex(secret, body);
  const headers = new Headers({ 'terra-signature': signature });

  const result = await verifyTerraSignature(body, headers, secret);
  assertEquals(result.isValid, true);
});

Deno.test('verifyTerraSignature rejects invalid signature', async () => {
  const secret = 'test_secret';
  const body = JSON.stringify({ hello: 'world' });
  const headers = new Headers({ 'terra-signature': 'abc123' });

  const result = await verifyTerraSignature(body, headers, secret);
  assertEquals(result.isValid, false);
});
