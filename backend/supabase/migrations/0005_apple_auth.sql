-- 0005_apple_auth.sql — Sign in with Apple identity link (§3).
-- The app verifies + links via /api/auth/apple. apple_sub is intentionally NOT
-- unique: one Apple account may map to several device rows (multi-device); the
-- entitlement webhook updates all rows that share the rc_app_user_id.

alter table public.users
    add column if not exists apple_sub text,
    add column if not exists email     text;

create index if not exists users_apple_sub_idx on public.users (apple_sub);
