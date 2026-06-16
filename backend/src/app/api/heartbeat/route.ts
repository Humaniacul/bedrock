import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err, readJson } from '@/lib/http';

// Device heartbeat: keeps the partner's view current and feeds the
// missed-heartbeat sweep (app gone dark → supportive alert).
export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { protectionActive, strictEnabled } = await readJson<{
    protectionActive: boolean;
    strictEnabled: boolean;
  }>(req);

  await db()
    .from('users')
    .update({
      protection_active: !!protectionActive,
      strict_enabled: !!strictEnabled,
      last_heartbeat_at: new Date().toISOString(),
    })
    .eq('id', user.id);

  return ok();
}
