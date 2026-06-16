-- Realtime publication (§3): partners get live tamper alerts and the user's
-- gauntlet gets the live approval signal. The client subscribes to these tables
-- filtered to rows it's allowed to see (RLS applies to Realtime too).

alter publication supabase_realtime add table public.tamper_events;
alter publication supabase_realtime add table public.approval_requests;
