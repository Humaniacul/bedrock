import { createClient, type SupabaseClient } from '@supabase/supabase-js';

// Service-role client. The API does its own authorization (device token → user);
// the service role bypasses RLS. Never expose the service role key to clients.
let client: SupabaseClient | null = null;

export function db(): SupabaseClient {
  if (!client) {
    const url = process.env.SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) throw new Error('SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not configured');
    client = createClient(url, key, { auth: { persistSession: false } });
  }
  return client;
}
