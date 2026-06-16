import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { sendPush } from '@/lib/apns';
import { ok, err, readJson } from '@/lib/http';

// Gauntlet step 6: ask the partner(s) to approve a disable. Creates one pending
// request per active partner and notifies them.
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

  const { data: me } = await supabase.from('users').select('display_name').eq('id', user.id).maybeSingle();
  const name = me?.display_name?.trim() || 'Your person';

  const rows = links.map((l) => ({ user_id: user.id, partner_id: l.partner_id, reason: reason ?? null }));
  const { data: inserted, error } = await supabase.from('approval_requests').insert(rows).select('id');
  if (error) return err(error.message, 500);

  for (const l of links) {
    const { data: partner } = await supabase.from('users').select('apns_token').eq('id', l.partner_id).maybeSingle();
    if (partner?.apns_token) {
      await sendPush(partner.apns_token, 'Approval needed', `${name} is asking to turn off protection.`).catch(() => {});
    }
  }

  // The client polls these ids (or listens via Realtime) for the decision.
  return ok({ requestIds: (inserted ?? []).map((r) => r.id) });
}
