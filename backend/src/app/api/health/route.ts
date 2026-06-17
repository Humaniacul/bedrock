import { ok } from '@/lib/http';

// Must run per-request so it reflects the live process env, not a build snapshot.
export const dynamic = 'force-dynamic';

// Safe diagnostic: reports ONLY whether each required env var is present at
// runtime. Never returns the values themselves — secrets must never leak over
// the wire. Use this to confirm Railway Variables reached the running process.
export async function GET() {
  return ok({
    ok: true,
    env: {
      SUPABASE_URL: Boolean(process.env.SUPABASE_URL),
      SUPABASE_SERVICE_ROLE_KEY: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
      REDIS_URL: Boolean(process.env.REDIS_URL),
    },
  });
}
