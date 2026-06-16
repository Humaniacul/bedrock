import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { sendPush } from '@/lib/apns';
import { ok, err, readJson } from '@/lib/http';

const KINDS = ['shield_cleared', 'screen_time_off', 'app_dark', 'uninstall_lock_off'];

// A protection layer dropped. Record it and fan out a SUPPORTIVE alert to
// partners — never "caught" (§4).
export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { kind } = await readJson<{ kind: string }>(req);
  if (!kind || !KINDS.includes(kind)) return err('invalid kind');

  const supabase = db();
  await supabase.from('tamper_events').insert({ user_id: user.id, kind });

  const { data: me } = await supabase.from('users').select('display_name').eq('id', user.id).maybeSingle();
  const name = me?.display_name?.trim() || 'your person';

  const { data: links } = await supabase
    .from('partner_links')
    .select('partner_id')
    .eq('supported_id', user.id)
    .eq('status', 'active');

  for (const link of links ?? []) {
    const { data: partner } = await supabase
      .from('users')
      .select('apns_token')
      .eq('id', link.partner_id)
      .maybeSingle();
    if (partner?.apns_token) {
      await sendPush(partner.apns_token, 'A good moment to reach out', `Now's a good time to check in with ${name}.`).catch(() => {});
    }
  }

  return ok();
}
