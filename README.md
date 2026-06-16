# Bedrock

A focus & self-mastery app for iOS. *Rock bottom is where bedrock is* — the solid foundation you build a new life on, layer by layer.

> This repo is the iOS client. Architecture, feature set, and design system are specified in the project brief. Build proceeds in phases — see **Build order** below.

---

## Requirements

- **Xcode 26.2+** (this machine has 26.2; SDK iOS 26.2).
- **[XcodeGen](https://github.com/yonsho/XcodeGen)** — `brew install xcodegen`. The `.xcodeproj` is generated, never hand-edited.
- For the blocking core (Phase 1+): a **paid Apple Developer account**, the **Family Controls** capability, and a **physical device** (Screen Time APIs are inert in Simulator).

## Generate & build

```sh
xcodegen generate
open Bedrock.xcodeproj
# or, headless compile check (Simulator, signing off):
xcodebuild -project Bedrock.xcodeproj -scheme Bedrock \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Targets (bundle-ID root `com.thebedrock.app`)

| Target | Bundle ID | Role |
|---|---|---|
| `Bedrock` | `com.thebedrock.app` | Main app |
| `BedrockMonitor` | `com.thebedrock.app.monitor` | `DeviceActivityMonitor` — re-applies shields, tamper/heartbeat |
| `BedrockShield` | `com.thebedrock.app.shield` | `ShieldConfiguration` — the Intercept wall styling |
| `BedrockShieldAction` | `com.thebedrock.app.shieldaction` | `ShieldAction` — handles shield button taps |

All four carry the **Family Controls** entitlement and the **App Group** `group.com.thebedrock.app`. Each bundle ID must be registered as its own App ID, with a **separate Family Controls entitlement request** submitted per bundle ID (weeks-long Apple approval — critical path).

## Critical constraints baked into this scaffold

- **§10.1 — min iOS 26.4 at ship.** Held at 26.2 locally (installed SDK). Bump `project.yml → options.deploymentTarget.iOS` to `"26.4"` before any release that relies on the passcode lock. iOS 26.4 / 27 APIs are gated behind `#available`.
- **§9 two-register copy rule.** Apple-facing strings (e.g. `NSFamilyControlsUsageDescription`, App Store copy, privacy labels) use **focus / usage-management** framing only — no recovery/addiction language. In-app brand copy stays recovery-forward. See `Bedrock/Resources/Info.plist`.
- **§10.6 — on-device only.** No browsing/traffic/image data ever leaves the phone.
- **§10.7 — every Liquid Glass surface ships a Reduce Transparency + Reduce Motion fallback.** Enforced centrally in `GlassKit`; never use raw `.glassEffect` in a screen.
- **No** `NEFilterDataProvider` content filtering and **no** MDM/config profiles on the consumer path (§10.3–4).

## Design system

All styling flows through two layers — no ad-hoc colors/fonts/glass in screens:

- `DesignSystem/Theme/` — palette, typography, spacing, motion, haptics tokens.
- `DesignSystem/GlassKit/` — `GlassCard`, `GlassButton`, `GlassSheet`, `bedrockGlass(in:)`, all with built-in Reduce Transparency/Motion fallbacks.

## Build order

- **Phase 0 — Foundations** ✅ *(this scaffold)*: project + targets + entitlements, `Theme`, `GlassKit`, service stubs, placeholder Foundation home.
- Phase 1 — Blocking core + Foundation streak UI
- Phase 2 — Strict Mode + Passcode vault + disable gauntlet
- Phase 3 — Accountability + backend (Supabase / Railway / Upstash)
- Phase 4 — Intercept Moment + on-device Trigger Intelligence
- Phase 5 — Onboarding + paywall
- Phase 6 — DNS layer, recovery program, community

## Status of Phase 0 service layer

`Services/` holds `@MainActor @Observable` **stubs** with the real method surfaces and `// Phase N:` seams. No OS APIs are invoked yet, so the scaffold builds and runs in Simulator. Live `FamilyControls` / `ManagedSettings` wiring lands in Phase 1 on device.
