import { db } from '@/lib/supabase';
import { ok, err } from '@/lib/http';

// RevenueCat webhook → Supabase entitlement sync (§3, §8). RevenueCat sends the
// Authorization header you configure in its dashboard; we verify it against
// REVENUECAT_WEBHOOK_AUTH. The app sets RevenueCat `app_user_id` to the device
// id, so we reconcile by matching `users.device_id`.
export const dynamic = 'force-dynamic';

// Event types that clearly END entitlement.
const INACTIVE = new Set(['EXPIRATION', 'SUBSCRIPTION_PAUSED']);
// Lifetime / consumable — active with no expiry.
const NON_RENEWING = 'NON_RENEWING_PURCHASE';

interface RCEvent {
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  product_id?: string;
  expiration_at_ms?: number | null;
}

export async function POST(req: Request) {
  const expected = process.env.REVENUECAT_WEBHOOK_AUTH;
  if (!expected) return err('webhook not configured', 500);
  if (req.headers.get('authorization') !== expected) return err('unauthorized', 401);

  const body = (await req.json().catch(() => ({}))) as { event?: RCEvent };
  const event = body.event;
  if (!event?.type) return err('missing event');

  // Test pings from the dashboard carry no user — just acknowledge.
  if (event.type === 'TEST') return ok({ test: true });

  const appUserId = event.app_user_id || event.original_app_user_id;
  if (!appUserId) return err('missing app_user_id');

  const expMs = event.expiration_at_ms ?? null;
  const expiresAt = expMs ? new Date(expMs).toISOString() : null;

  let isPremium: boolean;
  if (INACTIVE.has(event.type)) {
    isPremium = false;
  } else if (event.type === NON_RENEWING) {
    isPremium = true; // lifetime
  } else if (expMs != null) {
    isPremium = expMs > Date.now(); // CANCELLATION/BILLING_ISSUE stay active until expiry
  } else {
    isPremium = true;
  }

  // No-op if the user hasn't registered yet — RevenueCat retries, and the next
  // event will land once they have.
  await db()
    .from('users')
    .update({
      is_premium: isPremium,
      premium_expires_at: expiresAt,
      rc_app_user_id: appUserId,
      rc_updated_at: new Date().toISOString(),
    })
    .eq('device_id', appUserId);

  return ok();
}
