import { db } from './supabase';
import { sendPush } from './apns';

// Phase 7: an approval request opens by itself 3 days after it was made unless
// the partner approved it first. “Not yet” (denied) only delays; it can't hold
// the lock forever. The partner is told when it opens.
export const RELEASE_AFTER_MS = Number(process.env.APPROVAL_RELEASE_HOURS ?? 72) * 60 * 60 * 1000;

/** Requests still open (pending, or answered “not yet”) for this user. */
export const OPEN_STATUSES = ['pending', 'denied'];

/**
 * Release requests older than the 3-day window. Scoped to one user when
 * `userId` is given (on poll), otherwise everyone (the worker's sweep).
 * Returns how many were released.
 */
export async function releaseStaleApprovals(userId?: string): Promise<number> {
  const supabase = db();
  const cutoff = new Date(Date.now() - RELEASE_AFTER_MS).toISOString();
  let query = supabase
    .from('approval_requests')
    .update({ status: 'approved', auto_released: true, responded_at: new Date().toISOString() })
    .in('status', OPEN_STATUSES)
    .lt('created_at', cutoff);
  if (userId) query = query.eq('user_id', userId);
  const { data: released } = await query.select('id, partner_id, user_id');

  // Tell each partner, once per request. Discreet: nothing says what Bedrock is for.
  for (const row of released ?? []) {
    const { data: partner } = await supabase.from('users').select('apns_token').eq('id', row.partner_id).maybeSingle();
    const { data: requester } = await supabase.from('users').select('display_name').eq('id', row.user_id).maybeSingle();
    const name = requester?.display_name?.trim() || 'Your person';
    if (partner?.apns_token) {
      await sendPush(partner.apns_token, 'A request opened', `${name}'s request opened after 3 days without an answer.`).catch(() => {});
    }
  }
  return released?.length ?? 0;
}
