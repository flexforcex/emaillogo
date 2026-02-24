#!/usr/bin/env node
import { createHmac } from 'node:crypto';
import { readFile } from 'node:fs/promises';

function getArg(flag, fallback = null) {
  const index = process.argv.indexOf(flag);
  if (index === -1 || index === process.argv.length - 1) {
    return fallback;
  }
  return process.argv[index + 1];
}

async function main() {
  const url = getArg('--url', 'http://127.0.0.1:54321/functions/v1/terra-webhook');
  const secret = getArg('--secret', process.env.TERRA_WEBHOOK_SECRET);
  const payloadPath = getArg(
    '--payload',
    'supabase/functions/tests/fixtures/terra-webhook-sample.json',
  );

  if (!secret) {
    console.error('Missing webhook secret. Provide --secret or TERRA_WEBHOOK_SECRET.');
    process.exit(1);
  }

  const payloadRaw = await readFile(payloadPath, 'utf8');
  const signature = createHmac('sha256', secret).update(payloadRaw).digest('hex');

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'terra-signature': signature,
      'x-request-id': `replay-${Date.now()}`,
    },
    body: payloadRaw,
  });

  const text = await response.text();
  console.log(`Status: ${response.status}`);
  console.log(text);
}

main().catch((error) => {
  console.error('Webhook replay failed:', error);
  process.exit(1);
});
