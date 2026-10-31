# Component inventory

Every reusable piece of the onboarding, what it takes, its states, and what it needs for accessibility. Build these first; screens are mostly composition. Token names refer to `BedrockTokens.swift`, motion names to `BedrockMotion.swift`, haptics to `BedrockHaptics.swift`.

Sizes are points at the default text size. "AX sizes" means the accessibility text sizes (AX1–AX5).

## Frame and navigation

### `OnboardingScaffold`
The frame every onboarding screen sits in.
- **Props:** `screen: ScreenID`, `chapter: Chapter?`, `chapterProgress: Double`, `showsBack: Bool`, `showsFinishLater: Bool`, `showsClose: Bool`, `content`, `footer` (primary area).
- **Layout:** chapter bar at 58pt; back and Finish later at 92pt; content from 112pt (150pt when the back row shows); 24pt side margins; footer pinned 46pt above the home indicator.
- **Background:** `bgBase`, then `HorizonGlow` at the screen’s `Dawn.level`, then the noise tile at 6%.
- **AX sizes:** content scrolls; the footer stays pinned with a 1pt `lineSubtle` top hairline when content scrolls under it.
- **Privacy:** on S5–S8, S13.1 and Home, puts `PrivacyCover` over the window when the scene goes inactive.

### `ChapterBar`
Four segments: Wall, You, Lock, Begin.
- **Props:** `current: Chapter`, `progress: Double` (0–1 within the current chapter).
- **Look:** 3pt tracks in `lineSubtle`, fill in `ember`, labels SF Mono 9.5pt, +1.6 tracking, uppercase; current label `inkPrimary`, others `inkTertiary`.
- **Motion:** fill width animates 0.6s ease. No haptic.
- **VoiceOver:** one element: “Chapter 2 of 4, You.”

### `GlassCircleButton`
Back (chevron) and close (×). 44 × 44pt.
- **Look:** `.bedrockGlass(Circle())`; Reduce Transparency falls back to `bgRaised` with a `lineStrong` stroke.
- **VoiceOver:** “Back”; close is labelled with what it does: “Keep the free wall.”

### `FinishLaterButton`
Glass capsule, 44pt tall, “Finish later”. Shown S4–S11. Opens `FinishLaterSheet`.

## Buttons

### `PrimaryButton`
- **Props:** `title`, `isEnabled`, `isLoading`, `action`.
- **Look:** 56pt capsule, `BedrockColor.primaryFill`, 1pt border `rgba(255,214,170,0.35)`, inner top highlight, soft ember shadow (baked, not `.shadow` while animating). Label SF Pro Semibold 17 in `onEmber`.
- **Disabled:** `#1F1C1A` fill, `lineSubtle` border, label `inkDisabled`. Disabled buttons still announce why: hint “Pick at least one.”
- **Loading:** small spinner replaces nothing; the label stays (S2 while iOS answers).
- **Haptic:** none on routine taps.

### `TextButton`
44pt tall, SF Pro 16, `inkPrimary` (secondary actions like “Skip”, “Not now”, “Keep the free wall”). Never smaller than the primary’s hit area. The free path is never styled weaker than this.

### `LinkButton`
Underlined, 14pt, `inkTertiary` or `inkSecondary`. Crisis link, “What it can’t stop”, “Other plans”, “I got stuck”. 40pt hit height.

## Choices

### `ChoiceChip`
S5, S6, S7.
- **Props:** `title`, `isSelected`, `isExclusive` (“No pattern yet”, “Not sure” clear the others).
- **Look:** min 52pt, radius 14, unselected `bgSurface` + `lineStrong`; selected `emberWash` + `ember` border and an ember tick.
- **Layout:** two-column grid, 10pt gaps; one column at AX sizes.
- **Motion:** Strata in on arrival; selection changes border and fill in 0.2s.
- **Haptic:** `select()`.
- **VoiceOver:** toggle buttons with `isSelected` trait.

