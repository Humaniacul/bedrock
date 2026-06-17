import SwiftUI
import FamilyControls

// Reused onboarding beats. (Hook/Reframe/Personalize/Why were replaced by the
// data-driven flow in OnboardingFlow.swift + Beats/.) These three are still
// referenced by the container: `.layers`, `.raiseWall`, `.dayZero`.

// MARK: - Beat: How Bedrock holds (the four layers)

struct MechanismStep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void

    private struct Layer {
        let name: String, detail: String, icon: String, premium: Bool
    }
    private let layers: [Layer] = [
        .init(name: "The Wall", detail: "Blocks the apps and sites you choose.", icon: "shield.fill", premium: false),
        .init(name: "The Lock", detail: "Strict Mode you can't undo in a weak moment.", icon: "lock.fill", premium: true),
        .init(name: "The Partner", detail: "Someone quietly in your corner.", icon: "person.2.fill", premium: true),
        .init(name: "The Watch", detail: "Learns your danger windows and gets ahead of them.", icon: "eye.fill", premium: true),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer()
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Willpower is one layer.")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                Text("Bedrock stacks four — so when one gives, the others hold.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
            }
            .riseIn(0, reduceMotion: reduceMotion)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(layers.enumerated()), id: \.offset) { index, layer in
                    layerRow(layer)
                        .riseIn(0.2 + Double(index) * 0.18, reduceMotion: reduceMotion)
                }
            }
            Spacer()
            Button("Let's build it") { onNext() }
                .buttonStyle(.bedrockPrimary)
                .riseIn(0.2 + Double(layers.count) * 0.18, reduceMotion: reduceMotion)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xl)
    }

    private func layerRow(_ layer: Layer) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: layer.icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(layer.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(layer.detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Theme.Spacing.sm)
            Text(layer.premium ? "PREMIUM" : "FREE")
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .tracking(1)
                .foregroundStyle(layer.premium ? Theme.accent : Theme.textSecondary)
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.slate.opacity(0.5)))
    }
}

// MARK: - Beat: Raise the wall (the free win + activation)

struct ProtectStep: View {
    @Environment(AppServices.self) private var services
    var onNext: () -> Void

    @State private var showPicker = false
    @State private var authorizing = false

    private var blocking: BlockingService { services.blocking }

    private var selectionBinding: Binding<FamilyActivitySelection> {
        Binding(get: { blocking.selection }, set: { blocking.selection = $0 })
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("Raise the wall")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
            Text("Your first layer — free, forever. Pick the apps and sites that pull you in, and Bedrock keeps them behind a wall.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            actions
        }
        .padding(Theme.Spacing.xl)
        .familyActivityPicker(isPresented: $showPicker, selection: selectionBinding)
    }

    @ViewBuilder private var actions: some View {
        switch blocking.authState {
        case .unavailable:
            note("Screen Time runs on a real iPhone — we'll finish raising the wall there.")
            Button("Continue") { onNext() }.buttonStyle(.bedrockPrimary)
        case .denied:
            note("Screen Time access is off. You can enable it later in Settings → Screen Time.")
            Button("Continue") { onNext() }.buttonStyle(.bedrockPrimary)
        case .notDetermined:
            Button(authorizing ? "Requesting…" : "Choose what to block") { authorizeThenPick() }
                .buttonStyle(.bedrockPrimary)
                .disabled(authorizing)
            Button("I'll set this up later") { onNext() }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
        case .approved:
            if blocking.blockedItemCount == 0 {
                Button("Choose what to block") { showPicker = true }.buttonStyle(.bedrockPrimary)
                Button("I'll set this up later") { onNext() }
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Text("\(blocking.blockedItemCount) apps & sites selected")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                if blocking.isProtected {
                    Label("Protection on", systemImage: "checkmark.shield.fill")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.accent)
                    Button("Continue") { onNext() }.buttonStyle(.bedrockPrimary)
                } else {
                    Button("Turn on protection") {
                        blocking.applyProtection()
                        BedrockHaptics.set()
                    }
                    .buttonStyle(.bedrockPrimary)
                    Button("Edit selection") { showPicker = true }
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.bottom, Theme.Spacing.sm)
    }

    private func authorizeThenPick() {
        authorizing = true
        Task {
            try? await blocking.requestAuthorization()
            authorizing = false
            if blocking.authState == .approved { showPicker = true }
        }
    }
}

// MARK: - Beat: Day Zero (commit)

struct CommitStep: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: OnboardingModel
    var onDone: () -> Void

    private var hasWhy: Bool { !model.why.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            FoundationMonolith(foundationDays: 1, hasCrack: false)
                .frame(maxHeight: 200)
                .riseIn(0, reduceMotion: reduceMotion)
            Text("DAY ZERO")
                .font(Theme.Typography.monoCaption)
                .tracking(4)
                .foregroundStyle(Theme.textSecondary)
                .riseIn(0.2, reduceMotion: reduceMotion)
            Text("The foundation is set.")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .riseIn(0.35, reduceMotion: reduceMotion)
            Text(hasWhy
                 ? "You carved your reason in stone. We'll hold you to it — gently, and for as long as it takes."
                 : "One day at a time, the foundation rises. Welcome to Bedrock.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .riseIn(0.5, reduceMotion: reduceMotion)
            Spacer()
            Button("I'm in") { onDone() }
                .buttonStyle(.bedrockPrimary)
                .riseIn(0.7, reduceMotion: reduceMotion)
        }
        .padding(Theme.Spacing.xl)
    }
}
