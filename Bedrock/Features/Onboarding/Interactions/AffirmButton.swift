import SwiftUI

/// Affirm (spec v2): a single soft "Yes — that's me" tap that turns a
/// reflection into a micro-commitment. Quieter than a primary CTA — assent,
/// not navigation. `.rigid` on tap.
struct AffirmButton: View {
    var title = "Yes — that's me"
    let action: () -> Void

    var body: some View {
        Button {
            BedrockHaptics.set() // .rigid — agreement lands
            action()
        } label: {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(Capsule().fill(BedrockColor.slate.opacity(0.7)))
                .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.6), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Confirms this reflection is true for you")
    }
}
