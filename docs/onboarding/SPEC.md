# Bedrock onboarding — screen spec (First Light)

Generated from the spec boards F7–F12 on the design canvas, after the Phase 7 red team. Every string here is final copy. Where a value contains ` · `, the dot separates distinct UI strings (a title and its subtitle, a sheet’s rows) unless the screen shows a literal middle dot, such as the status chip or the trust line.

Prices in copy are examples for the US storefront. Never hard-code them: read `localizedPriceString` from StoreKit through RevenueCat and compute the per-month figure from the local price.

**36 screens and states.** Main path: S1 → S2 → S3 → S4 → S5 → S6 → S7 → S8 → S9 → S10 → S11 → S12 → SIWA → S13.x → S14 → S15 → Home.

## Contents

- **Wall**: Arrival, Screen Time, the wall goes up, the test — [S1](#s1), [S2](#s2), [S2-D](#s2-d), [S3](#s3), [S4](#s4)
- **You**: Hard hours, what’s underneath, the word, the stone — [S5](#s5), [S6](#s6), [S7](#s7), [S8](#s8)
- **Lock**: The door, what 2am faces, who holds the key — [S9](#s9), [S10](#s10), [S11](#s11)
- **Paywall**: Remove the door, the version gate, Sign in with Apple — [S12](#s12), [S12U](#s12u), [SIWA](#siwa)
- **Begin**: Strict Mode setup, heads-ups, one practice breath, Home — [S13.1](#s131), [S13.2B](#s132b), [S13.3B](#s133b), [S13.4B](#s134b), [S13.5A](#s135a), [S13.5B](#s135b), [S13.6](#s136), [S13.7A](#s137a), [S13.7B](#s137b), [S13.2P](#s132p), [S14](#s14), [S15](#s15), [Home](#home)
- **Branches**: Managed devices, simulator, resume, finish later — [B2](#b2), [B9](#b9), [RESUME](#resume), [FL](#fl)
- **Supporter**: The person who holds the key — [SP1](#sp1), [SP2](#sp2), [SP3](#sp3), [SP4](#sp4)

## Rules that apply to every screen

- Tokens, type, motion and haptics come from `BedrockTokens.swift`, `BedrockMotion.swift` and `BedrockHaptics.swift`. No literal colours, fonts or springs in views.
- One hero animation per screen, named in its Motion section. Everything else uses Rise (screen in) or Settle.
- Carve only where a screen asks for it: S1, “You’re in.”, S13.6, Home’s first headline, SP1, and the carved word on S8.
- Every animation has the Reduce Motion version listed. Every gesture has a VoiceOver or tap equivalent.
- Pre-permission screens (S2, S14, SP3) have one button, never labelled “Allow”. Either answer from iOS moves on.
- Nothing personal leaves the phone: no answers, no word, no letter, no app or site names in analytics or on the server.
- Backgrounding on S5–S8, S13.1 and Home shows a plain stone cover in the app switcher.
- Onboarding state (screen ID, answers, wall status) is written to the app group on every screen change; see RESUME.
- Accessibility text sizes: two-column grids become one column; side-by-side cards stack; primary buttons stay pinned above the home indicator.
- Liquid Glass on controls only (back, close, Finish later, hold control). With Reduce Transparency, glass becomes solid `bg.raised`.

---

## Wall

_Arrival, Screen Time, the wall goes up, the test_

### S1

**Arrival** · read · ~6s · 0:06

**Job.** Disarm in one line and start building the wall before anything is asked.

**Earns its place.** Without it, the first thing anyone sees is an iOS permission sheet about “restricting content”. It also makes the promise (“in the next minute”) that S3 keeps.

**Layout.** Full-bleed obsidian, no chapter bar. Small stone mark top-left at 96pt. Text block in the lower half: mono eyebrow, serif headline (Display XL), body. Primary button pinned 46pt above the home indicator, a text link under it. Dawn level 0: no horizon glow yet.

**Interaction.** Primary is enabled immediately. The link opens the supporter flow (SP1). No back, no skip: there is nothing before this.

**Data captured → pays off.** Nothing captured. Start time is stamped on device for the timing funnel.

**Copy**

| Key | String |
|---|---|
| Eyebrow | BEDROCK |
| Headline | Build it now, while you mean it. |
| Body | In the next minute, most adult sites stop opening on this phone. Then we make it hard to undo. |
| Primary | Build my wall |
| Link | I’m here to support someone |
| R1 headline | Welcome back. |
| R1 body | Your plan is still active. Let’s put the wall back up. |
| R1 primary | Put it back up |

**VoiceOver**

- Headline is a header trait.
- Primary: “Build my wall. Starts setup.”
- Link: “I’m here to support someone. Opens supporter setup.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Background and horizon already in place. No haptic on arrival. |
| 120ms | Stone mark Settles from 12pt below. Spring 0.42 / 0.62. |
| 200ms | Headline Carves in: each glyph from 4pt blur and 6pt below to rest, 420ms, 22ms stagger, curve (0.2, 0.8, 0.2, 1). |
| 900ms | Body rises 8pt and fades in, 360ms ease-out. |
| 1150ms | Button Settles in; the link fades in 200ms later. |

**Transition out.** Tap: light impact. Content Rises out (fade and 8pt up, 180ms ease-in). S2 Settles in 80ms later.

**Reduce Motion.** Everything fades in together over 250ms. No blur, no movement.

**Edge cases**

- Returning Pro user (an active entitlement found via StoreKit): R1 copy, then straight to S2.
- Opened from thebedrock.app/join/CODE: go to SP1 instead.
- Screen Time already authorised: Build my wall skips S2 and goes to S3.
- Largest accessibility text: the content scrolls; the button stays pinned.

**PostHog**

- `onb_started {source: organic | invite_link | returning}`
- `onb_screen_viewed {screen_id: "s1"}`
- `onb_action {screen_id: "s1", action: "build_wall" | "support_someone"}`

### S2

**Before the Screen Time sheet** · tap · ~10s + iOS ~8s · 0:24

**Job.** Say plainly what the one permission does, then hand over to iOS.

**Earns its place.** The iOS sheet says Bedrock may see activity data and restrict content. A privacy-scared user needs the honest version first, or they tap Don’t Allow.

**Layout.** Chapter bar appears (Wall, 25% filled). Eyebrow, Title headline, body. One illustration: a solid stone card with a shield glyph and the words “Screen Time”, centred. Caption directly above a single primary button. Dawn level 1.

**Interaction.** One button only, as the HIG requires for pre-permission screens. Tap calls AuthorizationCenter.requestAuthorization(for: .individual). The button shows a small spinner, no label change, until iOS answers.

**Data captured → pays off.** Authorisation status. Approved unlocks S3 and the Lock chapter. Denied goes to S2-D, restricted to B2, unavailable to B9.

**Copy**

| Key | String |
|---|---|
| Eyebrow | THE WALL |
| Headline | First, Bedrock needs Screen Time. |
| Body | It lets Bedrock block sites and apps on this iPhone. What you browse stays private, even from us. |
| Caption | iOS will ask you to confirm. |
| Primary | Continue |

**VoiceOver**

- Primary: “Continue. Opens the iOS Screen Time request.”
- Illustration is decorative: hidden from VoiceOver.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in from S1. |
| 150ms | Illustration card Settles (hero). Soft impact, intensity 0.4. |
| Approved | Card border warms to ember (Ember, 600ms), light impact, auto-advance to S3 after 500ms. |

**Transition out.** Approved: Rise to S3. Denied: Rise to S2-D. No haptic on denial.

**Reduce Motion.** Card fades in; on approval the border changes colour without glow.

**Edge cases**

- Sheet interrupted by backgrounding: status is still undetermined, so S2 waits with the button ready.
- iOS sheet wording is Apple’s and may differ by version; the lock test confirms it.
- Approved, but the ManagedSettings write fails: handled on S3, not here.

**PostHog**

- `onb_screen_viewed {screen_id: "s2"}`
- `onb_st_permission_prompted`
- `onb_st_permission_result {result: approved | denied | restricted | unavailable, ms_to_decide}`

### S2-D

**Screen Time declined** · tap · ~8s · branch

**Job.** Explain without guilt why the wall needs it, and offer two honest ways forward.

**Earns its place.** Without it, a declined permission is a dead end or a nag. Some people decline by reflex and want a second chance; others need to leave with dignity.

**Layout.** Same layout as S2 with the shield card dimmed. Primary button and a full-width text button beneath it.

**Interaction.** Try again calls requestAuthorization again. If iOS doesn’t show the sheet a second time, the screen switches to its Settings state. Continue without the wall goes to S5, then after S8 straight to Home: no Lock chapter, no paywall.

**Data captured → pays off.** Choice (retry, settings, continue without). Home shows the “wall isn’t up” card until access is granted.

**Copy**

| Key | String |
|---|---|
| Eyebrow | THE WALL |
| Headline | The wall needs Screen Time. |
| Body | Without it, Bedrock can’t block anything here. Allow it now, or any time later. |
| Primary | Try again |
| Secondary | Continue without the wall |
| Settings headline | Turn it on in Settings. |
| Settings body | iOS won’t ask again from here. In Settings, open Bedrock and switch on Screen Time access. Then come back. |
| Settings primary | Open Settings |
| Home card | The wall isn’t up yet. It needs Screen Time access. |

**VoiceOver**

- Secondary: “Continue without the wall. You can turn it on later.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. No haptic: declining isn’t an error. |
| State change | Copy crossfades 240ms when switching to the Settings state. |

**Transition out.** Granted on retry: Rise to S3 with the S2 approval beat. Continue without: Rise to S5.

**Reduce Motion.** Crossfades only.

**Edge cases**

- Returning from Settings with access on: detect on foreground, go to S3.
- Returning still off: stay here, Settings state.
- Restricted device detected on retry: B2.

**PostHog**

- `onb_screen_viewed {screen_id: "s2d"}`
- `onb_action {screen_id: "s2d", action: "retry" | "open_settings" | "continue_without"}`

### S3

**The wall goes up** · tap · ~18s · 0:42

**Job.** Choose what goes behind the wall, then watch each protection land as it’s actually applied.

**Earns its place.** This is the activation moment and the promise from S1 being kept. Without it, blocking would happen invisibly and nobody would believe it.

**Layout.** Chapter bar (Wall). Eyebrow, Title headline. Wall illustration 322 × 150pt on a ground line, empty courses drawn as faint outlines. Three list rows with trailing accessories. Primary button. In the up state the horizon rises one Dawn step.

**Interaction.** Row 1 is always on. Row 2 opens Apple’s FamilyActivityPicker; on return the row shows a count. Row 3 is informational. Put the wall up writes ManagedSettings (web filter on with the test domain added, picked apps shielded) and starts the daily DeviceActivity schedule. Each course lands when its write returns.

**Data captured → pays off.** Picked app and category tokens (count only leaves the device as a bucket). Shown on this row and protected by the shield.

**Copy**

| Key | String |
|---|---|
| Eyebrow | THE WALL |
| Headline | Choose what goes behind the wall. |
| Row 1 | Adult websites · Safari and other browsers · Always on |
| Row 2 | Apps that pull you in · Optional · Add |
| Row 2, after | 3 apps · Their names never leave this iPhone · Edit |
| Row 3 | Checked every day · Bedrock puts the wall back daily, in case anything resets it · Included |
| Primary | Put the wall up |
| Building | Putting the wall up. |
| Up | The wall is up. |
| Up primary | Continue |
| Error headline | Something stopped the wall. |
| Error body | Nothing was blocked yet. Try once more. If it fails again, restart your iPhone and come back. |
| Error primary | Try again |
| Error secondary | Get help |
| Row error | Didn’t apply |

**VoiceOver**

- Row 1: “Adult websites. Safari and other browsers. Always on.”
- Row 2: “Apps that pull you in. Optional. Add, button.”
- Wall: one element announcing “Wall, 2 of 3 rows in place”; on completion VoiceOver announces “The wall is up.”

**Motion and haptics**

| When | What |
|---|---|
| tap | Light impact. Button fades; headline crossfades to “Putting the wall up.” |
| per write | Its course drops 84pt and Settles (0.42 / 0.62), 80ms stagger between stones. Soft impact 0.4 per stone. Row check pops 1.15 → 1 (0.3 / 0.6) with a light impact. |
| all done | Lock: wall dips 3pt and returns (0.28 / 0.9). Heavy impact, then success notification 80ms later. Ember blooms at the base. |
| +0ms | Headline crossfades to “The wall is up.”; “up.” warms to ember over 600ms. Horizon rises one Dawn step over 900ms. |
| +500ms | Continue Settles in. |

**Transition out.** Rise to S4.

**Reduce Motion.** Each course fades in place over 200ms when applied. Lock becomes an ember fade at the base. Haptics unchanged.

**Edge cases**

- No apps picked: course 2 is skipped and the wall stands on two courses.
- Picker cancelled: nothing changes.
- A write takes over 3 seconds: the stones wait; the headline doesn’t change.
- A write fails: that course doesn’t land, its row shows “Didn’t apply”, error copy appears.
- Works offline: everything here is on-device.

**PostHog**

- `onb_picker_opened`
- `onb_picker_result {apps_bucket: 0 | 1-3 | 4-10 | 11+, categories_bucket}`
- `onb_wall_applied {web_filter: true, schedule: true, apps_bucket, apply_ms}`
- `onb_wall_apply_failed {stage: web | apps | schedule}`

### S4

**Try it** · tap · ~20s · 1:02

**Job.** Let them prove the wall works with their own hands, without leaving Bedrock.

**Earns its place.** The cynic believes what he sees. No competitor lets you test the block during onboarding; this turns “trust us” into “try it”.

**Layout.** Chapter bar (Wall). Eyebrow, Title headline, body. A small wall glyph above the button. Primary button, a Skip text button. “Finish later” as a text button top-right from here until S11.

**Interaction.** Open the test page presents SFSafariViewController at https://test.thebedrock.app, a domain added to the web filter on S3. iOS shows its own restriction page. On Done, Bedrock runs a silent check (a background WKWebView load of the same domain, which should fail) and shows Held only if it’s confirmed.

**Data captured → pays off.** Test result. Not shown again, but logged so we know the wall held for this person on day one.

**Copy**

| Key | String |
|---|---|
| Eyebrow | THE WALL |
| Headline | Go ahead. Try it. |
| Body | Open a blocked test page and see what stops it. You won’t leave Bedrock. |
| Primary | Open the test page |
| Secondary | Skip |
| Top right | Finish later |
| Checking | One moment |
| Held headline | Held. |
| Held body | That page is Apple’s, and that’s the point. The block lives in iOS, not in this app. |
| Held primary | Continue |
| Opened headline | That page opened. |
| Opened body | The wall isn’t holding yet. Let’s put it back up. |
| Opened primary | Put it back up |
| Unverified headline | Couldn’t check just now. |
| Unverified body | The wall is set. Bedrock will check again in the background. |
| Finish later sheet | Finish later? · Your wall is up. Bedrock will pick this up the next time you open it. · Go to my wall · Keep going |

**VoiceOver**

- On return, VoiceOver announces “Held. The test page was blocked.”
- Finish later: “Finish later. Your wall stays up.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. |
| return | Lock: “Held.” scales 1.06 → 1 (0.28 / 0.9) as it appears; the wall glyph flashes ember once. Heavy impact, success notification 80ms later. |

**Transition out.** Rise to S5.

**Reduce Motion.** “Held.” fades in; the glyph changes colour without a flash.

**Edge cases**

- Safari view can’t load at all (offline): the background check can still confirm the filter; if it can’t, show the unverified copy.
- Page opens (filter not active): Opened state, Put it back up re-runs S3 writes, then returns here.
- Skip: no penalty, no reminder.

**PostHog**

- `onb_screen_viewed {screen_id: "s4"}`
- `onb_wall_test_started`
- `onb_wall_test_result {result: held | opened | unverified}`
- `onb_wall_test_skipped`
- `onb_finish_later {screen_id}`

---

## You

_Hard hours, what’s underneath, the word, the stone_

### S5

**Hard hours** · tap · ~9s · 1:11

**Job.** Find out when it usually gets hard, so heads-ups can arrive just before.

**Earns its place.** It sets the timing of every heads-up and is the first line of the reflection on S8. Cut it and both lose their substance.

**Layout.** Back button (glass circle, top-left) and Finish later (top-right). Chapter bar (You). Eyebrow, Title headline, body. Six chips in a two-column grid (one column at accessibility text sizes). Privacy chip under the grid. Primary button.

**Interaction.** Multi-select. “No pattern yet” is exclusive: picking it clears the others, picking another clears it. Continue is disabled until one is picked.

**Data captured → pays off.** Hour windows: late night 22:00–02:00, early morning 05:00–08:00, middle of the day 12:00–15:00, after work 17:00–20:00, weekends Saturday and Sunday evenings. → S8 line one, the S14 body, heads-ups 15 minutes before each window, the Insights seed until a real pattern replaces it after about two weeks.

**Copy**

| Key | String |
|---|---|
| Eyebrow | YOU |
| Headline | When does it usually get hard? |
| Body | Pick any that fit. Bedrock uses this to time quiet heads-ups. |
| Chips | Late at night · Early morning · Middle of the day · After work · Weekends · No pattern yet |
| Privacy | Stays on this iPhone |
| Primary | Continue |

**VoiceOver**

- Chips are toggle buttons: “Late at night, not selected.”
- Privacy chip: “Your answers stay on this iPhone.”
- Continue when disabled: “Continue, dimmed. Pick at least one.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. Chips Strata in, 40ms stagger, 12pt rise. |
| select | Chip scales 0.96 → 1 (0.25 / 0.7), border warms to ember. Selection haptic. |

**Transition out.** Rise to S6.

**Reduce Motion.** Chips appear together; selection changes colour only.

**Edge cases**

- Accessibility text sizes: chips become one column (same on S6 and S7); the primary button stays pinned above the home indicator.
- Back: to S4 in its Held state; answers kept.
- Time zone change later: windows are local and follow the device clock.

**PostHog**

- `onb_screen_viewed {screen_id: "s5"}`
- `onb_hours_submitted {count, no_pattern: bool}`

### S6

**Underneath** · tap · ~9s · 1:20

**Job.** Name what usually sits under the urge, so Intercept starts in the right place.

**Earns its place.** Intercept’s second step is “name what’s underneath”. Asking now makes that step one tap at the worst moment, and it’s line two of the reflection.

**Layout.** Same structure as S5: back, Finish later, chapter bar, eyebrow, headline, body, six chips, privacy chip, primary.

**Interaction.** Multi-select. “Not sure” is exclusive. Continue disabled until one is picked.

**Data captured → pays off.** Feelings → S8 line two; Intercept preselects the first one and orders replacement actions to match; S15 mentions it.

**Copy**

| Key | String |
|---|---|
| Eyebrow | YOU |
| Headline | What’s usually underneath it? |
| Body | Pick what’s there most often. When an urge hits, Bedrock starts here. |
| Chips | Bored · Stressed · Lonely · Tired · Anxious · Not sure |
| Privacy | Stays on this iPhone |
| Primary | Continue |

**VoiceOver**

- Chips are toggle buttons.
- Not sure: “Not sure. Clears other choices.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in; chips Strata in. |
| select | Same as S5. Selection haptic. |

**Transition out.** Rise to S7.

**Reduce Motion.** As S5.

**Edge cases**

- Back: to S5 with selections intact.

**PostHog**

- `onb_screen_viewed {screen_id: "s6"}`
- `onb_underneath_submitted {count, not_sure: bool}`

### S7

**Your word** · tap · ~10s · 1:30

**Job.** Capture one word for who they are at their best.

**Earns its place.** The word is carved on S8, sits on every shield instead of a lecture, opens the letter in Strict Mode and heads Intercept. It’s the most reused answer in the product.

**Layout.** Back, Finish later, chapter bar. Eyebrow, Title headline, body. Six word chips plus a seventh, “My own word”, which reveals a single-line text field with helper text. Privacy chip. Primary.

**Interaction.** Single-select. My own word focuses the field and opens the keyboard; the primary moves above the keyboard. Field accepts one word, letters only, up to 14 characters, and is trimmed and lower-cased for display.

**Data captured → pays off.** The word → S8 carving and line three, the shield subtitle, the default letter in S13.1, the Intercept header, the Home stone.

**Copy**

| Key | String |
|---|---|
| Eyebrow | YOU |
| Headline | Who are you at your best? |
| Body | One word. You’ll see it whenever something’s blocked. |
| Chips | Steady · Present · Honest · Free · Kind · Focused · My own word |
| Field | One word |
| Helper | Anyone glancing at your phone could see it. |
| Error | One word, letters only. |
| Privacy | Stays on this iPhone |
| Primary | Continue |

**VoiceOver**

- Chips are radio buttons: “Steady, 1 of 7.”
- Field: “Your own word. One word, letters only.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in; chips Strata in. |
| select | The chosen word warms from ink to ember (Ember, 600ms). Selection haptic. |
| field | Field expands from the chip with a 0.35 / 0.85 spring. |

**Transition out.** Rise to S8.

**Reduce Motion.** Colour change only; field appears without expanding.

**Edge cases**

- Pasting a phrase: keeps the first word and shows the error until it’s one word.
- Non-Latin scripts allowed (letters in any script).
- Very long word at large text sizes: the carving on S8 scales down to fit the stone.

**PostHog**

- `onb_screen_viewed {screen_id: "s7"}`
- `onb_word_submitted {source: preset | custom}`

### S8

**Your stone** · hold · ~18s · 1:48

**Job.** Reflect their three answers back, let them set the first stone, and show that slips never take days away.

**Earns its place.** It’s where people feel seen without being told anything about themselves, and the only place Foundation, the real differentiator, gets shown before the paywall.

**Layout.** Back (hidden once set), Finish later, chapter bar (You). Eyebrow. Three serif lines (Title S). The stone, 176 × 266pt, centred, hovering at 45% opacity before it’s set. Caption. Hold control: an 84pt glass circle with a progress ring, label below. After setting: the hold control is replaced by text and the primary. Quiet crisis link at the bottom.

**Interaction.** Press and hold 1.4s to set. Releasing early drains the ring over 300ms. Two short taps show “Keep holding”; a third shows a plain “Set it” button. With VoiceOver on, double-tap sets it directly.

**Data captured → pays off.** Foundation day 1 begins now. The stone with their word becomes the Home hero.

**Copy**

| Key | String |
|---|---|
| Eyebrow | YOUR FOUNDATION |
| Line 1 | From S5: “Late at night.” · “Early in the morning.” · “In the middle of the day.” · “After work.” · “On weekends.” · “At no set time.” Two picked: “Late at night, and on weekends.” Three or more: “Late at night, and a few other times.” |
| Line 2 | From S6: “Usually when you’re tired.” Two: “Usually when you’re tired or stressed.” Three or more: “Usually when you’re tired, stressed, or lonely.” Not sure: “Even when you can’t say why.” |
| Line 3 | You want to be {word}. |
| Caption | This is your foundation. |
| Hold label | Hold to set your first stone |
| Tap hint | Keep holding |
| Fallback | Set it |
| After | It counts every day you build. A slip cracks the stone. It never takes a day away. |
| Stone | {WORD} · DAY 1 |
| Primary | Continue |
| Crisis link | If you’re really struggling, you’re not alone. |
| Crisis sheet | You don’t have to carry this alone. · If you’re in a dark place right now, talk to someone today. · Call or text 988 (Suicide & Crisis Lifeline, US) · Find a helpline in your country (findahelpline.com) · In immediate danger? Call your local emergency number. · Close |

**VoiceOver**

- The three lines read as one paragraph.
- Hold control: “Set your first stone. Double-tap to set.”
- After setting: “Stone set. Day one.”
- Crisis link: “Support resources. Opens a sheet.”

**Motion and haptics**

| When | What |
|---|---|
| 0–1.4s | Lines rise 10pt and fade in, 450ms apart. The stone hovers at 45% opacity. |
| hold | Ring fills over 1.4s. Core Haptics HoldRamp: continuous, intensity 0.2 → 0.8, sharpness 0.3 → 0.6. |
| set | Lock: the stone drops 14pt and settles with a 4pt overshoot (0.28 / 0.9). Heavy transient 1.0 / 0.4, success notification 80ms later. |
| +300ms | Carve: {WORD} appears letter by letter, 100ms apart, each glowing ember then cooling to an engraving over 900ms. |
| +1.4s | “DAY 1” fades in. A hairline crack draws across the base (600ms) and fills with ember: the repair. The day count doesn’t move. |
| +2.6s | Text and Continue Settle in. |

**Transition out.** Rise to S9. The horizon dims half a step on S9: the door is the story’s low point.

**Reduce Motion.** Ring still fills (it’s feedback, not decoration). The stone appears set; the word fades in whole; the crack is a still image.

**Edge cases**

- Crisis sheet is region-aware: 988 shows only where it works (US: Suicide & Crisis Lifeline; Canada: Suicide Crisis Helpline). Elsewhere the first row is Find a helpline in your country.
- Back before setting returns to S7; after setting, back is hidden.
- Accessibility text sizes: lines wrap, the stone shrinks to 132 × 200pt, the content scrolls.
- Crack test (A/B): variant B shows the repair on a small example stone instead of theirs.

**PostHog**

- `onb_screen_viewed {screen_id: "s8"}`
- `onb_stone_set {method: hold | tap_fallback | voiceover, attempts}`
- `onb_crisis_opened {screen_id: "s8"}`

---

## Lock

_The door, what 2am faces, who holds the key_

### S9

**The door** · watch · ~12s · 2:00

**Job.** Tell the honest truth: today, the free wall can be switched off in about ten seconds.

**Earns its place.** It’s the reason Strict Mode exists, said before we ask for anything. Owning our own weakness first is what makes the cynic trust the next two screens.

**Layout.** Back, Finish later, chapter bar (Lock). Eyebrow, Title headline, body. An illustration card in Bedrock’s own style (not a copy of iOS): a settings-style row reading “Screen Time access · Bedrock” with a switch, and a miniature of their wall behind it. Caption under the card. Primary.

**Interaction.** Nothing to do but read and continue. The illustration plays twice and then rests in its off state.

**Data captured → pays off.** None. This screen exists so S12’s headline, “Remove the door.”, needs no explanation.

**Copy**

| Key | String |
|---|---|
| Eyebrow | ONE HONEST THING |
| Headline | Right now, this wall has a door. |
| Body | Anyone holding this phone can switch Bedrock off in Settings in about ten seconds. That’s why most blockers don’t last. |
| Caption | The free wall, today |
| Primary | Close the door |

**VoiceOver**

- Illustration: “A Screen Time switch for Bedrock being turned off, and the wall disappearing.”
- Primary: “Close the door. Shows Strict Mode.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. Horizon dims half a Dawn step: the low point of the story. |
| 600ms | A soft touch dot appears on the switch. |
| 900ms | The switch slides off (220ms ease-in-out). The wall miniature dims to 30% and its top course slips down 6pt. No haptic: this is a warning, not an event. |
| 4.0s | Resets and plays once more, then rests in the off state. |

**Transition out.** Rise to S10. The horizon recovers its step.

**Reduce Motion.** A static two-panel illustration, on then off, side by side.

**Edge cases**

- Shown on every iOS version: the free wall’s door exists everywhere.
- Strict Mode not verified on this iOS: still shown; S11 carries the version banner.

**PostHog**

- `onb_screen_viewed {screen_id: "s9"}`
- `onb_action {screen_id: "s9", action: "close_door"}`

### S10

**What 2am you will face** · tap · ~20s · 2:20

**Job.** Show, step by step, the road Strict Mode puts where the door was.

**Earns its place.** This is where the single belief forms: “this one I can’t undo in a weak moment.” Claiming it would be easy; showing the road is what no competitor does.

**Layout.** Back, Finish later, chapter bar (Lock). Eyebrow, Title headline with a second italic line in ember. A vertical path of six steps, each a tappable row. Footer: the honest line in serif and a “What it can’t stop” link. Primary.

**Interaction.** The path plays once on arrival. Tapping any step expands its detail in place (one open at a time). The link opens the limits sheet.

**Data captured → pays off.** Which steps they open, as a count. Tells us whether people read the road or skim it.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE |
| Headline | Here’s what turning it off takes. |
| Headline 2 | At 2am. |
| Step 1 | Read the letter you write today · You write it during setup. It stays on screen before you can go on. |
| Step 2 | Breathe, then rate the urge · A slow breath first. Urges tend to rise, peak and pass. |
| Step 3 | Type your commitment, word for word · Pasting is blocked. One typo starts it over. |
| Step 4 | Your person hears about it · If someone holds your key, they’re told you’re asking. |
| Step 5 | Wait thirty minutes · Leave the app and the clock restarts. |
| Step 6 | Only then does it open · Your person approves, or Bedrock releases the code. Try again the same night and it takes longer. |
| Footer | Not impossible to undo. Just impossible to undo at 2am. |
| Link | What it can’t stop |
| Primary | Choose who holds the key |
| Limits sheet | What Strict Mode can’t stop · Erasing this iPhone. That removes everything, Bedrock included. · Anyone who knows your Screen Time passcode. · Other phones, tablets and computers. · Versions of iOS where the lock isn’t reliable. Bedrock tells you if yours is one. · Better you hear it now than at 2am. · Got it |

**VoiceOver**

- Steps are a list: “Step 5 of 6. Wait thirty minutes. Button, shows details.”
- The travelling light is decorative and hidden.
- Limits sheet opens with focus on its title.

**Motion and haptics**

| When | What |
|---|---|
| 0.6–4.6s | An ember light travels down the path, one step per second; each node flares and cools, its label rises from 40% to full. Selection haptic per node. |
| 4.6–6.8s | The light holds at step 5 while a ring closes around it and 30:00 shows. The longest beat on purpose. |
| 7.2s | Light reaches step 6. Medium impact. |
| 0.9s | The primary Settles in while the path keeps playing (Phase 7: no waiting for the button). |
| 7.6s | Footer and link fade up. |
| tap | Step detail expands (0.35 / 0.85), selection haptic. |

**Transition out.** Rise to S11.

**Reduce Motion.** All six steps shown lit, no travelling light; the ring is a still image.

**Edge cases**

- The 30-minute wait is the gauntlet’s server-validated cooldown; offline it counts on system uptime. Changing the date or time doesn’t skip it.
- Revisited via back: the path shows lit immediately, no replay.
- Exact gauntlet timings live in the built gauntlet; only the 30 minutes is stated here because the product commits to it.

**PostHog**

- `onb_screen_viewed {screen_id: "s10"}`
- `onb_gauntlet_step_opened {step}`
- `onb_limits_opened`

### S11

**Who holds the key** · tap · ~10s · 2:30

**Job.** Choose who decides when the lock opens: Bedrock’s steps alone, or a person they trust as well.

**Earns its place.** The paywall’s wording and the whole setup path depend on it, and choosing makes the purchase feel like a decision rather than a pitch.

**Layout.** Back, Finish later, chapter bar (Lock). Eyebrow, Title headline, body. Two large option cards stacked, each with title, body and a small tag. A text link below. Primary. Version banner at the top when Strict Mode isn’t verified on this iOS.

**Interaction.** Single choice, nothing preselected. Continue is disabled until one is chosen. The link opens a sheet.

**Data captured → pays off.** Key holder → S12 subtitle and third outcome, S13 path (B or P), the Sealed copy.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE |
| Headline | Who should hold the key? |
| Body | Strict Mode locks Screen Time with a passcode you won’t know. Someone has to decide when it opens. |
| Option A | Bedrock keeps it · You type a code you never see whole. It’s released only after the steps. · Works tonight, on your own |
| Option B | Someone I trust · Bedrock holds the code. They approve any way out and see whether the wall is up, never what you browse. · Works tonight, wherever they are |
| Link | I already have a Screen Time passcode |
| Primary | Continue |
| Sheet | You already have one · Then you know it, and so would the 2am you. During setup you’ll change it to one you don’t know, using your current code once. · Got it |
| Version banner | Strict Mode needs a newer version of iOS on this iPhone. Your free wall works now. |

**VoiceOver**

- Options are radio buttons: “Bedrock keeps it, 1 of 2.” Their body and tag are read as the hint.
- Banner is read first when present.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in; cards Strata in, 60ms apart. |
| select | Card border turns ember, title warms (Ember 600ms), card Settles 0.98 → 1. Selection haptic. |

**Transition out.** Rise to S12, or S12U when Strict Mode isn’t verified.

**Reduce Motion.** Colour change only.

**Edge cases**

- Back to S10 keeps the choice.
- If they bought before (restore), S11 still asks: the key choice is per phone.
- The version check is remote-configured per iOS build from the lock-test results, never hard-coded.

**PostHog**

- `onb_screen_viewed {screen_id: "s11", strict_supported}`
- `onb_key_holder_selected {holder: bedrock | partner}`
- `onb_existing_passcode_info_opened`

---

## Paywall

_Remove the door, the version gate, Sign in with Apple_

### S12

**Remove the door** · read · ~25s · reached 2:30

**Job.** Offer Strict Mode at the moment of highest belief, with the free wall always one tap away.

**Earns its place.** It’s the business. It also completes the story S9 started; without it the door is left open with no offer to close it.

**Layout.** Dawn at first light (strongest horizon). Close button top-right (44pt glass circle). Eyebrow, Title headline, one-line subhead. Four outcome rows with ember glyphs. Two plan cards side by side (Yearly selected), “Other plans” link. Trial timeline under the cards when eligible and Yearly is selected. Primary CTA, one line of reassurance, “Keep the free wall” as a full-width text button. Trust line. Late-night block when it applies. Legal footer, then Restore · Terms · Privacy, then the crisis link. Scrolls when needed; the CTA area does not float over legal text.

**Interaction.** Selecting a plan updates the CTA, the timeline and the legal text. Close and Keep the free wall do the same thing. Restore runs AppStore.sync(). The late-night block appears between 22:00 and 04:59 local time.

**Data captured → pays off.** Plan and outcome → entitlement “pro” via RevenueCat → S13. Free choice → S14. Late-night reminder → a local notification at 12:00 the next day that opens S12.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE |
| Headline | Remove the door. |
| Subhead A | Bedrock keeps the key. You keep the wall. |
| Subhead B | Your person keeps the key. You keep the wall. |
| Outcome 1 | Turning Bedrock off goes through your steps, not a switch. |
| Outcome 2 | Bedrock can’t be deleted on a whim. |
| Outcome 3 A | The code stays sealed until the steps are done. |
| Outcome 3 B | Your person approves any way out. |
| Outcome 4 | See your hardest hours coming. |
| Yearly card | Yearly · $69.99 a year · 3 days free, then $5.83 a month, billed yearly · tag: 3 days free |
| Yearly, no trial | Yearly · $69.99 a year · $5.83 a month, billed yearly |
| Lifetime card | Lifetime · $149 · Pay once. Keep it for good. · tag: Your last blocker |
| Link | Other plans |
| Timeline | Today · Strict Mode goes on / In 2 days · We send a reminder / In 3 days · $69.99 for the year, unless you cancel |
| CTA | Start 3 days free · Continue · $69.99 a year · Pay $149 once · Continue · $5.99 a week |
| Under CTA | Cancel anytime. If you do, your steps still open the lock. |
| Statement line | Your bank statement shows Apple. |
| Free path | Keep the free wall |
| Trust line | No account · No ad tracking · Your answers stay on this iPhone |
| Late night | It’s late. You don’t have to decide tonight. · Remind me tomorrow at noon |
| Toast | We’ll remind you tomorrow at noon. |
| Legal, trial | 3 days free, then $69.99 a year. Renews automatically unless cancelled at least 24 hours before the trial or current period ends. Manage or cancel in Settings › your name › Subscriptions. Payment is charged to your Apple Account. |
| Legal, lifetime | One-time purchase of $149. No subscription, nothing renews. |
| Legal, weekly | $5.99 a week. Renews automatically unless cancelled at least 24 hours before the current period ends. Manage or cancel in Settings › your name › Subscriptions. |
| Links | Restore purchases · Terms · Privacy |
| Other plans sheet | Other plans · Weekly · $5.99 a week · Renews weekly until you cancel. · Choose weekly · Close |
| Weekly, selected | Weekly · $5.99 a week (a selected row under the two cards; both cards show unselected) |
| Errors | That didn’t go through. You haven’t been charged. (Try again) · Waiting for approval. Your free wall stays on meanwhile. · Can’t reach the App Store right now. Your free wall stays on. · No purchases found for this Apple Account. · Restored. Welcome back. |
| Success | You’re in. |

**VoiceOver**

- Close: “Keep the free wall.”
- Plan cards are radio buttons: “Yearly, $69.99 a year, 3 days free, selected.”
- Timeline is read as one sentence.
- Legal text stays at full contrast and is never truncated.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. Dawn reaches first light: the horizon blooms over 900ms (the screen’s hero). |
| 100ms | Outcome rows Strata in, 40ms apart. |
| select | Plan card border to ember, selection haptic. CTA label crossfades 160ms. |
| purchase | App Store sheet. On success: success notification, “You’re in.” Carves in and holds 1.2s. |
| never | Prices, legal text and the close button never animate. |

**Transition out.** Purchase: Rise to SIWA. Free: Rise to S14. Remind me: toast, then S14.

**Reduce Motion.** Horizon appears at full strength; rows appear together.

**Edge cases**

- Accessibility text sizes: the two plan cards stack, Yearly first; the timeline wraps under them; the CTA, reassurance and Keep the free wall stay together and full width.
- Phase 7: if the plan ends while Strict Mode is on, the lock stays and the steps still release the code. The code is never held for payment, and S12 says so under the button.
- 3.1.2: price and period on every plan; trial length and post-trial price shown only when eligible; auto-renew disclosure next to the CTA area; Restore, Terms and Privacy present; close visible from the first frame.
- Trial eligibility comes from StoreKit (isEligibleForIntroOffer) via RevenueCat; ineligible users never see trial copy or the timeline.
- Prices come from StoreKit localized strings, never hard-coded; the per-month figure is computed from the local price.
- Ask to Buy or Strong Customer Authentication: pending copy, free wall stays on.
- Returning subscriber: Restore finds it, skips to S13 if not sealed on this phone.

**PostHog**

- `onb_paywall_viewed {variant: standard | late_night | no_trial | unsupported, holder, trial_eligible}`
- `onb_plan_selected {plan: yearly | lifetime | weekly}`
- `onb_other_plans_opened`
- `onb_purchase_started {plan}`
- `onb_purchase_result {result: success | cancelled | failed | pending, plan, trial}`
- `onb_restore_result {found}`
- `onb_free_path {via: button | close}`
- `onb_decide_tomorrow`

### S12U

**Not ready on this iPhone** · read · ~10s · branch

**Job.** Be honest that Strict Mode can’t lock reliably on this iOS version, and sell nothing that doesn’t work.

**Earns its place.** Selling a lock that a known bug can bypass would be the one thing a cynic never forgives, and a review risk.

**Layout.** Same frame as S12 without plans, prices or timeline. Eyebrow, headline, body, primary, secondary.

**Interaction.** Remind me after I update sets a flag; when Bedrock opens on a verified version, Home shows a card that opens S12. Keep the free wall goes to S14.

**Data captured → pays off.** Flag “strict_waiting_for_update”.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE |
| Headline | Strict Mode isn’t ready on this iPhone yet. |
| Body | It needs a newer iOS to lock reliably. Update in Settings › General › Software Update. Your free wall works now. |
| Primary | Remind me after I update |
| Secondary | Keep the free wall |
| Home card later | Your iPhone is ready for Strict Mode. |

**VoiceOver**

- Standard order: headline, body, buttons.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. Dawn at first light, as S12. |

**Transition out.** Rise to S14.

**Reduce Motion.** Fade.

**Edge cases**

- Verified versions come from remote config, updated from the lock test, never hard-coded.

**PostHog**

- `onb_paywall_viewed {variant: "unsupported"}`
- `onb_action {screen_id: "s12u", action: "remind_after_update" | "keep_free"}`

### SIWA

**Keep it if you change phones** · tap · ~6s · after purchase

**Job.** Offer Sign in with Apple once, after purchase, so the plan and settings can follow them.

**Earns its place.** Without it, a new phone means starting over, including Foundation days. Placed after purchase, it never stands between anyone and value.

**Layout.** Eyebrow, Title headline, body. The system Sign in with Apple button (white style), a Not now text button.

**Interaction.** ASAuthorizationAppleIDButton. Not now skips with no reminder during onboarding.

**Data captured → pays off.** Apple ID credential (opaque user identifier only; no email requested) → server account linked to the device ID for sync.

**Copy**

| Key | String |
|---|---|
| Eyebrow | YOU’RE IN |
| Headline | Keep it if you change phones. |
| Body | Sign in with Apple to bring your plan to a new iPhone. Your answers stay on this one. |
| Primary | Sign in with Apple (system button) |
| Secondary | Not now |

**VoiceOver**

- System button provides its own label.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. No hero: this is a quiet utility moment. |

**Transition out.** Rise to S13.

**Reduce Motion.** Fade.

**Edge cases**

- Sign-in cancelled or failed: continue to S13 silently.
- Sync carries the plan, Foundation days and settings. Never the answers, the word or the letter: “Your answers stay on this iPhone” on S12 stays true. A new iPhone asks for the word and letter again.
- Signing in creates an account; the built Settings › Delete account covers App Review 5.1.1(v). Deleting it keeps the free wall and this phone’s Strict Mode.

**PostHog**

- `onb_siwa_result {result: success | cancelled | skipped | error}`

---

## Begin

_Strict Mode setup, heads-ups, one practice breath, Home_

### S13.1

**Write the letter** · type · ~60s · setup

**Job.** Have them write the first thing they’ll read if they ever try to turn Strict Mode off.

**Earns its place.** The gauntlet opens with this letter. Written by the person who wants the lock, it does more at 2am than anything we could write.

**Layout.** Chapter bar (Begin, Strict Mode sub-steps 1 of 3). Eyebrow, Title headline, body. A tall text area on a raised surface, three starter chips above it, a helper line under it. Privacy note. Primary and secondary.

**Interaction.** Starter chips insert their text at the cursor. Save is enabled at 40 characters. “Use a short one for now” fills a default letter using their word, which they can edit later in Settings.

**Data captured → pays off.** Letter text, on device → gauntlet step 1.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE · 1 OF 3 |
| Headline | Write to the you who’ll want out. |
| Body | You’ll read it first if you ever try to turn Strict Mode off. Write it while you mean it. |
| Placeholder | You’re reading this because… |
| Starters | Remember why you started. · Tomorrow you’ll be glad you waited. · Call someone before you decide. |
| Helper | At least 40 characters. |
| Privacy | Stays on this iPhone. |
| Primary | Save the letter |
| Secondary | Use a short one for now |
| Default letter | You set this up because you want to be {word}. Read this slowly. The urge will pass. You don’t have to act on it. |

**VoiceOver**

- Text area: “Your letter. At least 40 characters.”
- Starters: “Insert: Remember why you started.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. Keyboard appears on focus; the primary rides above it. |
| save | Light impact. The text area folds into a sealed envelope glyph (300ms) before moving on. |

**Transition out.** Rise to S13.2B or S13.2P, by key holder.

**Reduce Motion.** No fold; fade.

**Edge cases**

- Leaving mid-letter: draft kept on device.
- Purchased but quit before setup: Home shows “Finish Strict Mode setup”.

**PostHog**

- `onb_strict_setup_started {holder}`
- `onb_letter_saved {length_bucket: 40-99 | 100-299 | 300+, default_used: bool}`

### S13.2B

**How blind entry works** · read · ~15s · setup

**Job.** Explain the three steps and the one rule (skip recovery) before anything happens.

**Earns its place.** Blind entry fails if the person skips a step or panics halfway. Knowing the shape first is the cheapest insurance there is.

**Layout.** Eyebrow, Title headline. Three numbered steps with small illustrations. A note card. Primary and secondary.

**Interaction.** Practice first is the default; “I’ve done this before” skips the practice.

**Data captured → pays off.** None.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE · 2 OF 3 |
| Headline | You’ll type a code you never see whole. |
| Step 1 | Bedrock shows one digit at a time in a small window over Settings. |
| Step 2 | You type each digit into Screen Time, then all four again to confirm. |
| Step 3 | When iOS offers passcode recovery, skip it. That’s what keeps the code from you. |
| Note | About three minutes. Seeing one digit at a time makes remembering the code unlikely, not impossible. A digit typed wrong twice becomes the code, so you’ll practice first and check at the end. |
| Primary | Practice first |
| Secondary | I’ve done this before |

**VoiceOver**

- Steps are a numbered list.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in; steps Strata in, 60ms apart. |

**Transition out.** Rise to S13.3B or S13.4B.

**Reduce Motion.** Steps appear together.

**Edge cases**

- VoiceOver users: the floating window also speaks each digit once, quietly, through VoiceOver.

**PostHog**

- `onb_screen_viewed {screen_id: "s13_2b"}`
- `onb_action {action: "practice" | "skip_practice"}`

### S13.3B

**Practice run** · tap · ~40s · setup

**Job.** Rehearse with a dummy code inside Bedrock so the real run can’t surprise them.

**Earns its place.** The worst failure in the product is a digit typed wrong twice. A rehearsal is the main defence.

**Layout.** Headline. A mock floating window (Bedrock’s own design, labelled practice) showing one large digit with a progress ring. Below it a Bedrock keypad (our style, not an iOS copy). Progress text.

**Interaction.** Each digit shows for 3 seconds or until typed. Four digits, then the same four again. Wrong digit: gentle shake, retype. Done: success state.

**Data captured → pays off.** Practice errors count (helps us tune digit timing).

**Copy**

| Key | String |
|---|---|
| Headline | Practice run. This code isn’t real. |
| Window | Type · {digit} · Digit {n} of 4 |
| Confirm phase | Again · {digit} |
| Wrong | That’s a different digit. Try again. |
| Done headline | That’s all it is. |
| Primary | Do the real one |

**VoiceOver**

- Each digit is announced: “Type 7. Digit 2 of 4.”
- Keypad keys are buttons labelled with their number.

**Motion and haptics**

| When | What |
|---|---|
| digit | Digit fades in 120ms; ring sweeps 3s. |
| typed | Selection haptic, digit slides away left 160ms. |
| wrong | Field shakes 3 times over 300ms. Rigid impact 0.5. |
| done | Lock glyph Settles; success notification. |

**Transition out.** Rise to S13.4B.

**Reduce Motion.** No slide or shake; colour feedback only.

**Edge cases**

- Three wrong digits in practice: offer to slow the window to 5 seconds per digit for the real run.

**PostHog**

- `onb_practice_completed {errors}`

### S13.4B

**The real run** · guided · ~90s · setup

**Job.** Guide them through Settings while the floating window shows the real digits one at a time.

**Earns its place.** This is the lock itself. Everything before it was preparation.

**Layout.** Headline, body, a numbered checklist with expected iOS labels in bold, a small note that labels can vary. Primary. While they’re in Settings, the floating window stays on top.

**Interaction.** Open Settings opens Bedrock’s page in Settings (deep links into Screen Time aren’t allowed), starts the floating window, and begins the digit sequence when Screen Time’s passcode screen is likely open (after the user taps the window once to start). Returning to Bedrock opens S13.5A.

**Data captured → pays off.** Bedrock-held code, generated and escrowed for the gauntlet, never shown whole.

**Copy**

| Key | String |
|---|---|
| Headline | Now the real one. |
| Body | Leave this open. Bedrock’s window stays on top while you’re in Settings. |
| Step 1 | Go back to the main Settings list. |
| Step 2 | Open Screen Time. |
| Step 3 | Tap Lock Screen Time Settings. Already have a passcode? Tap Change Screen Time Passcode and type your current one first. |
| Step 4 | Tap the floating window to start, then type each digit it shows. |
| Step 5 | Type all four again when iOS asks. |
| Step 6 | If iOS asks about passcode recovery, tap Cancel. |
| Step 7 | Come back to Bedrock. |
| Note | Labels may differ slightly between iOS versions. |
| Primary | Open Settings |
| Window start | Tap to start |
| Window | Type · {digit} · {n} of 4 |
| Window confirm | Again · {digit} |
| Window end | Done. Head back to Bedrock. |
| Window, recording | Stop screen recording to continue. |

**VoiceOver**

- Checklist is a numbered list.
- Floating window digits are announced by VoiceOver.

**Motion and haptics**

| When | What |
|---|---|
| window | Each digit fades in 120ms, ring sweeps its duration, fades out 120ms. No haptics outside Bedrock. |

**Transition out.** Return to Bedrock: Rise to S13.5A.

**Reduce Motion.** No ring sweep; a static “n of 4” label.

**Edge cases**

- Picture in Picture disabled by the user: fall back to switching apps with each digit shown in Bedrock for 3 seconds, then “Switch to Settings”.
- The code is written to the Keychain before the first digit shows and is never replaced until S13.5A passes or fails. Leaving Settings halfway pauses the window; coming back resumes the same code from digit 1. A fresh code is only made on S13.7B.
- Screen recording or mirroring is on (the screen reports it is captured): the window pauses and shows “Stop screen recording to continue.” Screenshots can’t be blocked; each shows a single digit.
- Already had a passcode: Step 3 variant; their old code is replaced.

**PostHog**

- `onb_blind_entry_started`
- `onb_blind_entry_window {step: started | digit_n | confirm_n | finished}`
- `onb_blind_entry_returned`

### S13.5A

**Check the code** · tap · ~30s · setup

**Job.** Confirm the passcode iOS saved is the one Bedrock holds, before sealing.

**Earns its place.** If a digit went in wrong twice, this is the last moment it can be caught while it’s still fixable with help.

**Layout.** Eyebrow (3 of 3), Title headline, body, primary, secondary. The floating window shows the digits again, one at a time.

**Interaction.** They open Change Screen Time Passcode and type the digits from the window. If iOS accepts the current code, they tap Cancel there and report back.

**Data captured → pays off.** Match confirmed → S13.5B.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE · 3 OF 3 |
| Headline | First, check the code works. |
| Body | In Screen Time, tap Change Screen Time Passcode and type the digits from the window. If iOS accepts them, tap Cancel. |
| Primary | iOS accepted it |
| Secondary | It didn’t accept it |

**VoiceOver**

- Primary hint: “Confirms the passcode matches.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. |
| accepted | Light impact. |

**Transition out.** Accepted: Rise to S13.5B. Not accepted: S13.7A.

**Reduce Motion.** Fade.

**Edge cases**

- Bedrock can’t detect a passcode or its value; this check is the user’s report, by design.

**PostHog**

- `onb_code_check {result: accepted | rejected}`

### S13.5B

**Try to switch it off** · tap · ~30s · setup

**Job.** Have them try the ten-second door themselves and see it’s closed.

**Earns its place.** This closes the loop on S9. Seeing the passcode prompt with their own eyes is the proof the paywall promised.

**Layout.** Title headline, body, primary, secondary, “I got stuck” link.

**Interaction.** They go to Apps with Screen Time Access and try to turn Bedrock off. On return, Bedrock also checks its authorisation status as a backstop.

**Data captured → pays off.** Lock confirmed → S13.6.

**Copy**

| Key | String |
|---|---|
| Headline | Now try to switch it off. |
| Body | In Screen Time › Apps with Screen Time Access, try turning Bedrock off. It should ask for a passcode you don’t know. |
| Primary | It asked for a passcode |
| Secondary | It switched off |
| Link | I got stuck |
| Stuck sheet | Lost your place? Run it again with a fresh code. · iOS didn’t ask about recovery? That’s fine on some versions. · Paid and it still won’t lock? Apple handles refunds at reportaproblem.apple.com. · Something else? Write to us at help@thebedrock.app. · Close |

**VoiceOver**

- Standard order.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. |

**Transition out.** Asked: Rise to S13.6. Switched off: S13.7B.

**Reduce Motion.** Fade.

**Edge cases**

- Authorisation found revoked on return regardless of answer: S13.7B with a re-grant step first.

**PostHog**

- `onb_lock_check {result: asked | switched_off}`

### S13.6

**Sealed** · watch · ~6s · setup

**Job.** Mark the moment the lock is real.

**Earns its place.** The emotional close of the purchase. Without a clear moment, “setup” just fades into Home.

**Layout.** The wall from S3 returns at centre with a keystone hovering above it. Eyebrow, Display headline, body, primary.

**Interaction.** Continue only.

**Data captured → pays off.** Strict Mode on: uninstall lock (denyAppRemoval) set, passcode held (Bedrock or person), gauntlet armed.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE |
| Headline | Sealed. |
| Body A | Strict Mode is on, and Bedrock holds the key. If you ever want out, your steps and your letter are waiting. |
| Body B | Strict Mode is on, and your person holds the key. If you ever want out, they’ll hear from you first. |
| Primary | Continue |

**VoiceOver**

- Announces “Sealed. Strict Mode is on.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Wall present. Keystone drops 40pt into the top course: Lock (0.28 / 0.9). Heavy impact, success notification 80ms later. |
| +200ms | “Sealed.” Carves in, warms to ember (Ember). Horizon rises a Dawn step. |

**Transition out.** Rise to S14.

**Reduce Motion.** Keystone appears in place; headline fades in.

**Edge cases**

- Partner mode completed later from Home: same screen, then back to Home.

**PostHog**

- `onb_strict_sealed {holder}`

### S13.7A

**The code didn’t match** · tap · ~20s · setup

**Job.** Recover calmly when iOS didn’t accept Bedrock’s code.

**Earns its place.** The highest-stakes failure in the product deserves its own screen, not an error toast.

**Layout.** Headline, body, primary, secondary.

**Interaction.** Show the digits again re-runs the window over Change Screen Time Passcode, more slowly (5 seconds per digit). Get help opens an email draft to support with a reference number.

**Data captured → pays off.** Retry count.

**Copy**

| Key | String |
|---|---|
| Headline | The code didn’t match. |
| Body | A digit probably went in wrong twice. Bedrock will show the digits again, slower. |
| Primary | Show the digits again |
| Secondary | Get help |

**VoiceOver**

- Standard order.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. No haptic. |

**Transition out.** Back to S13.5A.

**Reduce Motion.** Fade.

**Edge cases**

- Still no match after two slow tries: Get help is promoted to primary. The honest worst case, that only erasing the iPhone removes an unknown passcode with no recovery account, is written in the help article, not here.

**PostHog**

- `onb_code_mismatch {attempt}`

### S13.7B

**The lock didn’t save** · tap · ~10s · setup

**Job.** Recover when Bedrock could still be switched off.

**Earns its place.** Without it, someone could leave setup believing they’re protected when they aren’t.

**Layout.** Headline, body, primary.

**Interaction.** Run it again re-requests Screen Time access if it was revoked, generates a fresh code and returns to S13.4B.

**Data captured → pays off.** Retry count.

**Copy**

| Key | String |
|---|---|
| Headline | The lock didn’t save. |
| Body | No harm done. Turn Bedrock’s access back on and run it again with a fresh code. |
| Primary | Run it again |

**VoiceOver**

- Standard order.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. No haptic. |

**Transition out.** Rise to S13.4B (after the Screen Time sheet if needed).

**Reduce Motion.** Fade.

**Edge cases**

- Device on an unverified iOS that slipped through: show S12U copy instead.

**PostHog**

- `onb_lock_not_saved {attempt}`

### S13.2P

**Invite your person** · tap · ~20s · setup

**Job.** Send the invite and set honest expectations about what the person sees.

**Earns its place.** Partner-held only works if the right person joins, knowing exactly what they’re signing up for.

**Layout.** Eyebrow, Title headline, body. A raised card with the invite code in mono and the link. A note in a bordered box. Primary and secondary.

**Interaction.** Send the invite opens the share sheet with a prewritten message. Copy link copies and confirms with a toast.

**Data captured → pays off.** Invite code (server-side pairing token, no personal data) → supporter flow SP1.

**Copy**

| Key | String |
|---|---|
| Eyebrow | STRICT MODE · YOUR PERSON |
| Headline | Invite your person. |
| Body | They’ll see whether your wall is up and approve any way out. Never what you browse, block or write. |
| Card | Invite code · 7K2Q-M9 · thebedrock.app/join/7K2Q |
| Note | If they don’t answer a request within 3 days, Bedrock opens it and tells them. Nobody gets stuck. |
| Primary | Send the invite |
| Secondary | Copy link |
| Toast | Link copied. |
| Share message | I’m using Bedrock and I’d like you to be my support person. You’d see whether my wall is up, and okay it if I ask to turn it off. Join here: thebedrock.app/join/7K2Q |

**VoiceOver**

- Code is read character by character.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. |
| sent | Light impact on return from the share sheet. |

**Transition out.** Rise to S13.2B: the same blind entry as Bedrock-held. Until they accept, the steps work on their own.

**Reduce Motion.** Fade.

**Edge cases**

- Invite never accepted: Home card “Waiting for your person” with resend after 24 hours.
- Phase 7: the person no longer sets the passcode in person (old S13.3P and S13.4P are gone). Bedrock holds the code by blind entry; the person approves release. A request they don’t answer within 3 days opens and they’re told, so a lost or controlling key holder can’t trap anyone, and no one is left with erasing the iPhone as the only exit. This changes the already-built Partner-held model (brief 2.4): confirm before building.

**PostHog**

- `onb_partner_invite {action: shared | copied}`

### S14

**Quiet heads-ups** · tap · ~8s · after paywall

**Job.** Ask for notifications at the moment they make sense, showing exactly how discreet they look.

**Earns its place.** Heads-ups are how S5 pays off. Showing the lock-screen preview answers the exposure fear before iOS asks.

**Layout.** Chapter bar (Begin). Eyebrow, Title headline, body. A lock-screen notification preview card (Bedrock styled, with the real app icon). Caption. One primary button.

**Interaction.** One button, which triggers the iOS request (HIG). Either answer continues.

**Data captured → pays off.** Notification permission → heads-ups scheduled from S5, trial reminder, “decide tomorrow” reminder.

**Copy**

| Key | String |
|---|---|
| Eyebrow | BEGIN |
| Headline | Want a quiet heads-up before your hard hours? |
| Body | A few minutes ahead of them. Here’s how it looks on your lock screen. |
| Body, no pattern | Once they show up. Here’s how it looks on your lock screen. |
| Preview | Bedrock · now · A good moment to plan the next hour. (The lock-screen time in the preview is a few minutes before their first S5 window: the S5 payoff.) |
| Caption | Nothing on it says what Bedrock is for. |
| Primary | Continue |

**VoiceOver**

- Preview: “Example notification: A good moment to plan the next hour.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. |
| 200ms | Preview card drops 24pt into place (Settle). Soft impact. |

**Transition out.** After the iOS answer: Rise to S15.

**Reduce Motion.** Preview fades in.

**Edge cases**

- Already granted (from the late-night reminder): skip S14.
- Denied: nothing changes in the flow; Home offers it later only if they open the heads-up card.

**PostHog**

- `onb_notif_prompted`
- `onb_notif_result {granted: bool}`

### S15

**Press it once** · hold · ~15s · final

**Job.** Rehearse Intercept once, so the real moment isn’t its first use.

**Earns its place.** Every promise ends here: the button exists, they’ve used it, and it starts from their own answer.

**Layout.** Eyebrow, Title headline, body. A 168pt circular ember-glass button in the centre labelled “The urge is here”. After pressing: a breathing ring replaces it, then a closing line and the primary.

**Interaction.** Tap starts a short rehearsal: breathe in 4 seconds, out 4 seconds, then the closing line. Real Intercept continues further; this stops after one breath.

**Data captured → pays off.** Uses S6 (first feeling) in the closing line; S7 word appears on Home.

**Copy**

| Key | String |
|---|---|
| Eyebrow | BEGIN |
| Headline | One last thing. Press it once. |
| Body | Your button for when the urge is here. Press it now, so the real time isn’t the first. |
| Button | The urge is here |
| Breathe | Breathe in… · …and out. |
| Closing | That’s how it starts. Next time it carries on, starting with what’s underneath. |
| Primary | Go to my wall |

**VoiceOver**

- Button: “The urge is here. Starts a one-breath practice.”
- Breath phases are announced.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. The button Breathes (1.0 ↔ 1.02, 4s cycle). |
| press | Medium impact. Button expands into the ring (0.5 / 0.85). |
| breath | Ring grows 4s ease-in-out, shrinks 4s. Soft transient 0.25 at each phase change. |
| done | Closing line fades in; primary Settles. |

**Transition out.** Rise to Home; Dawn reaches full daylight over 1.2s.

**Reduce Motion.** No Breath loop; the ring is replaced by a counted “in · out” label.

**Edge cases**

- Skipping: no skip control; the rehearsal is 8 seconds and the button is the only way forward. VoiceOver users can double-tap through.

**PostHog**

- `onb_intercept_rehearsed`
- `onb_completed {path: pro | free | no_wall, strict_sealed: bool, total_ms}`

### Home

**Day 1. The wall is standing.** · watch · — · end

**Job.** Close the story at dawn and show every promise already kept.

**Earns its place.** It’s the final screen of onboarding and the first screen of the product. It has to feel like the same world.

**Layout.** Full daylight horizon. Top: date and a status chip. Centre: their stone with {WORD} and “DAY 1”. Below: the Intercept button, full width. Then up to two cards. First appearance only: the headline line above the stone.

**Interaction.** Cards are dismissible, except Finish setting up. Intercept opens the full flow. On the free wall, the status chip is a button that opens S10, then S12: a permanent, quiet way back to Strict Mode, never a pop-up.

**Data captured → pays off.** Everything from onboarding, now live.

**Copy**

| Key | String |
|---|---|
| First headline | Day 1. The wall is standing. |
| Headline, no wall | Day 1. |
| Status, Pro | Wall up · Strict Mode on |
| Status, free | Wall up · Strict Mode off |
| Status, no wall | Wall not up |
| Intercept | The urge is here |
| Card: heads-up | First heads-up · Tonight at 9:45 PM |
| Card: free | Remove the door · Strict Mode, whenever you’re ready |
| Card: partner | Waiting for your person · Until they join, your steps work on their own |
| Card: trial | Your trial ends tomorrow · Manage in Settings |
| Card: later | Finish setting up · About 2 minutes |
| Card: no wall | The wall isn’t up yet. It needs Screen Time access. |

**VoiceOver**

- Stone: “Foundation, day 1. Your word: steady.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Dawn completes. Stone Settles. Headline Carves once, then never again. |

**Transition out.** —

**Reduce Motion.** Fade.

**Edge cases**

- The free card appears once and stays dismissed. No paywall pop-ups, ever.
- The free card only follows a decision on S12; someone who left with Finish later before the door hasn’t met it yet.
- Finish setting up can’t be dismissed: it’s the only way back.
- Trial day 2: the trial card appears whether or not notifications are on, so the reminder S12 promises always arrives.
- No wall: the headline is “Day 1.” alone; the status chip reads “Wall not up”.

**PostHog**

- `home_viewed {first: true, path}`

---

## Branches

_Managed devices, simulator, resume, finish later_

### B2

**Screen Time is managed** · read · ~6s · branch

**Job.** Explain plainly that someone else controls Screen Time on this iPhone, and keep what still works.

**Earns its place.** Without it, a managed device shows a cryptic failure and the person leaves thinking Bedrock is broken.

**Layout.** Chapter bar (Wall). Eyebrow, Title headline, body, primary. Same dimmed shield card as S2-D.

**Interaction.** Continue goes to S5, then Home after S8. No Lock chapter, no paywall.

**Data captured → pays off.** Restricted flag. Home omits Strict Mode entirely.

**Copy**

| Key | String |
|---|---|
| Eyebrow | THE WALL |
| Headline | Screen Time is managed on this iPhone. |
| Body | A parent, school or company controls Screen Time here, so Bedrock can’t put up a wall. Your urge button and your foundation still work. |
| Primary | Continue |

**VoiceOver**

- Standard order.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. No haptic. |

**Transition out.** Rise to S5.

**Reduce Motion.** Fade.

**Edge cases**

- A minor on a parent-managed device: the 17+ rating and Apple’s age signals apply; nothing here asks for age.

**PostHog**

- `onb_screen_viewed {screen_id: "b2"}`

### B9

**Screen Time isn’t available here** · read · ~5s · branch

**Job.** Let review builds and the Simulator walk through every screen honestly.

**Earns its place.** App Review and demos run where FamilyControls can’t. Without this, reviewers hit a wall at S2.

**Layout.** As B2, plus a small “Preview” tag pinned under the Dynamic Island for the rest of the flow.

**Interaction.** Continue in preview simulates success at S2, S3 and S4 and shows every remaining screen. Purchases use the StoreKit sandbox.

**Data captured → pays off.** Preview flag.

**Copy**

| Key | String |
|---|---|
| Eyebrow | THE WALL |
| Headline | Screen Time isn’t available here. |
| Body | This build can’t block anything. You can still walk through every screen in preview mode. |
| Primary | Continue in preview |
| Tag | Preview |

**VoiceOver**

- Tag: “Preview mode. Nothing is blocked.”

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. |

**Transition out.** Rise to S3 (simulated).

**Reduce Motion.** Fade.

**Edge cases**

- Never shown on a real device with FamilyControls available.

**PostHog**

- `onb_screen_viewed {screen_id: "b9"}`

### RESUME

**Picking up where you left off** · — · 2s · branch

**Job.** Return to the exact screen, answers intact, after the app was closed mid-flow.

**Earns its place.** Restarting from S1 after a phone call is how onboardings lose people. One line tells them nothing was lost.

**Layout.** A toast under the Dynamic Island on the restored screen.

**Interaction.** State (screen ID, answers, wall status) is written to the app group container on every screen change. On launch, onboarding resumes there. System sheets that were interrupted are re-triggered from their pre-screen.

**Data captured → pays off.** Saved onboarding state, on device.

**Copy**

| Key | String |
|---|---|
| Toast | Picking up where you left off. |

**VoiceOver**

- Toast is announced.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Toast drops 12pt and fades in, holds 2s, fades out. |

**Transition out.** —

**Reduce Motion.** Fade only.

**Edge cases**

- More than 7 days later: resume, but at the start of the current chapter.
- Purchase completed but setup not started: resume at S13.1.
- Left after the real run started: resume at S13.5A with the same code. Never generate a new one here.
- Leaving the app on S5–S8, S13.1 or Home shows a plain stone cover in the app switcher, so answers and the letter never sit in a snapshot.

**PostHog**

- `onb_resumed {screen_id, gap_hours_bucket}`

### FL

**Finish later** · tap · ~4s · branch

**Job.** Let someone leave once the wall is up, and make coming back effortless.

**Earns its place.** This is the fast lane. The 2am builder can stop at 1:02 with protection on and nothing lost.

**Layout.** A sheet over the current screen: title, body, primary, secondary. Home then shows a card.

**Interaction.** Go to my wall saves state and opens Home. Keep going closes the sheet. The Home card resumes onboarding at the saved screen.

**Data captured → pays off.** Saved state, as RESUME.

**Copy**

| Key | String |
|---|---|
| Sheet title | Finish later? |
| Sheet body | Your wall is up. Bedrock will pick this up the next time you open it. |
| Primary | Go to my wall |
| Secondary | Keep going |
| Home card | Finish setting up · About 2 minutes |

**VoiceOver**

- Sheet focus starts on its title.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Standard sheet presentation. |

**Transition out.** Home (dawn level matches progress so far).

**Reduce Motion.** System sheet behaviour.

**Edge cases**

- No reminders or notifications about unfinished onboarding.

**PostHog**

- `onb_finish_later {screen_id}`
- `onb_finish_later_resumed`

---

## Supporter

_The person who holds the key_

### SP1

**Someone asked you** · read · ~6s · supporter

**Job.** Welcome a supporter and reframe the role as holding a key, not watching.

**Earns its place.** Partners arrive unsure of what they’re agreeing to. The first line decides whether they feel like a guardian or a spy.

**Layout.** No chapter bar. Stone mark, eyebrow, Title headline, body, primary. Dawn at a middle level.

**Interaction.** Opened from thebedrock.app/join/CODE (universal link) or the S1 link with a code field.

**Data captured → pays off.** Invite code → pairs the two devices on the server; nothing else is shared.

**Copy**

| Key | String |
|---|---|
| Eyebrow | BEDROCK |
| Headline | Someone asked you to be their person. |
| Body | It means holding a key, not watching. Here’s exactly what you’ll see. |
| Primary | Show me |
| Code field (from S1) | Invite code · Enter the code they sent you · Continue |
| Bad code | That code didn’t work. Check it with them and try again. |

**VoiceOver**

- Standard order.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Stone mark Settles; headline Carves. |

**Transition out.** Rise to SP2.

**Reduce Motion.** Fade.

**Edge cases**

- Code already used: “This invite has already been accepted.”
- Invite opened on a non-iPhone: the web page says supporters need an iPhone for now.

**PostHog**

- `sup_started {source: link | code}`

### SP2

**What you’ll see, and won’t** · read · ~10s · supporter

**Job.** List exactly what the supporter can and can’t see, side by side.

**Earns its place.** It protects the user’s dignity and the partner’s comfort in one screen. Every competitor that skipped this got called “invasion of privacy”.

**Layout.** Title headline. Two columns: “You’ll see” and “You won’t see”, three items each with glyphs. Primary.

**Interaction.** Continue only.

**Data captured → pays off.** None.

**Copy**

| Key | String |
|---|---|
| Headline | What you’ll see, and what you won’t. |
| You’ll see | Whether their wall is up · When they ask to turn it off · If their Bedrock goes quiet for a while |
| You won’t see | What they browse or block · Their answers or their letter · Anything they type |
| Primary | I’m in |

**VoiceOver**

- Each column is a list with its heading.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Columns Strata in, 80ms apart. |

**Transition out.** Rise to SP3.

**Reduce Motion.** Columns appear together.

**Edge cases**

- “Goes quiet” is detected on the server from missing check-ins, so alerts arrive hours later, not instantly; SP4 says so.

**PostHog**

- `sup_terms_viewed`

### SP3

**Alerts** · tap · ~6s · supporter

**Job.** Ask the supporter for notifications so a request never sits unseen.

**Earns its place.** An approval request nobody sees is a broken promise to the user.

**Layout.** Title headline, body, one primary (HIG pre-prompt rule).

**Interaction.** Continue triggers the iOS request; either answer continues.

**Data captured → pays off.** Notification permission on the supporter’s phone.

**Copy**

| Key | String |
|---|---|
| Headline | We’ll only reach you when it matters. |
| Body | Turn on notifications so a request doesn’t sit unseen. Nothing on them says what Bedrock is for. |
| Primary | Continue |

**VoiceOver**

- Standard order.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Rises in. |

**Transition out.** Rise to SP4.

**Reduce Motion.** Fade.

**Edge cases**

- Denied: SP4 shows “Turn on notifications in Settings to see requests quickly.”

**PostHog**

- `sup_notif_result {granted}`

### SP4

**You’re their person** · read · ~8s · supporter

**Job.** Confirm the role and show the supporter home.

**Earns its place.** Ends the flow with the one status they’ll check, and tells them plainly how a request works, including the 3-day rule.

**Layout.** Title headline. A status card. Body. Primary.

**Interaction.** Done lands on the supporter home (same layout, without onboarding copy).

**Data captured → pays off.** Paired.

**Copy**

| Key | String |
|---|---|
| Headline | You’re their person. |
| Status card | Wall up · Checked in 2 hours ago |
| Body | If they ask to turn it off, you’ll see it here first. Without your answer, it opens after 3 days, and you’re told. |
| Quiet note | If their Bedrock goes quiet, you’ll hear within a few hours, not instantly. |
| Primary | Done |
| Alert later | Haven’t heard from their Bedrock in a while. Might be worth a check-in. |

**VoiceOver**

- Status card is read as one element.

**Motion and haptics**

| When | What |
|---|---|
| 0ms | Status card Settles; soft impact. |

**Transition out.** Supporter home.

**Reduce Motion.** Fade.

**Edge cases**

- The supporter never sees a paywall, a price, or the user’s answers.

**PostHog**

- `sup_completed`
