import { ok } from '@/lib/http';

// Must run per-request — a static/cached value would freeze the clock at build.
export const dynamic = 'force-dynamic';

// Server-validated time (§10.5). The device never trusts its own clock for
// cooldowns — it reconciles against this.
export async function GET() {
  return ok({ nowMs: Date.now() });
}
