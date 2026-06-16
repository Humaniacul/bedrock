import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err, readJson } from '@/lib/http';

// Generate a short, human-shareable invite code (§4: invite a partner).
function code(): string {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
  return Array.from({ length: 6 }, () => alphabet[Math.floor(Math.random() * alphabet.length)]).join('');
}

export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { kind } = await readJson<{ kind: 'partner' | 'peer' }>(req);
  const inviteKind = kind === 'peer' ? 'peer' : 'partner';

  const supabase = db();
  // Retry a couple of times on the unlikely code collision.
  for (let attempt = 0; attempt < 5; attempt++) {
    const c = code();
    const { error } = await supabase.from('invites').insert({ code: c, created_by: user.id, kind: inviteKind });
    if (!error) {
      const base = process.env.PUBLIC_INVITE_BASE_URL ?? 'https://thebedrock.app/join';
      return ok({ code: c, url: `${base}/${c}` });
    }
  }
  return err('could not create invite', 500);
}
