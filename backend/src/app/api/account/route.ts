import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err } from '@/lib/http';

// Account & data deletion (App Store Guideline 5.1.1(v)). Deletes the caller's
// user row; foreign keys cascade (partner_links, invites.created_by,
// tamper_events, approval_requests, cooldowns). invites.accepted_by → null.
export const dynamic = 'force-dynamic';

export async function DELETE(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { error } = await db().from('users').delete().eq('id', user.id);
  if (error) return err(error.message, 500);
  return ok({ deleted: true });
}
