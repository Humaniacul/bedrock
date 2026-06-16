import { ok } from '@/lib/http';

// Server-validated time (§10.5). The device never trusts its own clock for
// cooldowns — it reconciles against this.
export async function GET() {
  return ok({ nowMs: Date.now() });
}
