import SwiftUI
import AuthenticationServices

/// Sign in with Apple — shown right after the paywall (skippable). Ties the
/// membership to the account and links the Apple identity to the backend.
struct AuthView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void

    @State private var working = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 46))
                .foregroundStyle(Theme.accent)
                .riseIn(0, reduceMotion: reduceMotion)
            Text("Save your foundation.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .riseIn(0.1, reduceMotion: reduceMotion)
            Text("Sign in so your progress, your plan, and your membership follow you — even on a new phone. Private by design: Apple shares only what you allow.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .riseIn(0.2, reduceMotion: reduceMotion)
            Spacer()
            SignInWithAppleButton(
                .signIn,
                onRequest: { services.auth.configureRequest($0) },
                onCompletion: { result in
                    working = true
                    Task {
                        await services.auth.handle(result)
                        onNext()
                    }
                }
            )
            .signInWithAppleButtonStyle(.white) // app is forced dark (§6)
            .frame(height: 52)
            .clipShape(Capsule())
            .disabled(working)
            .riseIn(0.3, reduceMotion: reduceMotion)

            Button("Not now") { onNext() }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .disabled(working)
                .riseIn(0.4, reduceMotion: reduceMotion)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack { StoneBackground(); AuthView(onNext: {}) }
        .environment(AppServices.makeStub())
}
