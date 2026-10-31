import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err, readJson } from '@/lib/http';

// Store this device's APNs token so a supporter's phone can be reached when a
// request arrives (SP3), and the person's phone when it matters.
export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { token } = await readJson<{ token: string }>(req);
  if (!token || !/^[0-9a-f]{32,200}$/i.test(token)) return err('token required');

  await db().from('users').update({ apns_token: token }).eq('id', user.id);
  return ok();
}
