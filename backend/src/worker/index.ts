import { Worker, Queue } from 'bullmq';
import { redisConnection, HEARTBEAT_SWEEP } from '../lib/queue';
import { db } from '../lib/supabase';
import { sendPush } from '../lib/apns';

// Railway worker service (§3). Runs the missed-heartbeat sweep on a schedule:
// if a user who should be protected has gone quiet (app deleted / Screen Time
// off / phone dark), we raise an `app_dark` tamper event and alert the partner
// — supportively.

const STALE_MINUTES = Number(process.env.HEARTBEAT_STALE_MINUTES ?? 45);
const SWEEP_EVERY_MS = Number(process.env.SWEEP_INTERVAL_MS ?? 15 * 60 * 1000);

async function runSweep(): Promise<void> {
  const supabase = db();
  const cutoff = new Date(Date.now() - STALE_MINUTES * 60 * 1000).toISOString();

  // Users who should be protected but haven't checked in since the cutoff.
  const { data: stale } = await supabase
    .from('users')
    .select('id, display_name, last_heartbeat_at')
    .or('protection_active.eq.true,strict_enabled.eq.true')
    .lt('last_heartbeat_at', cutoff);

  for (const user of stale ?? []) {
    // Don't spam: skip if we already raised app_dark since the last heartbeat.
    const { data: recent } = await supabase
      .from('tamper_events')
      .select('id')
      .eq('user_id', user.id)
      .eq('kind', 'app_dark')
      .gt('created_at', user.last_heartbeat_at ?? cutoff)
      .limit(1);
    if (recent && recent.length > 0) continue;

    await supabase.from('tamper_events').insert({ user_id: user.id, kind: 'app_dark' });

    const name = user.display_name?.trim() || 'your person';
    const { data: links } = await supabase
      .from('partner_links')
      .select('partner_id')
      .eq('supported_id', user.id)
      .eq('status', 'active');
    for (const link of links ?? []) {
      const { data: partner } = await supabase.from('users').select('apns_token').eq('id', link.partner_id).maybeSingle();
      if (partner?.apns_token) {
        await sendPush(partner.apns_token, 'A good moment to reach out', `You haven't heard from ${name} in a while.`).catch(() => {});
      }
    }
  }
}

async function main() {
  // Process sweep jobs.
  new Worker(HEARTBEAT_SWEEP, async () => runSweep(), { connection: redisConnection() });

  // Schedule a repeatable sweep (idempotent — BullMQ dedupes by repeat key).
  const queue = new Queue(HEARTBEAT_SWEEP, { connection: redisConnection() });
  await queue.add('sweep', {}, { repeat: { every: SWEEP_EVERY_MS }, removeOnComplete: true, removeOnFail: 100 });

  console.log(`[worker] heartbeat sweep every ${SWEEP_EVERY_MS / 1000}s, stale after ${STALE_MINUTES}m`);
}

main().catch((e) => {
  console.error('[worker] fatal', e);
  process.exit(1);
});
