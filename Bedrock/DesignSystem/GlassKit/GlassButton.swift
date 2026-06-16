import SwiftUI

// Bedrock button styles. Two registers:
//   .bedrockPrimary — solid ember, for the one action that matters on a screen.
//   .bedrockGlass   — Liquid Glass control (with Reduce Transparency fallback).
// Both fire a "set" haptic on press via `.sensoryFeedback`.

struct BedrockPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.onAccent)
            .padding(.vertical, Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? Theme.accentPressed : Theme.accent)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.smooth(duration: 0.18), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .heavy), trigger: configuration.isPressed) { _, now in now }
    }
}

struct BedrockGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.textPrimary)
            .padding(.vertical, Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .bedrockGlass(in: Capsule(style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.smooth(duration: 0.18), value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed) { _, now in now }
    }
}

extension ButtonStyle where Self == BedrockPrimaryButtonStyle {
    static var bedrockPrimary: BedrockPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == BedrockGlassButtonStyle {
    static var bedrockGlass: BedrockGlassButtonStyle { .init() }
}

#Preview {
    ZStack {
        StoneBackground()
        VStack(spacing: Theme.Spacing.lg) {
            Button("Lay the first stone") {}.buttonStyle(.bedrockPrimary)
            Button("Not now") {}.buttonStyle(.bedrockGlass)
        }
        .padding()
    }
}
