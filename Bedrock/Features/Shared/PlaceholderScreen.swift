import SwiftUI

/// Honest empty state for screens that arrive in a later phase. Empty states are
/// invitations, not dead ends (§6.6).
struct PlaceholderScreen: View {
    let title: String
    let phase: String

    var body: some View {
        ZStack {
            StoneBackground()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                Text("Being built — \(phase).")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(Theme.Spacing.xl)
        }
    }
}

#Preview {
    PlaceholderScreen(title: "Protection", phase: "Phase 1")
}
