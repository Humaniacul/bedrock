# Bedrock — App Store Submission Kit

Everything you need to put Bedrock in front of App Review. The most important
section is **App Review Notes** — the §9 two-register framing is what gets the
Family Controls entitlement *approved* rather than rejected.

> **Two-register rule (§9):** Apple-facing copy (this file, App Store metadata,
> review notes, the Family Controls usage string) uses **focus / screen-time /
> usage-management** language only. The recovery mission lives on **in-app,
> user-facing surfaces** — never in anything Apple reads for the entitlement.

---

## 1. App Review Notes (paste into App Store Connect → App Review Information → Notes)

> Bedrock is a **focus and screen-time self-management** app. People choose apps
> and websites that distract them and place them behind a shield they set up
> themselves, with an optional stricter mode and an accountability partner to
> help them stick to their own limits.
>
> **Family Controls usage:** We use Apple's Family Controls / Managed Settings /
> Device Activity APIs on the user's **own device**, for **self-restriction the
> user configures and consents to** — the same sanctioned pattern as Opal, Jomo,
> and similar focus apps. We do **not** use `NEFilterDataProvider`, MDM, or
> configuration profiles. Nothing is installed on a supervised/managed device.
>
> **Strict Mode** is an optional, user-initiated commitment: the user sets a
> Screen Time passcode and can always remove their own restrictions by completing
> an in-app process. There is no inescapable state.
>
> **How to test:** Family Controls requires a real device and the granted
> entitlement. On first launch, complete the short setup, tap "Choose what to
> block," grant Screen Time, and pick any app/category. Toggle protection on/off
> in the Protection tab. Accountability and Insights are subscription features
> (see the demo account below).
>
> **Demo account:** [provide a RevenueCat sandbox account / Screen Time-enabled
> test device, or note "no login required — device-based"].

**Reviewer checklist to pre-empt rejections:**
- Family Controls **Distribution** entitlement approved for every bundle id
  (app + monitor + shield + shieldaction).
- Subscriptions configured and in "Ready to Submit"; restore works.
- Privacy Policy + Terms URLs reachable (Settings links to them).
- In-app **account/data deletion** present (see §5 — required by 5.1.1(v)).

---

## 2. App Privacy (App Store Connect → App Privacy questionnaire)

Bedrock keeps the sensitive material **on-device** (streak, trigger patterns,
blocking choices, the future-self letter, the support contact). The backend only
stores what accountability needs.

**Data collected & linked to the user (purpose: App Functionality):**
- **Identifiers — Device ID:** a per-device pseudonymous id used to link an
  accountability partner and sync entitlement. Not advertising; never sold.
- **Contact Info — Name (optional):** the display name a user types so their
  partner recognizes them. Optional.
- **Purchases:** subscription status, via RevenueCat (third-party SDK).

**Data NOT collected (declare "Data Not Collected" / on-device):**
- Trigger/urge logs, danger windows, streak, and the future-self letter —
  computed and stored **only on the device**.
- The support contact's phone number — stored **only on the device**.
- No browsing/web history, no health data, no location, no contacts upload
  (the contact picker runs out-of-process; we never read the address book).

**Third-party SDKs:** RevenueCat (purchase/subscription data + the device id as
`app_user_id`). No analytics or ad SDKs.

**Tracking:** No. Bedrock does **not** track across apps/sites; no ATT prompt.

---

## 3. Store Listing Copy (focus register)

- **Name:** Bedrock
- **Subtitle (30 chars):** `Block distractions. Stay you.`
- **Promotional text:** Take back your attention. Block what pulls you in, make
  it stick, and have someone in your corner.
- **Keywords:** `focus,screen time,app blocker,website blocker,self control,discipline,accountability,habits,distraction,limit`
- **Description (draft):**
  > Bedrock helps you take back control of your attention.
  >
  > Choose the apps and sites that pull you in, and Bedrock puts them behind a
  > wall you build on purpose — when you're thinking clearly, not at your weakest
  > moment.
  >
  > • **The Wall** — block apps, categories, and adult/explicit websites with
  >   Apple Screen Time. Free, forever.
  > • **Strict Mode** — make your limits stick with a Screen Time lock and a
  >   thoughtful, deliberate process to change them.
  > • **A partner in your corner** — invite someone you trust; supportive, never
  >   shaming.
  > • **Insight** — Bedrock learns your tough times of day and helps you get
  >   ahead of them. All on your device.
  >
  > Premium unlocks Strict Mode, accountability, and Insights. Basic blocking is
  > always free.
  >
  > *Subscriptions auto-renew unless cancelled. Manage in Settings.*

---

## 4. Screenshots (6.7" + 6.1", required)

1. **Foundation** — the monolith + day count (the hero).
2. **Onboarding hook** — "The man you're building is still in there."
3. **Protection** — choosing what to block (the free win).
4. **Paywall** — the plans (annual highlighted).
5. **Insights** — the danger-window heatmap.
6. **Strict Mode / the gauntlet** — "make it unbreakable."

Caption each in the focus register ("Block what pulls you in," "Make your limits
stick," "See your tough times coming").

---

## 5. Pre-submission checklist (the real blockers)

- [ ] **Family Controls Distribution entitlement** approved for all 4 bundle ids
      (start early — weeks-long, critical path).
- [ ] Deployment target bumped **26.2 → 26.4** (§10.1) once the 26.4 SDK is
      installed. Do not bump before — it won't build locally.
- [ ] RevenueCat: products created in App Store Connect, attached to the
      `premium` entitlement, in an Offering; public SDK key in `Info.plist`;
      webhook → Railway `REVENUECAT_WEBHOOK_AUTH` set; migration `0004` run.
- [ ] APNs `.p8` in Railway (real partner push).
- [x] **In-app account & data deletion** (App Store Guideline 5.1.1(v)) — DONE.
      Settings → Account → "Delete my account & data" (with confirmation) calls
      `DELETE /api/account` (removes the user row; FKs cascade) and wipes all
      on-device data (Keychain identity + passcode, the App Group suite), then
      resets the app to onboarding. Note for reviewers: this does **not** cancel
      an active App Store subscription (managed via Apple ID) — by design.
- [ ] Privacy Policy + Terms pages live at the URLs Settings links to.
- [ ] Subscription group, prices, and 3-day intro offer configured in ASC.
- [ ] Restore Purchases verified.
- [ ] Reduce Transparency + Reduce Motion verified on-device (§10).
