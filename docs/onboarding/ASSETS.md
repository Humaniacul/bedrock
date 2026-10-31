# Asset list

Almost everything in the onboarding is drawn in code. The few files that ship are below, with where they come from and their licence.

## Fonts

| File | Use | Licence | Notes |
|---|---|---|---|
| `InstrumentSerif-Regular.ttf` | All serif lines (Display XL, Title, Title S) | SIL Open Font License 1.1 | Free to bundle and embed. Add to the app target and `UIAppFonts`. PostScript name `InstrumentSerif-Regular`. |
| `InstrumentSerif-Italic.ttf` | Accent italic (“At 2am.”) | SIL OFL 1.1 | PostScript name `InstrumentSerif-Italic`. |
| SF Pro, SF Mono | UI, body, eyebrows, digits | System | Nothing to ship. |

Download from Google Fonts or the Instrument foundry’s repository and keep the OFL text in the repo (for example `Bedrock/Resources/Fonts/OFL.txt`). If you later license a premium serif (Canela, GT Sectra, Reckless class), only `BedrockFont.serifName` changes. Fallback when the font is missing: the system serif (New York).

## Images

| Asset | Format | Where | Notes |
|---|---|---|---|
| Horizon glow | PNG @3x, about 2172 × 1680 px (724 × 560pt, wider than the screen so its edges never show) | `HorizonGlow` on every screen | Pre-rendered radial gradient (ember glow → transparent). Opacity animates; never a live blur. One for onboarding, one brighter “daylight” layer for Home. |
| Noise tile | PNG, 256 × 256pt, grayscale | Scaffold background, stone surface | Fractal noise at about 6% overlay. Tiled. |
| Stone mark | SF-style vector (PDF or SwiftUI `Shape`) | S1, SP1 corner, privacy cover, floating window | The five-point stone silhouette. Prefer a `Shape` so it scales with Dynamic Type. |
| App icon | Existing Bedrock icon | Notification preview, shield | Must stay discreet: no words, nothing that says what the app is for. |

## Drawn in SwiftUI (no files)

- `StoneView`: polygon, strata lines in a `Canvas`, highlight and shade gradients, the carved word, the ember seam.
- `WallView` stones, ground line, keystone.
- `DoorIllustration` switch and mini wall.
- `GauntletPath` line and nodes.
- `NotificationPreview` lock-screen miniature.
- `BreathRing`, hold ring, chapter bar.

## SF Symbols

| Symbol | Where |
|---|---|
| `chevron.left` | Back |
| `xmark` | Close, card dismiss |
| `chevron.right` | Tappable Home cards, sheet rows |
| `checkmark` | Chip ticks, S3 row checks, practice done |
| `lock.fill` | S3 row 1, “Stays on this iPhone” |
| `square.grid.2x2` | S3 row 2 (apps) |
| `clock` | S3 row 3 (daily check) |
| `key` | SP2 “When they ask to turn it off” |
| `eye.slash` | SP2 “You won’t see” |
| `waveform.path` | SP2 “If their Bedrock goes quiet” |

## Haptics

No AHAP files. `BedrockHaptics.swift` builds the HoldRamp pattern in code; everything else uses UIKit feedback generators.

## Sound

None. Onboarding ships no sounds.

## Web and server

| Item | Purpose |
|---|---|
| `https://test.thebedrock.app` | A page that exists only to be blocked. Added to the web filter on S3; opened on S4. Serve a plain page so a failed block is obvious. |
| `https://thebedrock.app/join/{CODE}` | Universal link for partner invites (SP1). Needs the `applinks:` entitlement and an `apple-app-site-association` file. If opened on a non-iPhone, the page says supporters need an iPhone for now (RT-22). |
| Partner approval endpoint and 3-day timer | Server side, for RT-02. Pending your confirmation of the partner model. |
