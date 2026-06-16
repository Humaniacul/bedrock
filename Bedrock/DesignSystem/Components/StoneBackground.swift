import SwiftUI

/// The living-stone content layer that everything floats above (§6). Deep
/// obsidian→basalt with a faint molten glow low in the frame — the bedrock
/// depth. This is *content*, not a glass background; glass controls sit on top.
struct StoneBackground: View {
    /// How present the molten core glow is (0 = dark, 1 = lit). The home screen
    /// brightens this as the Foundation rises.
    var emberGlow: Double = 0.10

    var body: some View {
        LinearGradient(
            colors: [BedrockColor.obsidian, BedrockColor.basalt, BedrockColor.obsidian],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            RadialGradient(
                colors: [BedrockColor.ember.opacity(emberGlow), .clear],
                center: UnitPoint(x: 0.5, y: 0.96),
                startRadius: 0,
                endRadius: 460
            )
        )
        .ignoresSafeArea()
    }
}

#Preview { StoneBackground(emberGlow: 0.18) }
