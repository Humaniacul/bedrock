import FamilyControls
import SwiftUI

/// The Protection screen (§7) — the user-facing blocking core. Walks Screen Time
/// authorization, lets the user choose what to block (FamilyActivityPicker),
/// toggles the Safari adult-content filter, and shows which layers are live.
/// Strict Mode + the gauntlet (Phase 2) attach here later.
struct ProtectionView: View {
    @Environment(AppServices.self) private var services
    @State private var isPickerPresented = false
    @State private var isAuthorizing = false
    @State private var errorMessage: String?

    private var blocking: BlockingService { services.blocking }

    var body: some View {
        NavigationStack {
            ZStack {
                StoneBackground()
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        switch blocking.authState {
                        case .approved:
                            configuration
                        case .notDetermined:
                            authPrompt
                        case .denied:
                            authDenied
                        case .unavailable:
                            authUnavailable
                        }
                    }
                    .padding(Theme.Spacing.xl)
                }
            }
            .navigationTitle("Protection")
            .navigationBarTitleDisplayMode(.large)
            .familyActivityPicker(isPresented: $isPickerPresented, selection: selectionBinding)
            .alert("Couldn’t turn on access", isPresented: errorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Authorized configuration

    private var configuration: some View {
        VStack(spacing: Theme.Spacing.lg) {
            statusHeader

            GlassCard {
                VStack(spacing: Theme.Spacing.lg) {
                    Button {
                        isPickerPresented = true
                    } label: {
                        settingRow(
                            icon: "apps.iphone",
                            title: "Apps & sites to block",
                            detail: blocking.blockedItemCount == 0
                                ? "Choose what to block"
                                : "\(blocking.blockedItemCount) selected",
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().overlay(Theme.hairline)

                    Toggle(isOn: safariBinding) {
                        settingRow(
                            icon: "safari.fill",
                            title: "Safari adult-content filter",
                            detail: "Blocks explicit sites system-wide",
                            showsChevron: false
                        )
                    }
                    .tint(Theme.accent)
                }
            }

            primaryAction
            strictModeLink
        }
    }

    private var strictModeLink: some View {
        NavigationLink {
            StrictModeView()
        } label: {
            GlassCard {
                HStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: services.strictMode.isEnabled ? "lock.shield.fill" : "lock.open")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Strict Mode")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.textPrimary)
                        Text(services.strictMode.isEnabled
                            ? "On — disabling means the gauntlet"
                            : "Lock protection so you can't quietly remove it")
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

    private var statusHeader: some View {
        GlassCard(tint: blocking.isProtected ? Theme.accent : nil) {
            HStack(spacing: Theme.Spacing.lg) {
                Image(systemName: blocking.isProtected ? "shield.lefthalf.filled" : "shield.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(blocking.isProtected ? Theme.accent : Theme.textSecondary)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(blocking.isProtected ? "Protection is on" : "Protection is off")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(blocking.isProtected
                        ? "Your chosen apps and sites are shielded."
                        : "Pick what to block, then turn it on.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var primaryAction: some View {
        Group {
            if blocking.isProtected {
                Button("Pause protection") { blocking.clearProtection() }
                    .buttonStyle(.bedrockGlass)
            } else {
                Button("Turn on protection") { blocking.applyProtection() }
                    .buttonStyle(.bedrockPrimary)
                    .disabled(blocking.blockedItemCount == 0 && !blocking.safariFilterEnabled)
            }
        }
    }

    // MARK: - Authorization states

    private var authPrompt: some View {
        gateCard(
            icon: "lock.shield",
            title: "Turn on Screen Time access",
            body: "Bedrock uses Screen Time to shield the apps and sites you choose. Nothing you browse ever leaves your phone.",
            actionTitle: isAuthorizing ? "Requesting…" : "Grant access"
        ) {
            Task { await authorize() }
        }
    }

    private var authDenied: some View {
        gateCard(
            icon: "exclamationmark.shield",
            title: "Screen Time access is off",
            body: "Enable Screen Time for Bedrock in Settings, then come back to choose what to block.",
            actionTitle: "Open Settings"
        ) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }

    private var authUnavailable: some View {
        gateCard(
            icon: "iphone.gen3.slash",
            title: "Needs a real iPhone",
            body: "Screen Time isn’t available in the Simulator. Run Bedrock on a device to set up protection.",
            actionTitle: nil,
            action: nil
        )
    }

    // MARK: - Building blocks

    private func gateCard(
        icon: String,
        title: String,
        body: String,
        actionTitle: String?,
        action: (() -> Void)?
    ) -> some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.lg) {
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
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.bedrockPrimary)
                        .disabled(isAuthorizing)
                }
            }
        }
    }

    private func settingRow(icon: String, title: String, detail: String, showsChevron: Bool) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Actions & bindings

    private func authorize() async {
        isAuthorizing = true
        defer { isAuthorizing = false }
        do {
            try await blocking.requestAuthorization()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var selectionBinding: Binding<FamilyActivitySelection> {
        Binding(get: { blocking.selection }, set: { blocking.selection = $0 })
    }

    private var safariBinding: Binding<Bool> {
        Binding(get: { blocking.safariFilterEnabled }, set: { blocking.safariFilterEnabled = $0 })
    }

    private var errorPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }
}

#Preview("Authorized") {
    ProtectionView().environment(AppServices.makeStub())
}
