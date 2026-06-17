import SwiftUI

/// Settings (§7). Membership management (required by App Store review),
/// commitment editing, the on-device privacy story, support, and about.
struct SettingsView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.openURL) private var openURL

    @State private var editingLetter = false
    @State private var editingContact = false
    @State private var showPaywall = false
    @State private var restoring = false
    @State private var showDeleteConfirm = false
    @State private var deleting = false

    private let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
    private let supportURL = URL(string: "mailto:support@thebedrock.app")!
    private let privacyURL = URL(string: "https://thebedrock.app/privacy")!
    private let termsURL = URL(string: "https://thebedrock.app/terms")!

    var body: some View {
        NavigationStack {
            ZStack {
                StoneBackground()
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        membershipSection
                        commitmentSection
                        privacySection
                        supportSection
                        dangerSection
                        aboutSection
                        #if DEBUG
                        debugSection
                        #endif
                    }
                    .padding(Theme.Spacing.xl)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $editingLetter) { LetterEditor(text: letterBinding) }
            .sheet(isPresented: $editingContact) { SupportContactSheet() }
            .sheet(isPresented: $showPaywall) { PaywallView(context: .gate(.general)) }
            .alert("Delete everything?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account, your accountability links, and all data on this device and our servers — your foundation, streak, and settings can't be recovered. It won't cancel an active subscription; manage that in your Apple ID settings.")
            }
        }
    }

    // MARK: - Danger zone (App Store Guideline 5.1.1(v))

    private var dangerSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                sectionHeader("Account")
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "trash").frame(width: 28)
                        Text(deleting ? "Deleting…" : "Delete my account & data")
                            .font(Theme.Typography.body)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(.red)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(deleting)
            }
        }
    }

    // MARK: - Membership

    private var membershipSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                sectionHeader("Membership")
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: services.paywall.isPremium ? "checkmark.seal.fill" : "seal")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(services.paywall.isPremium ? "Premium active" : "Free plan")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text(services.paywall.isPremium
                             ? "Thank you for building with us."
                             : "Basic blocking is on. Unlock the rest when you're ready.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)

                if services.paywall.isPremium {
                    Divider().overlay(Theme.hairline)
                    actionRow("creditcard", "Manage subscription") { openURL(manageSubscriptionsURL) }
                } else {
                    Button("Unlock Premium") { showPaywall = true }
                        .buttonStyle(.bedrockPrimary)
                }
                Divider().overlay(Theme.hairline)
                actionRow(restoring ? "arrow.clockwise" : "arrow.clockwise.circle",
                          restoring ? "Restoring…" : "Restore purchases") { restore() }
            }
        }
    }

    // MARK: - Commitment

    private var commitmentSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                sectionHeader("Your commitment")
                navRow("text.quote", "Letter from your committed self",
                       "Played back at your weakest moment") { editingLetter = true }
                Divider().overlay(Theme.hairline)
                navRow("phone.fill", "Person you call",
                       services.supportContact.contact?.name ?? "Not set yet") { editingContact = true }
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                sectionHeader("Privacy")
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.accent)
                        .frame(width: 28)
                    Text("Your blocking choices, streak, and trigger patterns stay on this device — we never see them. Accountability syncs only what your partner needs to support you.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                linkRow("hand.raised", "Privacy Policy", privacyURL)
            }
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                sectionHeader("Support")
                actionRow("envelope", "Contact support") { openURL(supportURL) }
                Divider().overlay(Theme.hairline)
                linkRow("doc.text", "Terms of Use", termsURL)
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(versionString)
                .font(Theme.Typography.monoCaption)
                .foregroundStyle(Theme.textSecondary)
            Text("Built one layer at a time.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "Bedrock \(version) (\(build))"
    }

    // MARK: - Reusable rows

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(Theme.Typography.monoCaption)
            .tracking(2)
            .foregroundStyle(Theme.textSecondary)
    }

    /// Tappable row that performs an in-app action.
    private func actionRow(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon).foregroundStyle(Theme.accent).frame(width: 28)
                Text(title).font(Theme.Typography.body).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Tappable row that opens a detail sheet (shows a value + chevron).
    private func navRow(_ icon: String, _ title: String, _ detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon).foregroundStyle(Theme.accent).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.Typography.body).foregroundStyle(Theme.textPrimary)
                    Text(detail).font(Theme.Typography.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(title)")
    }

    private func linkRow(_ icon: String, _ title: String, _ url: URL) -> some View {
        actionRow(icon, title) { openURL(url) }
    }

    // MARK: - Actions

    private func restore() {
        guard !restoring else { return }
        restoring = true
        Task {
            _ = await services.paywall.restore()
            restoring = false
        }
    }

    private func deleteAccount() {
        guard !deleting else { return }
        deleting = true
        // onWipe rebuilds the app from a clean graph and lands back in onboarding,
        // so this view is torn down on completion.
        Task { await services.deleteAccountAndData() }
    }

    private var letterBinding: Binding<String> {
        Binding(get: { services.commitment.letter }, set: { services.commitment.letter = $0 })
    }

    // MARK: - DEBUG

    #if DEBUG
    private var debugSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                sectionHeader("Debug")
                actionRow("crown", services.paywall.isPremium ? "Set free" : "Set premium") {
                    services.paywall.debugSetPremium(!services.paywall.isPremium)
                }
                Divider().overlay(Theme.hairline)
                actionRow("arrow.counterclockwise", "Replay onboarding") { OnboardingModel.debugReset() }
                Divider().overlay(Theme.hairline)
                actionRow("chart.bar", "Seed trigger samples") { services.triggers.debugSeedSamples() }
            }
        }
    }
    #endif
}

#Preview {
    SettingsView().environment(AppServices.makeStub())
}