### `CustomWordField`
S7. Text field, 52pt, `bgRaised`, ember border when focused. Letters only, one word, 14 characters max. Error “One word, letters only.” in `emberGlow`. Note under it: “Anyone glancing at your phone could see it.”

### `OptionCard`
S11 key holder. Full width, radius 20, title in serif 26, body 15, small tag pill.
- **States:** unselected, selected (ember border, `emberWash`, title warms with Ember).
- **VoiceOver:** radio buttons, “Bedrock keeps it, 1 of 2”; body and tag as hint.

### `PlanCard`
S12. Two side by side (Yearly, Lifetime); stack at AX sizes, Yearly first.
- **Props:** `plan`, `price` (localized), `subline`, `badge?`, `isSelected`.
- **Look:** radius 18, min 132pt tall, badge pill overlapping the top edge.
- **Rules:** prices never animate; the badge “3 days free” shows only when StoreKit says eligible.
- **VoiceOver:** “Yearly, $69.99 a year, 3 days free, selected.”

## Illustration and hero pieces

### `StoneView`
The foundation stone. Drawn in SwiftUI (a five-point polygon with stratified fill), no raster.
- **Props:** `word`, `day`, `state: hovering | set | cracked(repaired:)`, `size: regular(148×218) | home(132×194) | ax(132×200)`.
- **Hovering:** 45% opacity, raised 12pt.
- **Set:** Lock (drops 14pt, 4pt overshoot) + `lock()` haptic; the word carves in with `CarveText(word: true)` 100ms per letter; “DAY 1” fades in; the demo seam draws and fills with ember.
- **VoiceOver:** one image element: “Foundation, day 1. Your word: steady.”
- **Performance:** `.drawingGroup()`; noise tile 256pt.

### `HoldToSetControl`
S8. 84pt glass circle with a progress ring and a small stone glyph.
- **Behaviour:** press and hold 1.4s fills the ring (`HoldRamp.begin`); early release drains it over 0.3s (`HoldRamp.cancel`); completion calls `HoldRamp.complete` then `BedrockHaptics.lock()`.
- **Fallbacks:** two short taps show “Keep holding”; a third shows a plain “Set it” button. With VoiceOver, double-tap sets directly.
- **VoiceOver:** “Set your first stone. Double-tap to set.”

### `WallView`
S3, S4 mini, S9 mini, S13.6. Three courses of stones (76pt and 35pt halves, 46pt tall, 6pt gaps) on a ground line.
- **Props:** `courses: [CourseState]` where each course is `empty | landing | landed | failed`, `hasApps: Bool` (the middle course only exists if apps were picked), `keystone: Bool`.
- **Motion:** each course Drops when its ManagedSettings write returns (`stoneLands()` per course), then the wall Locks (dips 3pt) with `lock()`. A write over 3s keeps its stones waiting; a failure leaves the course empty and its row says “Didn’t apply”.
- **VoiceOver:** “The wall: adult websites blocked, 3 apps blocked, checked daily.”

### `GauntletPath`
S10. Six tappable rows on a vertical line with nodes.
- **Motion:** the ember fill travels from 0.6s, one step a second, holds at step 5, reaches step 6 at 7.2s; nodes flare (`pathNode()`); labels rise 40% → 100%. Plays once; on back it shows lit with no replay. The primary is available from 0.9s.
- **Expand:** tapping a row expands its detail (Expand); one open at a time.
- **Reduce Motion:** all six lit, no travel; the 30:00 ring is a still.

### `DoorIllustration`
S9. A settings-style row in Bedrock’s own style (not a copy of iOS) with a switch, and a miniature wall. Plays twice: switch slides off, wall dims to 30% and drops 4pt; rests off. Reduce Motion: two static panels side by side.

### `NotificationPreview`
S14, SP3. A lock-screen miniature (300 × 232pt, neutral wallpaper, date and time) with one notification card using the real app icon. The time comes from the person’s first S5 window. VoiceOver: “Example notification: A good moment to plan the next hour.”

