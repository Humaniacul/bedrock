import Foundation
import SwiftUI

/// Runs the disable gauntlet (§4). Presents each step, advances the coordinator,
/// resets the cooldown if the app is backgrounded, and on completion lifts
/// protection and reveals the release path (Model B reveals the code; Model A
/// hands off to the partner). Backing out before completion just keeps
/// protection on — that's not a bypass.
struct DisableGauntletView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let coordinator: GauntletCoordinator
    @State private var didRelease = false
    @State private var approvalIds: [String] = []
    @State private var serverCooldownId: String?

    var body: some View {
        ZStack {
            StoneBackground()
            if coordinator.isComplete {
                completionScreen
            } else {
                VStack(spacing: 0) {
                    header
                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                        .id(coordinator.current)
                }
            }
        }
        .animation(.smooth, value: coordinator.index)
        .onChange(of: coordinator.isComplete) { _, complete in
            if complete { performRelease() }
        }
        .onChange(of: scenePhase) { _, phase in
            // §4: leaving during the cooldown restarts it.
            if phase != .active, coordinator.current == .cooldown {
                coordinator.cooldown.resetForBackground()
            }
        }
        .task(id: coordinator.index) { await driveBackend(for: coordinator.current) }
    }

    // Backend work for the current step (only when a backend is configured).
    private func driveBackend(for step: GauntletStep?) async {
        guard services.accountability.isConfigured else { return }
        switch step {
        case .cooldown:
            serverCooldownId = await services.accountability.startServerCooldown(seconds: coordinator.cooldownSeconds)
        case .partnerApproval:
            approvalIds = await services.accountability.requestApproval()
            while !Task.isCancelled {
                if await services.accountability.pollApproval(ids: approvalIds) == .approved {
                    coordinator.completeCurrent()
                    return
                }
                try? await Task.sleep(for: .seconds(4))
            }
        default:
            break
        }
    }

    private func verifyCooldown() async -> Bool {
        guard let id = serverCooldownId else { return true }
        return await services.accountability.serverCooldownComplete(id: id)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityLabel("Keep protection on")
                Spacer()
                Text("Step \(coordinator.stepNumber) of \(coordinator.steps.count)")
                    .font(Theme.Typography.monoCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
            ProgressView(value: coordinator.progress)
                .tint(Theme.accent)
            if let title = coordinator.current?.title {
                Text(title)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.Spacing.xl)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch coordinator.current {
        case .futureSelf:
            FutureSelfStep(letter: services.commitment.letter) {
                coordinator.completeCurrent()
            }
        case .urgeSurf:
            UrgeSurfView { rating in
                logUrge(rating)
                coordinator.completeCurrent()
            }
        case .commitment:
            CommitmentTypingStep(sentences: passageSentences) {
                coordinator.completeCurrent()
            }
        case .partnerMessage:
            PartnerMessageStep { message in
                services.accountability.sendDisableReason(message)
                coordinator.completeCurrent()
            }
        case .cooldown:
            CooldownStep(
                cooldown: coordinator.cooldown,
                seconds: coordinator.cooldownSeconds,
                verify: services.accountability.isConfigured ? { await verifyCooldown() } : nil
            ) {
                coordinator.completeCurrent()
            }
        case .partnerApproval:
            PartnerApprovalStep {
                coordinator.completeCurrent()
            }
        case nil:
            EmptyView()
        }
    }

    private var passageSentences: [String] {
        Array(services.commitment.passage.prefix(coordinator.requiredSentences))
    }

    // MARK: Completion / release

    private func performRelease() {
        guard !didRelease else { return }
        didRelease = true
        services.blocking.clearProtection()
        services.strictMode.completeDisable()
    }

    private var completionScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.accent)
            Text("Protection lifted")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
            releaseInstructions
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.bedrockPrimary)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(Theme.Spacing.xl)
    }

    @ViewBuilder
    private var releaseInstructions: some View {
        switch services.strictMode.config.passcodeModel {
        case .appHeld:
            if let code = services.passcode.storedCode() {
                GlassCard {
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Your Screen Time passcode")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.textSecondary)
                        Text(code)
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                            .tracking(8)
                        Text("Open Settings → Screen Time → Turn Off Screen Time Passcode, and enter it.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        case .partnerHeld:
            Text("Ask your partner to turn off the Screen Time passcode in Settings.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        case .none:
            EmptyView()
        }
    }

    private func logUrge(_ rating: Int?) {
        // The user is riding out the urge as part of the disable gauntlet.
        services.triggers.log(
            TriggerEngine.Event(
                date: .now,
                trigger: "Gauntlet",
                urgeIntensity: rating,
                outcome: .surfed
            )
        )
    }
}
