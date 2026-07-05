# Bedrock — production deployment guide

Everything required to take Bedrock from "builds locally" to "running in
production." Split by **who** does it: 🤖 = already done in the repo, 🧑 = a
dashboard/secret action only you can do (secrets must never enter the app binary,
git, or this repo).

---

## 1. iOS 26.4 deployment target 🧑 (one-line flip, later)

**Status: held at 26.2 on purpose.** Your machine only has the iOS **26.2 SDK**
(Xcode 26.2). Bumping the target before the SDK exists breaks every local build.

The hard constraint (§10.1): iOS **26.4** closes the Screen Time passcode bypass.
Ship no release that relies on the passcode lock below 26.4.

**When you have Xcode with the 26.4 SDK installed:**

1. Edit [`project.yml`](../project.yml) → `options.deploymentTarget.iOS: "26.2"` → `"26.4"`.
2. Run `xcodegen generate`.
3. Build. Done.

No other code changes are needed — the marker comment in `project.yml` flags it.

---

## 2. Backend on Railway — TWO services from one repo

The repo's `backend/` folder now defines **two** Railway config files:

| Service | Config file                  | Start command     | Purpose                                              |
| ------- | ---------------------------- | ----------------- | --------------------------------------------------- |
| web     | `backend/railway.json`       | `npm run start`   | The Next.js API (already deployed).                 |
| worker  | `backend/railway.worker.json`| `npm run worker`  | BullMQ missed-heartbeat sweep + partner escalations.|

🤖 Both config files exist. 🤖 `tsx` was moved to runtime `dependencies` so the
worker process can launch in production (it would otherwise be pruned).

### Create the worker service 🧑

1. Railway → your project → **+ New → GitHub Repo** → pick this repo again
   (a second service from the same repo is expected).
2. Open the new service → **Settings**:
   - **Root Directory:** `backend` (same as the web service).
   - **Config-as-code path:** `railway.worker.json`
     (this is what makes it run `npm run worker` instead of the web start command).
3. Give it the env vars below (it needs at minimum `SUPABASE_URL`,
   `SUPABASE_SERVICE_ROLE_KEY`, and `REDIS_URL`; add `APNS_*` to send partner
   pushes).
4. Deploy. Logs should show:
   `[worker] heartbeat sweep every 900s, stale after 45m`.

> Without this service running, "your person went dark" alerts never fire — the
> web API never sweeps for stale heartbeats.

---

## 3. Environment variables (Railway) 🧑

Set these in **each** Railway service's Variables tab. The list is derived
directly from what the code reads (`process.env.*`).

| Variable                    | web | worker | Notes                                                                 |
| --------------------------- | :-: | :----: | --------------------------------------------------------------------- |
| `SUPABASE_URL`              | ✅  |   ✅   | Supabase project URL.                                                 |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅  |   ✅   | **Service role — server only. Never in the app, git, or shared.**     |
| `REDIS_URL`                 | —   |   ✅   | Upstash `rediss://…`. **Worker only** — no web route uses the queue.  |
| `REVENUECAT_WEBHOOK_AUTH`   | ✅  |   —    | Long random secret; must match the RevenueCat webhook header.        |
| `APPLE_BUNDLE_ID`           | ✅  |   —    | Audience for Apple identity-token verify. Defaults `com.thebedrock.app`. |
| `PUBLIC_INVITE_BASE_URL`    | ✅  |   —    | e.g. `https://thebedrock.app/join` — base for partner invite links.  |
| `APNS_KEY_P8`               | ✅  |   ✅   | Contents of the `.p8`. See §4. Pushes are a no-op until this is set.  |
| `APNS_KEY_ID`               | ✅  |   ✅   | 10-char key id from Apple.                                            |
| `APNS_TEAM_ID`              | ✅  |   ✅   | Your Apple team id (`BWL4YS7RFJ`).                                    |
| `APNS_BUNDLE_ID`            | ✅  |   ✅   | `com.thebedrock.app`. Defaults if unset.                             |
| `APNS_HOST`                 | ✅  |   ✅   | `https://api.push.apple.com` (prod) or `…sandbox…` (dev builds).     |
| `HEARTBEAT_STALE_MINUTES`   |  —  |   ✅   | Optional. Default 45.                                                 |
| `SWEEP_INTERVAL_MS`         |  —  |   ✅   | Optional. Default 900000 (15 min).                                    |

> The web API itself only *queues* sweeps / sends pushes on demand, so APNS_*
> can live on web too — but the scheduled sweep that actually pushes partner
> alerts runs in the **worker**, so the worker is the one that truly needs APNS_*.

---

## 4. APNs (.p8) 🧑 — secret, you paste it into Railway

Push is fully coded ([`backend/src/lib/apns.ts`](../backend/src/lib/apns.ts)) and
no-ops until the key is present. To enable real partner notifications:

1. Apple Developer → **Certificates, Identifiers & Profiles → Keys → +**.
2. Enable **Apple Push Notifications service (APNs)**, create the key, and
   **download the `.p8` once** (Apple won't let you re-download it).
3. In Railway, set:
   - `APNS_KEY_ID` = the key's 10-character ID.
   - `APNS_TEAM_ID` = `BWL4YS7RFJ`.
   - `APNS_KEY_P8` = the full contents of the `.p8` file. If the Railway field is
     single-line, replace newlines with literal `\n` (the code converts `\n` back
     to real newlines). A multi-line value works too.
   - `APNS_HOST` = `https://api.push.apple.com` for App Store / TestFlight builds.

> Paste the `.p8` **only** into Railway. Never commit it, never put it in the
> app, never send it to anyone (including me).

---

## 5. Privacy Policy + Terms website 🤖 → deploy 🧑

A standalone Next.js site lives in [`website/`](../website) and builds clean.
Routes: `/`, `/privacy`, `/terms`, `/join/[code]`. The app links to
`thebedrock.app/privacy` and `/terms`, and shares invites as
`thebedrock.app/join/<code>` — these paths are already wired.

**Deploy (separate Vercel project from the Railway API):**

1. Vercel → **Add New → Project** → import this repo.
2. **Root Directory = `website`** (Settings → General).
3. Deploy (no env vars needed), then add domain **thebedrock.app**
   (Settings → Domains) and point DNS as Vercel instructs.

**Before go-live**, fill the placeholders (see [`website/README.md`](../website/README.md)):
`[LEGAL ENTITY NAME]`, `[ADDRESS]`, `[JURISDICTION]`, the effective date, and the
real App Store URL. ⚠️ The legal copy is an app-accurate **draft** — have a
lawyer review it before launch (sensitive-category data).

---

## Quick verification checklist

- [ ] Worker service shows `[worker] heartbeat sweep every …` in Railway logs.
- [ ] `https://thebedrock.app/privacy` and `/terms` resolve.
- [ ] RevenueCat webhook test ping returns 200 (`REVENUECAT_WEBHOOK_AUTH` matches).
- [ ] A real device receives a partner push (confirms APNS_* + token).
- [ ] iOS target bumped to 26.4 once the SDK is installed.
