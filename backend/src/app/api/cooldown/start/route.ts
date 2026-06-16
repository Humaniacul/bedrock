import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err, readJson } from '@/lib/http';

// Start a server-validated cooldown (§10.5). The server owns `started_at`, so
// the device can't fake elapsed time by changing its clock.
export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { seconds } = await readJson<{ seconds: number }>(req);
  const duration = Math.max(1, Math.min(Number(seconds) || 0, 24 * 60 * 60));

  const { data, error } = await db()
    .from('cooldowns')
    .insert({ user_id: user.id, duration_seconds: duration })
    .select('id, started_at, duration_seconds')
    .single();
  if (error) return err(error.message, 500);

  return ok({
    id: data.id,
    startedAtMs: new Date(data.started_at).getTime(),
    durationSeconds: data.duration_seconds,
    nowMs: Date.now(),
  });
}
