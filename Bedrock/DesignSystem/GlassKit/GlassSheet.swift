import SwiftUI

/// A branded sheet body. The presenting sheet chrome gets Liquid Glass from the
/// platform; this provides the solid content surface beneath it (reading content
/// must never sit on full-screen glass — §6.3) plus a grabber and optional title.
/// Reused by Intercept / Panic / gauntlet sheets in later phases.
struct GlassSheet<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule()
                .fill(Theme.textSecondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, Theme.Spacing.sm)
                .accessibilityHidden(true)

            if let title {
                Text(title)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            content()
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
    }
}

#Preview {
    Color.black.sheet(isPresented: .constant(true)) {
        GlassSheet(title: "Ride it out") {
            Text("Breathe. The urge crests and fades in minutes.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
            Button("I'm steady") {}.buttonStyle(.bedrockPrimary)
        }
        .presentationDetents([.medium])
    }
}
