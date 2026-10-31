import SwiftUI

/// The living-stone content layer that everything floats above (§6). Deep
/// obsidian→basalt with a faint molten glow low in the frame — the bedrock
/// depth. This is *content*, not a glass background; glass controls sit on top.
struct StoneBackground: View {
    /// How present the molten core glow is (0 = dark, 1 = lit). The home screen
    /// brightens this as the Foundation rises.
    var emberGlow: Double = 0.10

    var body: some View {
        // The onboarding backdrop: obsidian, the horizon glow, the grain. The
        // old 0.1–0.28 glow range maps onto Dawn levels.
        OnboardingBackdrop(level: min(emberGlow * 3, 1))
    }
}

#Preview { StoneBackground(emberGlow: 0.18) }
