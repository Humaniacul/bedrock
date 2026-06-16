# Bedrock backend

Accountability + server-validated time for Bedrock (§3). **Next.js API on Railway**, **Supabase** (Postgres + Auth + Realtime + RLS), **Upstash Redis + BullMQ** for scheduled jobs, **APNs** for push.

The iOS app talks only to this API (plain HTTPS); it never holds Supabase keys. Everything is **deploy-ready** — provision the accounts below, set env vars, and ship. Until then the iOS app runs in local stub mode.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/register` | Register a device → `{ userId, token }` (bearer for all other calls) |
| GET | `/api/time` | Server time for cooldowns (§10.5) |
| POST | `/api/heartbeat` | Device check-in (protection/strict state) |
| POST | `/api/tamper` | Report a dropped layer → supportive partner alert |
| POST | `/api/partner/invite` | Create an invite code/link |
| POST | `/api/partner/accept` | Accept an invite (mutual for `peer`/two-key) |
| GET | `/api/partner/status` | My partners + the people I support (partner view) |
| POST | `/api/approval/request` | Gauntlet step 6 — ask partner(s) to approve |
| POST | `/api/approval/respond` | Partner approves/denies |
| GET | `/api/approval/pending` | Partner's inbox |
| GET | `/api/approval/status?ids=` | Requester polls for the decision |
| POST | `/api/cooldown/start` · GET `/api/cooldown/check?id=` | Server-validated cooldown |

All except `/register` and `/time` require `Authorization: Bearer <token>`.

## Deploy

1. **Supabase** — create a project. Run the migrations in `supabase/migrations/` in order (SQL editor or `supabase db push`). Copy the Project URL + **service role** key.
2. **Upstash** — create a Redis database; copy the `rediss://` URL.
3. **Railway** — two services from this repo:
   - **web**: `npm run build` / `npm run start` (uses `railway.json`).
   - **worker**: start command `npm run worker` (the BullMQ sweep).
   - Set env from `.env.example` on both.
4. **APNs** (needs a paid Apple Developer account) — create an APNs Auth Key (`.p8`), set `APNS_*`. Until set, pushes no-op and everything else works.
5. Point the iOS app at the web service URL (`BackendConfig`, see the app's `Backend/` group).

```sh
npm install
npm run typecheck
npm run dev      # local API on :3000
npm run worker   # local sweep worker (needs REDIS_URL)
```

## Auth (v1 → production)

v1 identity is a device-generated id + a server-issued bearer token (hashed at rest). RLS policies are already written against `auth.uid()` for the upgrade to **Supabase Auth / Sign in with Apple** — populate `users.auth_user_id` and switch the client to Supabase-issued JWTs.

## Notes
- The API uses the Supabase **service role** and does its own authz; never expose that key to clients.
- Add request logging / error tracking (e.g. structured logs + Sentry) before production — handlers are intentionally minimal here.
- Partner alerts are always **supportive** ("a good moment to reach out"), never "caught" (§4).
