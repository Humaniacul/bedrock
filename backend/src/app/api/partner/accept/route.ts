import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err, readJson } from '@/lib/http';

// Accept an invite: the accepting user becomes the partner of the inviter.
// For 'peer' invites the link is mutual (two-key, §4 P1).
export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { code } = await readJson<{ code: string }>(req);
  if (!code) return err('code required');

  const supabase = db();
  const { data: invite } = await supabase
    .from('invites')
    .select('id, created_by, kind, accepted_by, expires_at')
    .eq('code', code.toUpperCase())
    .maybeSingle();

  if (!invite) return err('invalid code', 404);
  if (invite.accepted_by) return err('already used', 409);
  if (new Date(invite.expires_at) < new Date()) return err('expired', 410);
  if (invite.created_by === user.id) return err('cannot accept your own invite');

  await supabase.from('invites').update({ accepted_by: user.id, accepted_at: new Date().toISOString() }).eq('id', invite.id);

  // Inviter is supported by the accepting partner.
  await supabase.from('partner_links').upsert(
    { supported_id: invite.created_by, partner_id: user.id, kind: invite.kind, status: 'active' },
    { onConflict: 'supported_id,partner_id' },
  );
  if (invite.kind === 'peer') {
    await supabase.from('partner_links').upsert(
      { supported_id: user.id, partner_id: invite.created_by, kind: 'peer', status: 'active' },
      { onConflict: 'supported_id,partner_id' },
    );
  }

  return ok({ supportedUserId: invite.created_by, kind: invite.kind });
}
