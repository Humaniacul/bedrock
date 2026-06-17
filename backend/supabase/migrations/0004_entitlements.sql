-- 0004_entitlements.sql — RevenueCat → Supabase entitlement sync (§3, §8).
-- RevenueCat webhooks (see /api/webhooks/revenuecat) keep these columns current.
-- The app's RevenueCat `app_user_id` is the device id, so we reconcile by
-- matching `users.device_id` (also stored as `rc_app_user_id` for traceability).

alter table public.users
    add column if not exists is_premium         boolean not null default false,
    add column if not exists premium_expires_at timestamptz,
    add column if not exists rc_app_user_id      text,
    add column if not exists rc_updated_at       timestamptz;

create index if not exists users_rc_app_user_id_idx on public.users (rc_app_user_id);
