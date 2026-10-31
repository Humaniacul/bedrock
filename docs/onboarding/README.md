# Bedrock onboarding · First Light · handoff

Everything Claude Code needs to build the onboarding in SwiftUI. The design, research and clickable prototype live on the Bedrock design canvas (Phase 6 has the prototype; Phase 7 the red team). This folder is the build-facing copy of the final spec, after the red team.

**Flow version:** `first_light_1` · **Target:** iOS 26.4+, iPhone, SwiftUI, Liquid Glass on controls only · **Screens:** 36 specified states. The free path is 15 screens from S1 to Home, with the paywall 12th; buying adds Sign in with Apple and 7 Strict Mode setup screens after the paywall.

## Read these first

1. **OPEN_QUESTIONS.md #1 (partner model).** Decided: ship the Phase 7 model (Bedrock-held blind entry, partner approval, 3-day release). The partner path can be built, last in the build order.
2. **OPEN_QUESTIONS.md #2 (floating digit window).** Decided: spike Picture in Picture first; if it works on the lock-test devices, ship it, and keep app switching behind a remote flag either way.
3. **SPEC.md, “Rules that apply to every screen”.**

## Files

| File | What it is | Suggested home in the project |
|---|---|---|
| `SPEC.md` | Every screen: job, layout, interaction, data, every string, VoiceOver, motion and haptics, transition, Reduce Motion, edge cases, PostHog events | stays in `docs/onboarding/` |
| `onboarding-spec.json` | The same spec as data, one object per screen | stays here; handy for generating tests |
| `Localizable.xcstrings` | All 284 onboarding strings as a String Catalog, keys `onb.<screen>.<label>` | merge into `Bedrock/` (or keep as `Onboarding.xcstrings` and use `tableName: "Onboarding"`) |
| `BedrockTokens.swift` | Colours, Dawn levels, spacing, radii, type, glass | `BedrockShared/Design/` (the monitor uses it too; copy `BedrockColor` into `BedrockShield` or add `BedrockShared` to its sources) |
| `BedrockMotion.swift` | The twelve primitives as SwiftUI animations, appear modifiers, per-glyph Carve, named timings | `Bedrock/Onboarding/Design/` |
| `BedrockHaptics.swift` | The haptic map and the S8 HoldRamp (Core Haptics) | `Bedrock/Onboarding/Design/` |
| `OnboardingAnalytics.swift` | PostHog setup and a typed event enum; no free-text properties are possible | `Bedrock/Analytics/` |
| `COMPONENTS.md` | Every reusable component with props, states, motion and accessibility | stays here |
| `ASSETS.md` | Fonts (Instrument Serif, OFL), images, SF Symbols, web endpoints | stays here |
| `AB_TESTS.md` | Test candidates, the metric each moves, guardrails, what’s never tested | stays here |
| `OPEN_QUESTIONS.md` | Decisions still open, with recommendations | stays here |

The Swift files are reference implementations written against the spec, not yet compiled in this project. Expect small API adjustments (PostHog config names in particular) when you add them.

## Project changes

- Add the PostHog package to the `Bedrock` target in `project.yml` (`https://github.com/PostHog/posthog-ios.git`). RevenueCat is already there; use entitlement `pro`, offering `default`.
- Add `InstrumentSerif-Regular.ttf` and `InstrumentSerif-Italic.ttf` to the app target and `UIAppFonts`, with the OFL text alongside.
- Universal links for `thebedrock.app/join/{CODE}` (`applinks:` entitlement and an `apple-app-site-association` file).
- A blocked-on-purpose test page at `https://test.thebedrock.app`.

## Build order

Sizes are the Phase 7 iOS engineer’s rough estimates for one developer with Claude Code (S ≈ a day, M a few days, L about a week, XL more or risky).

1. **Foundations** · tokens, `OnboardingScaffold`, `ChapterBar`, buttons, `ChoiceChip`, `BedrockSheet`, `Toast`, `PrivacyCover`, onboarding state saved to the app group on every screen change.
2. **Wall · S1–S4** (M) · Screen Time authorisation, the picker, ManagedSettings writes, the daily DeviceActivity schedule, the S4 test with its background check. Blocking must be on by the end of S3, on every path.
3. **You · S5–S8** (M) · chips, the custom word, `StoneView`, `CarveText`, `HoldToSetControl` with HoldRamp.
4. **Lock story · S9–S11** (S) · `DoorIllustration`, `GauntletPath`, `OptionCard`.
5. **Paywall · S12, S12U, SIWA** (M) · RevenueCat offerings, trial eligibility, localized prices, Restore, late-night reminder, Sign in with Apple.
6. **Begin · S14, S15, Home** (M) · `NotificationPreview`, `UrgeButton`, `BreathRing`, Home cards and the status chip.
7. **Branches** · S2-D, B2, B9 (preview mode for the simulator and review), RESUME, Finish later.
8. **Strict Mode setup · S13.1–S13.7** (XL) · after the PiP spike: the letter, practice, the real run, both checks, Sealed.
9. **Partner and supporter · S13.2P, SP1–SP4** (L) · after OPEN_QUESTIONS #1.
10. **Analytics** throughout: fire each screen’s events as you build it.

## Non-negotiables

- Every string is final. Use the catalog; don’t rewrite copy in code. No emoji, no exclamation marks.
- Prices come from StoreKit through RevenueCat, never literals. Trial copy and the timeline only when `isEligibleForIntroOffer` is true.
- The free path is always visible: “Keep the free wall” and the close button on S12 from the first frame.
- Nothing on the lock screen, the shield or a notification says what Bedrock is for.
- Nothing personal leaves the phone. Analytics properties are enums, bools, buckets and durations only.
- No claim about the lock that isn’t true on the iOS versions the lock test verified. Strict Mode is offered only on those versions (remote config).
- Every animation has its Reduce Motion version; every gesture has a VoiceOver or tap equivalent; layouts hold at AX sizes; glass falls back to solid with Reduce Transparency.
- The code is never held for payment: if the plan ends with Strict Mode on, the steps still release it.

## Definition of done, per screen

- [ ] Copy matches SPEC.md exactly, from the catalog.
- [ ] Layout matches the prototype at 402 × 874 and holds at AX5.
- [ ] Hero motion and haptics as specified; Reduce Motion version checked with the setting on.
- [ ] VoiceOver order and labels as specified.
- [ ] Every edge case in SPEC.md handled or explicitly deferred.
- [ ] The screen’s PostHog events fire once, with only the listed properties.
- [ ] No literal colours, fonts or animation values in the view.

## A first prompt for Claude Code

> Read docs/onboarding/README.md, SPEC.md and COMPONENTS.md. Add BedrockTokens.swift to BedrockShared and BedrockMotion.swift and BedrockHaptics.swift to the app target, fix any compile issues, then build OnboardingScaffold, ChapterBar, PrimaryButton, TextButton and ChoiceChip with SwiftUI previews at 402 × 874 and at AX5. Don’t build any screens yet. Show me the previews.
