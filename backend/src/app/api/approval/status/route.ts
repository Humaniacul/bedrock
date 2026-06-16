import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err } from '@/lib/http';

// The requesting user polls a set of request ids; the gauntlet releases when ANY
// partner approves. (Production also receives this via Realtime / push.)
export async function GET(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const ids = new URL(req.url).searchParams.get('ids')?.split(',').filter(Boolean) ?? [];
  if (ids.length === 0) return err('ids required');

  const { data } = await db()
    .from('approval_requests')
    .select('id, status')
    .in('id', ids)
    .eq('user_id', user.id);

  const statuses = data ?? [];
  const approved = statuses.some((s) => s.status === 'approved');
  const denied = statuses.length > 0 && statuses.every((s) => s.status === 'denied');
  return ok({ approved, denied, statuses });
}
