import { db } from '@/lib/supabase';
import { hashToken, newToken } from '@/lib/auth';
import { ok, err, readJson } from '@/lib/http';

// Register (or rotate the token for) a device. v1 identity (see lib/auth.ts).
export async function POST(req: Request) {
  const { deviceId, displayName } = await readJson<{ deviceId: string; displayName?: string }>(req);
  if (!deviceId) return err('deviceId required');

  const supabase = db();
  const token = newToken();
  const { data: existing } = await supabase
    .from('users')
    .select('id')
    .eq('device_id', deviceId)
    .maybeSingle();

  if (existing) {
    await supabase
      .from('users')
      .update({ token_hash: hashToken(token), display_name: displayName ?? null })
      .eq('id', existing.id);
    return ok({ userId: existing.id, token });
  }

  const { data, error } = await supabase
    .from('users')
    .insert({ device_id: deviceId, token_hash: hashToken(token), display_name: displayName ?? null })
    .select('id')
    .single();
  if (error) return err(error.message, 500);
  return ok({ userId: data.id, token });
}
