-- Bedrock backend schema (§3). Postgres on Supabase.
-- Identities are device-token based for v1; the `auth_user_id` column is the
-- seam for upgrading to Supabase Auth / Sign in with Apple later.

create extension if not exists pgcrypto;

-- Users (the person in recovery AND partners both have a row).
create table if not exists public.users (
    id            uuid primary key default gen_random_uuid(),
    device_id     text unique not null,
    auth_user_id  uuid,                       -- future: references auth.users(id)
    token_hash    text not null,              -- sha256 of the device's bearer token
    display_name  text,
    apns_token    text,
    protection_active boolean not null default false,
    strict_enabled    boolean not null default false,
    last_heartbeat_at timestamptz,
    created_at    timestamptz not null default now()
);

-- A directed support link: `partner` supports `supported` user.
create table if not exists public.partner_links (
    id            uuid primary key default gen_random_uuid(),
    supported_id  uuid not null references public.users(id) on delete cascade,
    partner_id    uuid not null references public.users(id) on delete cascade,
    kind          text not null default 'partner' check (kind in ('partner', 'peer')),
    status        text not null default 'active' check (status in ('active', 'revoked')),
    created_at    timestamptz not null default now(),
    unique (supported_id, partner_id)
);

-- Invite codes a user generates for a partner (or peer) to accept.
create table if not exists public.invites (
    id            uuid primary key default gen_random_uuid(),
    code          text unique not null,
    created_by    uuid not null references public.users(id) on delete cascade,
    kind          text not null default 'partner' check (kind in ('partner', 'peer')),
    accepted_by   uuid references public.users(id) on delete set null,
    accepted_at   timestamptz,
    expires_at    timestamptz not null default (now() + interval '7 days'),
    created_at    timestamptz not null default now()
);

-- Protection-layer drops detected on device or by the heartbeat sweep.
create table if not exists public.tamper_events (
    id            uuid primary key default gen_random_uuid(),
    user_id       uuid not null references public.users(id) on delete cascade,
    kind          text not null check (kind in ('shield_cleared', 'screen_time_off', 'app_dark', 'uninstall_lock_off')),
    notified      boolean not null default false,
    created_at    timestamptz not null default now()
);

-- Gauntlet step 6: the user asks the partner to approve a disable.
create table if not exists public.approval_requests (
    id            uuid primary key default gen_random_uuid(),
    user_id       uuid not null references public.users(id) on delete cascade,
    partner_id    uuid not null references public.users(id) on delete cascade,
    reason        text,
    status        text not null default 'pending' check (status in ('pending', 'approved', 'denied', 'expired')),
    created_at    timestamptz not null default now(),
    responded_at  timestamptz
);

-- Server-validated cooldowns (§10.5) — the device cannot fake elapsed time.
create table if not exists public.cooldowns (
    id            uuid primary key default gen_random_uuid(),
    user_id       uuid not null references public.users(id) on delete cascade,
    duration_seconds integer not null,
    started_at    timestamptz not null default now()
);

create index if not exists tamper_events_user_idx on public.tamper_events (user_id, created_at desc);
create index if not exists approval_requests_partner_idx on public.approval_requests (partner_id, status);
create index if not exists partner_links_partner_idx on public.partner_links (partner_id, status);
