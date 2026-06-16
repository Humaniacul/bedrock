import { Queue } from 'bullmq';

// BullMQ on Upstash Redis (§3). We hand BullMQ plain connection options (parsed
// from REDIS_URL) and let it manage its own ioredis client — avoids version-skew
// between our deps and BullMQ's bundled ioredis, and is the recommended pattern.

export const HEARTBEAT_SWEEP = 'heartbeat-sweep';

export function redisConnection() {
  const url = process.env.REDIS_URL;
  if (!url) throw new Error('REDIS_URL not configured');
  const u = new URL(url);
  return {
    host: u.hostname,
    port: Number(u.port || 6379),
    username: u.username || undefined,
    password: u.password || undefined,
    tls: u.protocol === 'rediss:' ? {} : undefined,
    maxRetriesPerRequest: null, // required by BullMQ
  };
}

let sweepQueue: Queue | null = null;
export function heartbeatSweepQueue(): Queue {
  if (!sweepQueue) sweepQueue = new Queue(HEARTBEAT_SWEEP, { connection: redisConnection() });
  return sweepQueue;
}
