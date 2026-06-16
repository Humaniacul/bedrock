-- Row Level Security (§9: RLS on every table).
--
-- The Next.js API talks to Postgres with the SERVICE ROLE, which bypasses RLS,
-- and does its own authorization (device token → user). These policies are
-- defense-in-depth for the future client-direct path, once Supabase Auth /
-- Sign in with Apple populates `users.auth_user_id` = auth.uid().

alter table public.users            enable row level security;
alter table public.partner_links    enable row level security;
alter table public.invites          enable row level security;
alter table public.tamper_events    enable row level security;
alter table public.approval_requests enable row level security;
alter table public.cooldowns        enable row level security;

-- Maps the current authenticated principal to a users.id.
create or replace function public.current_user_id() returns uuid
language sql stable security definer set search_path = public as $$
    select id from public.users where auth_user_id = auth.uid()
$$;

-- Users: see/update only your own row.
create policy users_self_select on public.users
    for select using (auth_user_id = auth.uid());
create policy users_self_update on public.users
    for update using (auth_user_id = auth.uid());

-- Partner links: visible to either side of the link.
create policy links_visible on public.partner_links
    for select using (
        supported_id = public.current_user_id()
        or partner_id = public.current_user_id()
    );

-- Invites: only the creator can read theirs.
create policy invites_owner on public.invites
    for select using (created_by = public.current_user_id());

-- Tamper events: the user, and any active partner of that user.
create policy tamper_visible on public.tamper_events
    for select using (
        user_id = public.current_user_id()
        or exists (
            select 1 from public.partner_links pl
            where pl.supported_id = tamper_events.user_id
              and pl.partner_id = public.current_user_id()
              and pl.status = 'active'
        )
    );

-- Approval requests: the requester and the partner who must respond.
create policy approvals_visible on public.approval_requests
    for select using (
        user_id = public.current_user_id()
        or partner_id = public.current_user_id()
    );
create policy approvals_partner_respond on public.approval_requests
    for update using (partner_id = public.current_user_id());

-- Cooldowns: owner only.
create policy cooldowns_owner on public.cooldowns
    for select using (user_id = public.current_user_id());
