import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err } from '@/lib/http';

// Authoritative remaining time for a cooldown, computed from server clock.
export async function GET(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const id = new URL(req.url).searchParams.get('id');
  if (!id) return err('id required');

  const { data } = await db()
    .from('cooldowns')
    .select('started_at, duration_seconds')
    .eq('id', id)
    .eq('user_id', user.id)
    .maybeSingle();
  if (!data) return err('not found', 404);

  const elapsedMs = Date.now() - new Date(data.started_at).getTime();
  const remainingMs = Math.max(0, data.duration_seconds * 1000 - elapsedMs);
  return ok({ remainingMs, complete: remainingMs === 0 });
}
