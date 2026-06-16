import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err } from '@/lib/http';

// Returns both sides of this user's accountability:
//  - partners: who supports me
//  - supporting: who I support, with their live protection status (partner view)
export async function GET(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const supabase = db();

  const { data: partnerRows } = await supabase
    .from('partner_links')
    .select('partner_id, kind, users:partner_id (display_name)')
    .eq('supported_id', user.id)
    .eq('status', 'active');

  const { data: supportingRows } = await supabase
    .from('partner_links')
    .select('supported_id, kind, users:supported_id (display_name, protection_active, strict_enabled, last_heartbeat_at)')
    .eq('partner_id', user.id)
    .eq('status', 'active');

  const partners = (partnerRows ?? []).map((r) => {
    const u = r.users as { display_name?: string } | null;
    return { id: r.partner_id, kind: r.kind, name: u?.display_name ?? null };
  });

  const supporting = (supportingRows ?? []).map((r) => {
    const u = r.users as {
      display_name?: string;
      protection_active?: boolean;
      strict_enabled?: boolean;
      last_heartbeat_at?: string;
    } | null;
    return {
      id: r.supported_id,
      kind: r.kind,
      name: u?.display_name ?? null,
      protectionActive: u?.protection_active ?? false,
      strictEnabled: u?.strict_enabled ?? false,
      lastHeartbeatAt: u?.last_heartbeat_at ?? null,
    };
  });

  return ok({ partners, supporting });
}
