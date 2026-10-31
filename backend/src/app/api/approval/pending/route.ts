import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err } from '@/lib/http';
import { OPEN_STATUSES } from '@/lib/approvals';

// Requests awaiting THIS user's decision (partner-side inbox), including ones
// answered “Not yet”, which can still be approved before they open.
export async function GET(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { data } = await db()
    .from('approval_requests')
    .select('id, reason, created_at, users:user_id (display_name)')
    .eq('partner_id', user.id)
    .in('status', OPEN_STATUSES) // “Not yet” stays answerable until it opens
    .order('created_at', { ascending: false });

  const pending = (data ?? []).map((r) => {
    const u = r.users as { display_name?: string } | null;
    return { id: r.id, reason: r.reason, createdAt: r.created_at, name: u?.display_name ?? null };
  });

  return ok({ pending });
}
