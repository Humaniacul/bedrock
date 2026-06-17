import SwiftUI

/// Configures Strict Mode and launches the disable gauntlet (§4, §7). Lives
/// inside Protection's navigation stack.
struct StrictModeView: View {
    @Environment(AppServices.self) private var services

    @State private var pendingModel: PasscodeModel?
    @State private var gauntlet: GauntletCoordinator?
    @State private var showSleepBlocked = false
    @State private var editingLetter = false
    @State private var showPaywall = false

    private var strict: StrictModeService { services.strictMode }

    var body: some View {
        ZStack {
            StoneBackground()
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if strict.isEnabled {
                        enabledState
                    } else if services.paywall.isPremium {
                        setupState
                    } else {
                        premiumLockCard
                    }
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .navigationTitle("Strict Mode")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $pendingModel) { model in
            PasscodeSetupView(model: model) {
                strict.enable(model: model)
            }
        }
        .sheet(isPresented: $editingLetter) {
            LetterEditor(text: letterBinding)
        }
        .fullScreenCover(item: $gauntlet) { coordinator in
            DisableGauntletView(coordinator: coordinator)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .gate(.strictMode))
        }
        .alert("Not during the night", isPresented: $showSleepBlocked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You set disables to only work between \(strict.config.sleepWindow.startHour):00 and \(strict.config.sleepWindow.endHour):00. Sleep on it — come back when the window's open.")
        }
    }

    // MARK: - Premium gate (§8)

    private var premiumLockCard: some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
                Text("Make it unbreakable")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                Text("Strict Mode is part of Premium — the lock you can't undo in a weak moment, plus an accountability partner and insight into your danger windows.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Unlock with Premium") { showPaywall = true }
                    .buttonStyle(.bedrockPrimary)
                    .padding(.top, Theme.Spacing.xs)
                Text("Basic blocking stays free, always.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    // MARK: - Not yet enabled

    private var setupState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            GlassCard {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accent)
                    Text("Make it stick")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Strict Mode locks protection behind a passcode you can't quietly remove. Turning it off means walking the gauntlet — long enough to outlast the urge.")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Text("Who holds the key?")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            modelOption(
                .partnerHeld,
                icon: "person.2.fill",
                title: "A partner holds it",
                detail: "Someone you trust sets the passcode. Strongest lock."
            )
            modelOption(
                .appHeld,
                icon: "lock.rotation",
                title: "Bedrock holds it",
                detail: "The app generates a code you won't remember. Good for going solo."
            )
        }
    }

    private func modelOption(_ model: PasscodeModel, icon: String, title: String, detail: String) -> some View {
        Button {
            pendingModel = model
        } label: {
            GlassCard {
                HStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(title)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.textPrimary)
                        Text(detail)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Enabled

    private var enabledState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            GlassCard(tint: Theme.accent) {
                HStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Strict Mode is on")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text(strict.isUninstallLockOn ? "App deletion is locked." : "Passcode lock active.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            }

            settingsCard
            commitmentCard

            Button("Turn off protection") { beginDisable() }
                .buttonStyle(.bedrockGlass)

            Text("This launches the gauntlet — it always eventually releases.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var settingsCard: some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.lg) {
                Stepper(value: cooldownBinding, in: 30...120, step: 15) {
                    settingRow("timer", "Cooldown", "\(strict.config.baseCooldownMinutes) min (now \(strict.config.effectiveCooldownMinutes))")
                }
                Divider().overlay(Theme.hairline)
                Toggle(isOn: sleepEnabledBinding) {
                    settingRow("moon.zzz.fill", "Sleep on it", "Block disables outside daytime hours")
                }
                .tint(Theme.accent)
                if strict.config.sleepWindow.enabled {
                    HStack {
                        hourPicker("From", selection: Binding(
                            get: { strict.config.sleepWindow.startHour },
                            set: { v in strict.updateConfig { $0.sleepWindow.startHour = v } }
                        ))
                        hourPicker("To", selection: Binding(
                            get: { strict.config.sleepWindow.endHour },
                            set: { v in strict.updateConfig { $0.sleepWindow.endHour = v } }
                        ))
                    }
                }
            }
        }
    }

    private var commitmentCard: some View {
        Button { editingLetter = true } label: {
            GlassCard {
                settingRow("text.quote", "Letter from your committed self", "Played back at your weakest moment", chevron: true)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pieces

    private func settingRow(_ icon: String, _ title: String, _ detail: String, chevron: Bool = false) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title).font(Theme.Typography.body).foregroundStyle(Theme.textPrimary)
                Text(detail).font(Theme.Typography.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .contentShape(Rectangle())
    }

    private func hourPicker(_ label: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label).font(Theme.Typography.caption).foregroundStyle(Theme.textSecondary)
            Picker(label, selection: selection) {
                ForEach(0..<24, id: \.self) { Text("\($0):00").tag($0) }
            }
            .pickerStyle(.menu)
            .tint(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func beginDisable() {
        guard strict.canBeginDisable() else {
            showSleepBlocked = true
            return
        }
        gauntlet = strict.makeGauntlet(hasPartner: services.accountability.hasPartner)
    }

    // MARK: Bindings

    private var cooldownBinding: Binding<Int> {
        Binding(get: { strict.config.baseCooldownMinutes },
                set: { v in strict.updateConfig { $0.baseCooldownMinutes = v } })
    }

    private var sleepEnabledBinding: Binding<Bool> {
        Binding(get: { strict.config.sleepWindow.enabled },
                set: { v in strict.updateConfig { $0.sleepWindow.enabled = v } })
    }

    private var letterBinding: Binding<String> {
        Binding(get: { services.commitment.letter },
                set: { services.commitment.letter = $0 })
    }
}

/// `Identifiable` so `.sheet(item:)` / `.fullScreenCover(item:)` can drive it.
extension PasscodeModel: Identifiable { public var id: String { rawValue } }
extension GauntletCoordinator: Identifiable {}

/// Edits the future-self letter (reused by Settings). Internal, not private.
struct LetterEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String

    var body: some View {
        NavigationStack {
            ZStack {
                StoneBackground()
                TextEditor(text: $text)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Your letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
