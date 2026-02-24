import { assertEquals } from '@std/assert';
import { normalizeTerraWebhookPayload } from '../_shared/terraPayload.ts';

Deno.test('normalizeTerraWebhookPayload maps daily metrics', () => {
  const payload = {
    id: 'evt_test_001',
    type: 'daily_summary',
    user: { user_id: 'terra_user_123' },
    timestamp: '2026-02-24T07:30:00.000Z',
    data: [
      {
        date: '2026-02-23',
        steps: 9000,
        sleep_duration_seconds: 28800,
        hrv: 44.2,
        resting_heart_rate: 54,
        active_calories: 520,
        active_duration_minutes: 42,
      },
    ],
  };

  const normalized = normalizeTerraWebhookPayload(payload);
  assertEquals(normalized.eventId, 'evt_test_001');
  assertEquals(normalized.eventType, 'daily_summary');
  assertEquals(normalized.terraUserId, 'terra_user_123');
  assertEquals(normalized.metrics.length, 1);
  assertEquals(normalized.metrics[0].date, '2026-02-23');
  assertEquals(normalized.metrics[0].steps, 9000);
  assertEquals(normalized.metrics[0].sleepMinutes, 480);
  assertEquals(normalized.metrics[0].rhr, 54);
});
