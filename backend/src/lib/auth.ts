import { createHash, randomBytes } from 'node:crypto';
import { db } from './supabase';

// v1 device-token auth. The device registers and gets an opaque bearer token;
// we store only its SHA-256. Upgrade path: Supabase Auth / Sign in with Apple
// populating users.auth_user_id (the RLS policies already key off auth.uid()).

export function newToken(): string {
  return randomBytes(32).toString('base64url');
}

export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export interface AuthedUser {
  id: string;
  deviceId: string;
}

export async function authenticate(req: Request): Promise<AuthedUser | null> {
  const header = req.headers.get('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return null;

  const { data } = await db()
    .from('users')
    .select('id, device_id')
    .eq('token_hash', hashToken(token))
    .maybeSingle();

  return data ? { id: data.id, deviceId: data.device_id } : null;
}
