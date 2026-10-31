import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err } from '@/lib/http';
import { releaseStaleApprovals } from '@/lib/approvals';

// The requesting user polls a set of request ids; the gauntlet releases when ANY
// partner approves, or 3 days after the ask without an approval. (Production also receives this via Realtime / push.)
export async function GET(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const ids = new URL(req.url).searchParams.get('ids')?.split(',').filter(Boolean) ?? [];
  if (ids.length === 0) return err('ids required');

  // Phase 7: past 3 days without approval, the request opens and the partner is told.
  await releaseStaleApprovals(user.id);

  const { data } = await db()
    .from('approval_requests')
    .select('id, status, auto_released')
    .in('id', ids)
    .eq('user_id', user.id);

  const statuses = data ?? [];
  const approved = statuses.some((s) => s.status === 'approved');
  const denied = statuses.length > 0 && statuses.every((s) => s.status === 'denied');
  const autoReleased = statuses.some((s) => s.status === 'approved' && s.auto_released);
  return ok({ approved, denied, autoReleased, statuses });
}
