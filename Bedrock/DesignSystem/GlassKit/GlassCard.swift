import SwiftUI

/// A floating glass control surface — the navigation/control layer above the
/// stone content (§6.3). Use for HUDs, option cards, stat panels. Do NOT put
/// primary reading content behind it.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Theme.Radius.lg
    var tint: Color?
    var padding: CGFloat = Theme.Spacing.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .bedrockGlass(
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                tint: tint
            )
    }
}

#Preview {
    ZStack {
        StoneBackground()
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Protection active").font(Theme.Typography.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("3 layers holding").font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding()
    }
}