### `UrgeButton`
S15 and Home. S15: 168pt circle, ember glass, Breath. Home: full-width 64pt capsule. Press: `urge()`.

### `BreathRing`
S15. Replaces the urge button after the press: scale 0.56 → 1 over 4s (in), back over 4s (out), `breathPhase()` at each change, labels “Breathe in…” / “…and out.” announced. Reduce Motion: brightness changes instead of size.

### `HorizonGlow`
A pre-rendered radial gradient image (not a live blur) whose opacity animates to `Dawn.level` with `BedrockMotion.dawn`. Home adds the full daylight layer.

## Sheets, overlays and system moments

### `BedrockSheet`
Custom bottom sheet for Bedrock content: crisis, limits, existing passcode, other plans, Finish later, stuck.
- **Look:** `bgSurface`, top corners 32, 1pt `lineStrong` top border, grabber 36 × 5.
- **Focus:** VoiceOver focus starts on the title. Dismiss by grabber drag, scrim tap or the sheet’s button.
- **Crisis sheet:** region-aware. 988 only in the US (Suicide & Crisis Lifeline) and Canada (Suicide Crisis Helpline); elsewhere “Find a helpline in your country” (findahelpline.com) is first. Always ends with “In immediate danger? Call your local emergency number.”

### `FloatingDigitWindow`
S13.4B, S13.5A, S13.7A. The blind-entry window over Settings. **The riskiest component; see RT-23 in OPEN_QUESTIONS.md.**
- **States:** `tapToStart`, `digit(n, phase: type | again)`, `paused(.screenCaptured)`, `done`.
- **Copy:** “Tap to start” · “Type · 7 · 1 of 4” · “Again · 7” · “Stop screen recording to continue.” · “Done. Head back to Bedrock.”
- **Timing:** 3s per digit, 5s in slow mode. Each digit fades in 120ms, a ring sweeps its duration, fades out 120ms.
- **Rules:** the code is in the Keychain before the first digit; never regenerated mid-setup (RT-03). Pauses while the screen is captured (RT-04).
- **Implementation A:** `AVPictureInPictureController` with a sample-buffer content source rendering the digit.
- **Implementation B (fallback):** each digit shown in Bedrock for 3s, then “Switch to Settings”.

### `PracticeKeypad`
S13.3B. A local, fake passcode pad (4 9 1 6, twice). Wrong digit: shake (8pt, 0.32s) + `wrongDigit()`. Done: “That’s all it is.” with a Lock check.

### `Toast`
Drops 12pt under the Dynamic Island, holds 2s, fades. Announced by VoiceOver. Used for “Picking up where you left off.”, “Link copied.”, “We’ll remind you tomorrow at noon.”

### `PrivacyCover`
Full-window `bgBase` with the stone mark, shown in the app switcher on S5–S8, S13.1 and Home.

### `HomeCard`
Up to two on Home. Title + subtitle, chevron when tappable, × to dismiss (except “Finish setting up”). Cards: Finish setting up, The wall isn’t up yet, First heads-up, Waiting for your person, Remove the door (only after an S12 decision), Your trial ends tomorrow (day 2).

### `StatusChip`
Home. “Wall up · Strict Mode on / off” or “Wall not up”, with a dot. On the free wall it’s a button that opens S10 then S12 (RT-16); with no wall it opens S2.

## System surfaces (not ours, but designed around)

- **Screen Time authorisation sheet** (S2): triggered by `AuthorizationCenter.shared.requestAuthorization(for: .individual)`. Never imitate it.
- **FamilyActivityPicker** (S3): returns opaque tokens; show counts only (“3 apps”).
- **SFSafariViewController** (S4): opens `https://test.thebedrock.app`, which the web filter blocks; Bedrock then confirms with a background `WKWebView` load.
- **App Store purchase sheet** (S12): via RevenueCat.
- **Notification permission** (S14, SP3, and the late-night “Remind me”).
- **Settings → Screen Time passcode screens** (S13.4B): Bedrock opens its own Settings page; the checklist names the taps.
