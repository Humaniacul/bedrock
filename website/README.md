# Bedrock — website

The public marketing + legal site for Bedrock, served at **thebedrock.app**.
Next.js (App Router), fully static, no environment variables, no database.

## Routes

| Path           | Purpose                                                      |
| -------------- | ----------------------------------------------------------- |
| `/`            | Landing page                                                |
| `/privacy`     | Privacy Policy (the app links here from Settings)           |
| `/terms`       | Terms of Service (the app links here from Settings)         |
| `/join/[code]` | Partner-invite landing — where shared invite links resolve  |
| `/join`        | Fallback when no code is present                             |

The iOS app hardcodes `https://thebedrock.app/privacy` and `/terms`, and shares
partner links as `https://thebedrock.app/join/<CODE>`. Keep these paths stable.

## Local dev

```bash
cd website
npm install
npm run dev        # http://localhost:3001
```

## Deploy to Vercel

1. Push this repo to GitHub (the website lives in the `website/` subfolder).
2. In Vercel → **Add New… → Project** → import the repo.
3. **Set Root Directory to `website`** (Settings → General → Root Directory).
   Framework preset auto-detects as Next.js. No env vars needed.
4. Deploy. Then add the custom domain **thebedrock.app** under
   Settings → Domains, and point your DNS as Vercel instructs.

> This is a separate Vercel project from the Railway-hosted API. The two don't
> share infrastructure — the website is pure static content.

## Before you go live — fill these placeholders

Search the `app/` folder for these and replace:

- `[LEGAL ENTITY NAME]`, `[ADDRESS]` in `app/privacy/page.tsx`
- `[JURISDICTION]` in `app/terms/page.tsx`
- The `EFFECTIVE` date constant in both legal pages (currently June 18, 2026)
- The App Store URL `https://apps.apple.com/app/bedrock` (used in several pages)
  once you have the real listing.

> ⚠️ The Privacy Policy and Terms are a solid, app-accurate **starting draft** —
> not legal advice. Because Bedrock handles sensitive (sexual-behavior /
> recovery) data, have a lawyer review both before launch, especially the
> GDPR/CCPA and liability sections.
