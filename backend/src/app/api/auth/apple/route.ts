import { authenticate } from '@/lib/auth';
import { db } from '@/lib/supabase';
import { ok, err, readJson } from '@/lib/http';
import { createRemoteJWKSet, jwtVerify } from 'jose';

// Sign in with Apple link (§3). Verifies the Apple identity token and attaches
// the Apple identity to this device's user. The app also calls RevenueCat
// `logIn(appleUserID)`, so we store rc_app_user_id = the Apple sub to keep the
// entitlement webhook mapping correct.
export const dynamic = 'force-dynamic';

const APPLE_JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));

export async function POST(req: Request) {
  const user = await authenticate(req);
  if (!user) return err('unauthorized', 401);

  const { identityToken, displayName } = await readJson<{ identityToken: string; displayName?: string }>(req);
  if (!identityToken) return err('identityToken required');

  let sub: string;
  let email: string | undefined;
  try {
    const { payload } = await jwtVerify(identityToken, APPLE_JWKS, {
      issuer: 'https://appleid.apple.com',
      audience: process.env.APPLE_BUNDLE_ID ?? 'com.thebedrock.app',
    });
    sub = String(payload.sub);
    email = typeof payload.email === 'string' ? payload.email : undefined;
  } catch {
    return err('invalid identity token', 401);
  }

  const patch: Record<string, unknown> = { apple_sub: sub, rc_app_user_id: sub };
  if (email) patch.email = email;
  if (displayName && displayName.trim()) patch.display_name = displayName.trim();

  const { error } = await db().from('users').update(patch).eq('id', user.id);
  if (error) return err(error.message, 500);
  return ok({ appleSub: sub });
}
