import SwiftUI
import UIKit

/// Guides the user (or partner) through setting the Screen Time passcode (§4).
/// iOS has no API to set it, so this is instructional — Model A's partner types
/// it; Model B reveals the app-generated code one digit at a time so the user
/// never sees all four at once. The code is stored in the Keychain so the
/// gauntlet can reveal it on release.
struct PasscodeSetupView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    let model: PasscodeModel
    var onConfirmed: () -> Void

    @State private var code = ""

    var body: some View {
        NavigationStack {
            ZStack {
                StoneBackground()
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        switch model {
                        case .partnerHeld: partnerFlow
                        case .appHeld: appFlow
                        case .none: EmptyView()
                        }
                    }
                    .padding(Theme.Spacing.xl)
                }
            }
            .navigationTitle("Set the passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if model == .appHeld, code.isEmpty {
                    code = services.passcode.generateCode()
                }
            }
        }
    }

    // MARK: Model A — partner-held

    private var partnerFlow: some View {
        VStack(spacing: Theme.Spacing.xl) {
            header(
                icon: "person.2.fill",
                title: "Hand your phone to your partner",
                body: "They'll set a 4-digit Screen Time passcode that you won't know. Without it, you can't disable protection — which is the point."
            )
            settingsSteps
            disclosureCard
            Button("My partner has set it") {
                onConfirmed(); dismiss()
            }
            .buttonStyle(.bedrockPrimary)
            openSettingsButton
        }
    }

    // MARK: Model B — app-held (blind entry)

    private var appFlow: some View {
        VStack(spacing: Theme.Spacing.xl) {
            header(
                icon: "lock.rotation",
                title: "Set a code you won't remember",
                body: "Bedrock generated a passcode and saved it securely. Reveal one digit at a time and enter it in Settings — you'll never see all four at once."
            )
            DigitReveal(code: code)
            settingsSteps
            disclosureCard
            Button("I've set it in Settings") {
                onConfirmed(); dismiss()
            }
            .buttonStyle(.bedrockPrimary)
            openSettingsButton
        }
    }

    // MARK: Shared pieces

    private func header(icon: String, title: String, body: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(body)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var settingsSteps: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                stepLine(1, "Open Settings → Screen Time")
                stepLine(2, "Tap “Use Screen Time Passcode”")
                stepLine(3, "Enter the 4-digit code (twice)")
                stepLine(4, "Skip Apple ID recovery when asked")
            }
        }
    }

    private func stepLine(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
            Text("\(n)")
                .font(Theme.Typography.monoCaption)
                .foregroundStyle(Theme.onAccent)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Theme.accent))
            Text(text)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
        }
    }

    private var disclosureCard: some View {
        // §4 / §9 honest disclosure.
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle.fill").foregroundStyle(Theme.textSecondary)
            Text("This also locks deleting **all** apps, not just Bedrock — Apple doesn't allow a single-app lock. You can reverse it any time through the gauntlet.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.slate.opacity(0.4)))
    }

    private var openSettingsButton: some View {
        Button("Open Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        .buttonStyle(.bedrockGlass)
    }
}

/// Reveals one digit of the code at a time — tapping a slot shows its digit
/// briefly, so the user can enter it without memorizing the whole code.
private struct DigitReveal: View {
    let code: String
    @State private var revealed: Int?

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(Array(code.enumerated()), id: \.offset) { index, digit in
                Button {
                    reveal(index)
                } label: {
                    Text(revealed == index ? String(digit) : "•")
                        .font(.system(size: 34, weight: .semibold, design: .monospaced))
                        .foregroundStyle(revealed == index ? Theme.accent : Theme.textSecondary)
                        .frame(width: 60, height: 72)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.basalt))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.hairline))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Digit \(index + 1)")
                .accessibilityHint("Reveals briefly")
            }
        }
        .overlay(alignment: .bottom) {
            Text("Tap a slot to reveal that digit")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .offset(y: 26)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    private func reveal(_ index: Int) {
        revealed = index
        BedrockHaptics.selection()
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if revealed == index { revealed = nil }
        }
    }
}
