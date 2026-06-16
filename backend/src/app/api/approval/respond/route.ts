import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err, readJson } from '@/lib/http';

// The partner approves or denies a pending request.
export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { id, decision } = await readJson<{ id: string; decision: 'approved' | 'denied' }>(req);
  if (!id || (decision !== 'approved' && decision !== 'denied')) return err('id and decision required');

  const supabase = db();
  const { data, error } = await supabase
    .from('approval_requests')
    .update({ status: decision, responded_at: new Date().toISOString() })
    .eq('id', id)
    .eq('partner_id', user.id) // only the assigned partner may respond
    .eq('status', 'pending')
    .select('id')
    .maybeSingle();

  if (error) return err(error.message, 500);
  if (!data) return err('not found or already answered', 404);
  return ok();
}
