import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { sendPush } from '@/lib/apns';
import { ok, err, readJson } from '@/lib/http';
import { OPEN_STATUSES, RELEASE_AFTER_MS } from '@/lib/approvals';

// Gauntlet step 6: ask the partner(s) to approve a disable. Creates one pending
// request per active partner and notifies them (or rejoins the open request).
export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { reason } = await readJson<{ reason: string }>(req);

  const supabase = db();
  const { data: links } = await supabase
    .from('partner_links')
    .select('partner_id')
    .eq('supported_id', user.id)
    .eq('status', 'active');

  if (!links || links.length === 0) return err('no partner to approve', 409);

  // One request at a time: asking again joins the open one, so the 3-day
  // window runs from the first ask and can't be restarted by retrying.
  const windowStart = new Date(Date.now() - RELEASE_AFTER_MS).toISOString();
  const { data: open } = await supabase
    .from('approval_requests')
    .select('id')
    .eq('user_id', user.id)
    .in('status', OPEN_STATUSES)
    .gte('created_at', windowStart);
  if (open && open.length > 0) return ok({ requestIds: open.map((r) => r.id) });

  const { data: me } = await supabase.from('users').select('display_name').eq('id', user.id).maybeSingle();
  const name = me?.display_name?.trim() || 'Your person';

  const rows = links.map((l) => ({ user_id: user.id, partner_id: l.partner_id, reason: reason ?? null }));
  const { data: inserted, error } = await supabase.from('approval_requests').insert(rows).select('id');
  if (error) return err(error.message, 500);

  for (const l of links) {
    const { data: partner } = await supabase.from('users').select('apns_token').eq('id', l.partner_id).maybeSingle();
    if (partner?.apns_token) {
      // Discreet: nothing on a notification says what Bedrock is for.
      await sendPush(partner.apns_token, 'A request', `${name} sent you a request. If you don't answer, it opens in 3 days.`).catch(() => {});
    }
  }

  // The client polls these ids (or listens via Realtime) for the decision.
  return ok({ requestIds: (inserted ?? []).map((r) => r.id) });
}
