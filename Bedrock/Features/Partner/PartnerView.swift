import SwiftUI

/// The Partner screen (§4, §7). Two roles in one screen: invite/see your own
/// partner, and — for someone who accepted an invite — a supportive dashboard of
/// the people they support plus an approvals inbox. Honest "not connected" state
/// when no backend is configured.
struct PartnerView: View {
    @Environment(AppServices.self) private var services
    @State private var inviteInfo: InviteInfo?
    @State private var acceptCode = ""
    @State private var isWorking = false

    private var acc: AccountabilityService { services.accountability }

    var body: some View {
        NavigationStack {
            ZStack {
                StoneBackground()
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        if acc.isConfigured {
                            myPartnerCard
                            inviteCard
                            acceptCard
                            if !acc.pendingApprovals.isEmpty { approvalsSection }
                            if !acc.supporting.isEmpty { supportingSection }
                        } else {
                            notConnectedCard
                        }
                    }
                    .padding(Theme.Spacing.xl)
                }
            }
            .navigationTitle("Partner")
            .task { await acc.refresh() }
            .refreshable { await acc.refresh() }
            .sheet(item: $inviteInfo) { info in InviteShareSheet(info: info) }
        }
    }

    // MARK: My partner

    private var myPartnerCard: some View {
        GlassCard(tint: acc.hasPartner ? Theme.accent : nil) {
            HStack(spacing: Theme.Spacing.lg) {
                Image(systemName: acc.hasPartner ? "person.2.fill" : "person.2")
                    .font(.system(size: 28))
                    .foregroundStyle(acc.hasPartner ? Theme.accent : Theme.textSecondary)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(acc.hasPartner ? "\(acc.partnerName ?? "Your partner") has your back" : "No partner yet")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(acc.hasPartner
                        ? "They’re notified, supportively, if a layer drops."
                        : "The men who make it don’t do it alone.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var inviteCard: some View {
        Button {
            Task {
                isWorking = true
                inviteInfo = await acc.createInvite()
                isWorking = false
            }
        } label: {
            GlassCard {
                settingRow("envelope.fill", "Invite a partner", "Share a code with someone you trust", chevron: true)
            }
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
    }

    private var acceptCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                settingRow("person.badge.plus", "Support someone", "Enter their invite code to become their partner")
                HStack(spacing: Theme.Spacing.md) {
                    TextField("Code", text: $acceptCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(Theme.Typography.mono)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(Theme.Spacing.md)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(BedrockColor.basalt))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm).strokeBorder(Theme.hairline))
                    Button("Join") {
                        Task {
                            isWorking = true
                            if await acc.acceptInvite(code: acceptCode.trimmingCharacters(in: .whitespaces)) {
                                acceptCode = ""
                            }
                            isWorking = false
                        }
                    }
                    .buttonStyle(.bedrockGlass)
                    .frame(width: 92)
                    .disabled(acceptCode.count < 4 || isWorking)
                }
            }
        }
    }

    // MARK: Partner-role dashboard

    private var approvalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader("Approvals waiting on you")
            ForEach(acc.pendingApprovals) { request in
                GlassCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("\(request.name ?? "Your person") wants to turn off protection")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.textPrimary)
                        if let reason = request.reason, !reason.isEmpty {
                            Text("“\(reason)”")
                                .font(Theme.Typography.callout)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        HStack(spacing: Theme.Spacing.md) {
                            Button("Approve") { respond(request, approve: true) }
                                .buttonStyle(.bedrockPrimary)
                            Button("Not yet") { respond(request, approve: false) }
                                .buttonStyle(.bedrockGlass)
                        }
                    }
                }
            }
        }
    }

    private var supportingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader("You’re supporting")
            ForEach(acc.supporting) { person in
                GlassCard {
                    HStack(spacing: Theme.Spacing.lg) {
                        Circle()
                            .fill(person.protectionActive ? BedrockColor.mineral : BedrockColor.bronze)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(person.name ?? "Your person")
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.textPrimary)
                            Text(statusLine(person))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    // MARK: Not connected

    private var notConnectedCard: some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
                Text("Partner features need the backend")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Invites, supportive alerts, and approvals turn on once the Bedrock backend is deployed and the app is pointed at it.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: Pieces

    private func respond(_ request: PendingApproval, approve: Bool) {
        Task { await acc.respondToApproval(id: request.id, approve: approve) }
    }

    private func statusLine(_ person: SupportedPerson) -> String {
        var parts = [person.protectionActive ? "Protected" : "Protection off"]
        if person.strictEnabled { parts.append("Strict") }
        if let last = person.lastHeartbeat {
            parts.append("seen \(last.formatted(.relative(presentation: .named)))")
        }
        return parts.joined(separator: " · ")
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

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
}

extension InviteInfo: Identifiable { public var id: String { code } }

private struct InviteShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let info: InviteInfo

    var body: some View {
        NavigationStack {
            ZStack {
                StoneBackground()
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()
                    Text("Share this code")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                    Text(info.code)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accent)
                        .tracking(8)
                    Text("They open Bedrock, tap “Support someone”, and enter it.")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                    ShareLink(item: URL(string: info.url) ?? URL(string: "https://thebedrock.app")!) {
                        Text("Share link").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bedrockPrimary)
                }
                .padding(Theme.Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PartnerView().environment(AppServices.makeStub())
}
