# Open questions

Decisions the design can’t make alone. Each has a recommendation and what changes either way. The first two are now decided (see their headings); the rest can be settled while the early screens are built.

## Blocking

### 1. The partner model (RT-02) · DECIDED: ship the Phase 7 model (confirmed by Codrin)

**What changed.** Brief 2.4 lists Partner-held as built: the person sets and keeps the Screen Time passcode. Phase 7 replaced it with Bedrock-held blind entry plus partner approval, and a 3-day release: a request the person doesn’t answer within 3 days opens, and they’re told.

**Why.** With the built model, if the person vanishes, breaks up with him or refuses to let go, the only way out is erasing the iPhone. It also needs them in the same room, which can delay the lock by days.

**Recommendation.** Ship the Phase 7 model. The gauntlet already has partner approval; what’s new is the server-side 3-day timer and that the partner never types a passcode.

**If you keep the built model.** Restore S13.3P (“Finish this together.”) and S13.4P (“You’re setting their passcode.”) from the Phase 4 spec boards’ history, restore the S13.2P note (“…the only other way out is erasing this iPhone.”), the S11 option B copy and tag (“Needs them with you once”), and the SP4 body about setting the passcode together.

**Sub-questions.** Is 3 days right? Does a declined request also open after 3 days (the design says yes, so a decline can delay but never trap)? Does removing the person go through the steps, with them told (the design says yes)?

### 2. The floating digit window (RT-23) · DECIDED: spike A first, keep B behind a remote flag (confirmed by Codrin)

**Options.** (A) Picture in Picture with a sample-buffer content source drawing the digit, so it floats over Settings. (B) App switching: each digit shown in Bedrock for 3 seconds, then “Switch to Settings”.

**Risks.** A is the better experience and the more expensive build, and non-video PiP is a review risk. B is cheap and certain, but switching apps eight times is clumsy and easier to get wrong.

**Recommendation.** Spike A first (a day or two). If it works on the lock-test devices and survives a TestFlight review, ship it; keep B behind a remote flag either way, since the spec already uses B when the user has PiP turned off.

## Before Strict Mode ships

### 3. Releasing the code when the server can’t be reached

At the end of the gauntlet, can the code be released offline, or does it wait for the server? Offline release makes the gauntlet work on a plane; server-only release makes the 30-minute wait and the partner approval impossible to fake by cutting the network. **Recommendation:** server-only for partner approval; for Bedrock-held, allow offline release only after the full steps plus a longer offline wait (for example 2 hours on system uptime), and tell the person that on the gauntlet screen.

### 4. Verified iOS versions (from the lock test, board 04)

Strict Mode is sold only on versions where the lock test passes. Fill the remote config before launch: which of iOS 26.4, 26.5, 26.6 and 27.x pass every row of the F3 comparison, including the reported Face ID bypass on the per-app Settings page in 26.4–26.6. Record the exact iOS wording of the Screen Time sheets per version while you’re at it; S13.4B’s checklist uses the expected labels and says they may differ.

### 5. Where the code lives

The spec says Keychain before the first digit (RT-03) and escrow for the gauntlet. Decide whether the escrow is device-only (Keychain, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), server-only, or both. Device-only is simplest and works offline but dies with a restore; server-held survives a new phone via Sign in with Apple. **Recommendation:** both, encrypted, with the server copy released only by the gauntlet.

## Product and policy

### 6. Supporters without an iPhone (RT-22)

The supporter flow is iPhone-only. Options: a web page at `thebedrock.app/join` where a supporter can see status and approve requests after a magic-link sign-in; or an Android app later. **Recommendation:** the web page, since approvals are a few taps and the 3-day release now protects against a supporter who can’t act quickly.

### 7. Analytics consent in the EU (RT-21)

A persistent random ID stored on the device may need consent under EU ePrivacy rules even without personal data. This is a legal question, so get a privacy lawyer’s view before an EU launch. Options:
- A consent toggle on EU storefronts (off by default), with session-scoped IDs until it’s on.
- Session-scoped IDs everywhere: funnels still work within a session; cross-day retention moves to RevenueCat and the server.
- Keep a persistent ID and rely on the lawyer’s view that it’s strictly necessary (unlikely for analytics).

`OnboardingAnalytics.swift` keeps PostHog’s anonymous ID unlinked from the server’s device ID until this is decided.

### 8. What Sign in with Apple syncs (RT-09)

The design says: plan, Foundation days and settings; never the answers, the word or the letter. Confirm, because Foundation days are arguably personal too, and “Your answers stay on this iPhone” must stay literally true.

### 9. Crisis lines by region (RT-12)

The sheet shows 988 only in the US and Canada and puts findahelpline.com first elsewhere. Decide whether to add a short list of verified national lines for your biggest storefronts (for example the UK and Ireland’s Samaritans on 116 123) and who keeps that list current. Never show a number that hasn’t been checked for that country.

### 10. Trial length (first A/B test)

The defaults launch with 3 days and test 7 first. Confirm you’re comfortable shipping 3 days at launch given the RevenueCat data in AB_TESTS.md, or start at 7.

## Smaller

- **Free card timing:** the “Remove the door” Home card appears once after an S12 decision. Should it come back after a set time (for example 30 days) if dismissed? The design says no: the status chip is the permanent way back.
- **Letter minimum:** S13.1 asks for 40 characters. The default letter (“Use a short one for now”) fills it. Fine as is unless testing shows people stall.
- **Slow mode:** S13.7A shows digits again at 5 seconds each. Confirm 5 is right on the lock-test devices.
- **Intercept from S15:** the rehearsal stops after one breath. The real Intercept continues to “what’s underneath”. Confirm Intercept’s first screen matches what S15 promises.
