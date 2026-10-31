import SwiftUI

// Supporter · The person who holds the key (SPEC.md SP1–SP4), and the supporter
// home they land on. The supporter never sees a paywall, a price, or the user's
// answers.

// MARK: - SP1 · Someone asked you

struct SupporterWelcomeScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services

    @State private var code = ""
    @State private var error: String?
    @State private var working = false
    @FocusState private var fieldFocused: Bool

    /// Opened from a /join/CODE link: the code is already known.
    private var linkedCode: String? { flow.supporterCode }
    private var field: [String] { OnbCopy.parts("onb.sp1.code_field_from_s1") }
    private var typedCode: String {
        code.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    var body: some View {
        OnboardingScaffold(.sp1, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s7) {
                StoneMark()
                    .fill(LinearGradient(colors: [BedrockColor.emberGlow, BedrockColor.ember],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: BedrockSize.stoneMark.width, height: BedrockSize.stoneMark.height)
                    .bedrockAppear(.settle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(OnbCopy.string("onb.sp1.eyebrow"))
                        .bedrockEyebrow()
                        .padding(.bottom, Space.s3)
                    CarveText(OnbCopy.string("onb.sp1.headline"), delay: 0.1, font: BedrockFont.title)
                        .lineSpacing(BedrockLine.title.lineSpacing)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(OnbCopy.string("onb.sp1.body"))
                        .font(BedrockFont.body)
                        .lineSpacing(BedrockLine.body.lineSpacing)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Space.s4)
                        .bedrockAppear(.rise, delay: 0.5)
                }
                if linkedCode == nil { codeField }
                if let error {
                    Text(error)
                        .font(BedrockFont.subhead)
                        .foregroundStyle(BedrockColor.emberGlow)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .animation(BedrockMotion.reducedFade, value: error)
        } footer: {
            PrimaryButton(title: linkedCode == nil ? (field.last ?? "") : OnbCopy.string("onb.sp1.primary"),
                          isEnabled: linkedCode != nil || typedCode.count >= 4,
                          isLoading: working) {
                Task { await accept() }
            }
        }
        .task { flow.track(.supStarted(source: linkedCode == nil ? .organic : .inviteLink)) }
        .environment(\.onboardingScrollAnchor, fieldFocused ? .bottom : nil)
    }

    private var codeField: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(field.first ?? "")
                .bedrockEyebrow()
            TextField(field.dropFirst().first ?? "", text: $code)
                .focused($fieldFocused)
                .font(BedrockFont.digits)
                .foregroundStyle(BedrockColor.inkPrimary)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .onSubmit { Task { await accept() } }
                .padding(.horizontal, Space.s4)
                .frame(minHeight: BedrockSize.chipMinHeight)
                .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
                .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(fieldFocused ? BedrockColor.ember : BedrockColor.lineStrong, lineWidth: 1))
                .onChange(of: code) { _, _ in error = nil }
        }
    }

    private func accept() async {
        guard let invite = linkedCode ?? (typedCode.isEmpty ? nil : typedCode), !working else { return }
        working = true
        fieldFocused = false
        let result = await services.accountability.accept(code: invite)
        working = false
        switch result {
        case .accepted:
            flow.update { $0.supporterPaired = true }
            flow.go(.sp2)
        case .alreadyUsed:
            error = OnbCopy.string("onb.sp1.code_used")
        case .invalid:
            error = OnbCopy.string("onb.sp1.bad_code")
        case .unreachable:
            error = OnbCopy.string("onb.sp1.offline")
        }
        if error != nil { BedrockHaptics.needsAction() }
    }
}

// MARK: - SP2 · What you'll see, and won't

struct SupporterTermsScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s7))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Space.s4))
        OnboardingScaffold(.sp2, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s8) {
                ScreenHeading(headline: OnbCopy.string("onb.sp2.headline"))
                layout {
                    TermsColumn(title: OnbCopy.string("onb.sp2.youll_see_title"),
                                items: OnbCopy.parts("onb.sp2.youll_see"),
                                glyph: "eye", tint: BedrockColor.emberGlow)
                        .bedrockAppear(.strata(index: 0))
                    TermsColumn(title: OnbCopy.string("onb.sp2.you_wont_see_title"),
                                items: OnbCopy.parts("onb.sp2.you_wont_see"),
                                glyph: "eye.slash", tint: BedrockColor.inkTertiary)
                        .bedrockAppear(.strata(index: 1), delay: 0.03)
                }
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.sp2.primary")) { flow.go(.sp3) }
        }
        .task { flow.track(.supTermsViewed) }
    }
}

private struct TermsColumn: View {
    let title: String
    let items: [String]
    let glyph: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Text(title)
                .bedrockEyebrow(color: tint)
                .accessibilityAddTraits(.isHeader)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: Space.s2) {
                    Image(systemName: glyph)
                        .font(BedrockFont.footnote.weight(.semibold))
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(BedrockFont.subhead)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineSubtle))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - SP3 · Alerts

struct SupporterAlertsScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @State private var asking = false

    var body: some View {
        OnboardingScaffold(.sp3, flow: flow, back: false) {
            ScreenHeading(headline: OnbCopy.string("onb.sp3.headline"),
                          text: OnbCopy.string("onb.sp3.body"))
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.sp3.primary"), isLoading: asking) {
                Task {
                    asking = true
                    let granted = await NotificationPermission.request()
                    asking = false
                    flow.track(.supNotifResult(granted: granted))
                    flow.go(.sp4)
                }
            }
        }
    }
}

// MARK: - SP4 · You're their person

struct SupporterDoneScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @State private var notificationsOff = false

    var body: some View {
        OnboardingScaffold(.sp4, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s6) {
                ScreenHeading(headline: OnbCopy.string("onb.sp4.headline"))
                SupporterStatusCard(person: services.accountability.supporting.first)
                    .bedrockAppear(.settle)
                SupporterNotes(notificationsOff: notificationsOff)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.sp4.primary")) {
                flow.track(.supCompleted)
                flow.endSupporter()
            }
        }
        .task {
            notificationsOff = await NotificationPermission.status() == .denied
            await services.accountability.refresh()
            try? await Task.sleep(for: .seconds(0.4))
            BedrockHaptics.stoneLands()
        }
    }
}

/// SP4 and the supporter home: how a request works, the 3-day rule, and the
/// honest note that “goes quiet” arrives hours later, not instantly.
private struct SupporterNotes: View {
    let notificationsOff: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Text(OnbCopy.string("onb.sp4.body"))
                .font(BedrockFont.body)
                .lineSpacing(BedrockLine.body.lineSpacing)
                .foregroundStyle(BedrockColor.inkSecondary)
            Text(OnbCopy.string("onb.sp4.quiet_note"))
                .font(BedrockFont.subhead)
                .foregroundStyle(BedrockColor.inkTertiary)
            if notificationsOff {
                Text(OnbCopy.string("onb.sp4.notif_denied"))
                    .font(BedrockFont.subhead)
                    .foregroundStyle(BedrockColor.emberGlow)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// “Wall up · Checked in 2 hours ago”, read as one element.
struct SupporterStatusCard: View {
    let person: SupportedPerson?

    private var isUp: Bool { person?.protectionActive ?? false }

    private var checked: String {
        guard let last = person?.lastHeartbeat else { return OnbCopy.string("onb.sp4.checked_never") }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return OnbCopy.string("onb.sp4.checked")
            .replacingOccurrences(of: "{time}", with: formatter.localizedString(for: last, relativeTo: .now))
    }

    var body: some View {
        HStack(spacing: Space.s4) {
            Circle()
                .fill(isUp ? BedrockColor.emberGlow : BedrockColor.inkTertiary)
                .frame(width: BedrockSize.statusDot * 1.6, height: BedrockSize.statusDot * 1.6)
                .shadow(color: isUp ? BedrockColor.emberGlow.opacity(0.6) : .clear, radius: 4)
            VStack(alignment: .leading, spacing: Space.s1) {
                Text(OnbCopy.string(isUp ? "onb.sp4.status_up" : "onb.sp4.status_down"))
                    .font(BedrockFont.headline)
                    .foregroundStyle(BedrockColor.inkPrimary)
                Text(checked)
                    .font(BedrockFont.subhead)
                    .foregroundStyle(BedrockColor.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Space.s5)
        .frame(minHeight: BedrockSize.homeCardMinHeight)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineSubtle))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Supporter home

/// Where a supporter lands after SP4, and what they see on later opens: each
/// person's status, any request to answer, and the 3-day rule. Same world as
/// onboarding, without its copy.
struct SupporterHomeView: View {
    @Environment(AppServices.self) private var services
    /// A supporter who hasn't built a wall of their own (shown instead of the tabs).
    var standalone = false
    var onBuildWall: (() -> Void)?
    var onAddPerson: (() -> Void)?

    @State private var notificationsOff = false
    @State private var answering: String?

    private var accountability: AccountabilityService { services.accountability }

    var body: some View {
        ZStack {
            OnboardingBackdrop(level: Dawn.level(for: .sp4))
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s6) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(OnbCopy.string("onb.sp_home.eyebrow"))
                            .bedrockEyebrow()
                            .padding(.bottom, Space.s3)
                        Text(OnbCopy.string("onb.sp4.headline"))
                            .font(BedrockFont.title)
                            .foregroundStyle(BedrockColor.inkPrimary)
                            .accessibilityAddTraits(.isHeader)
                    }
                    if accountability.supporting.isEmpty {
                        SupporterStatusCard(person: nil)
                    } else {
                        ForEach(accountability.supporting) { person in
                            SupporterStatusCard(person: person)
                        }
                    }
                    if accountability.pendingApprovals.isEmpty {
                        Text(OnbCopy.string("onb.sp_home.empty"))
                            .font(BedrockFont.subhead)
                            .foregroundStyle(BedrockColor.inkTertiary)
                    } else {
                        ForEach(accountability.pendingApprovals) { request in
                            RequestCard(isWorking: answering == request.id) { approve in
                                Task { await answer(request.id, approve: approve) }
                            }
                        }
                    }
                    SupporterNotes(notificationsOff: notificationsOff)
                    VStack(alignment: .leading, spacing: Space.s1) {
                        if let onAddPerson {
                            let parts = OnbCopy.parts("onb.sp_home.invite")
                            LinkButton(title: parts.last ?? "", tone: .secondary, action: onAddPerson)
                                .accessibilityHint(parts.first ?? "")
                        }
                        if standalone, let onBuildWall {
                            LinkButton(title: OnbCopy.parts("onb.sp_home.own_wall").last ?? "", tone: .secondary,
                                       action: onBuildWall)
                                .accessibilityHint(OnbCopy.parts("onb.sp_home.own_wall").first ?? "")
                        }
                    }
                }
                .padding(.horizontal, Space.s6)
                .padding(.top, Space.s8)
                .padding(.bottom, Space.s10)
            }
            .scrollBounceBehavior(.basedOnSize)
            .refreshable { await accountability.refresh() }
        }
        .task {
            notificationsOff = await NotificationPermission.status() == .denied
            while !Task.isCancelled {
                await accountability.refresh()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private func answer(_ id: String, approve: Bool) async {
        answering = id
        BedrockHaptics.select()
        await accountability.respondToApproval(id: id, approve: approve)
        answering = nil
    }
}

/// “They're asking to turn it off.” · the 3-day rule · Approve · Not yet.
private struct RequestCard: View {
    let isWorking: Bool
    let respond: (Bool) -> Void

    var body: some View {
        let parts = OnbCopy.parts("onb.sp_home.request")
        let item: (Int) -> String = { parts.indices.contains($0) ? parts[$0] : "" }
        VStack(alignment: .leading, spacing: Space.s3) {
            Text(item(0))
                .font(BedrockFont.headline)
                .foregroundStyle(BedrockColor.inkPrimary)
            Text(item(1))
                .font(BedrockFont.subhead)
                .foregroundStyle(BedrockColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Space.s3) {
                TextButton(title: item(3), fullWidth: true) { respond(false) }
                    .background(Capsule().strokeBorder(BedrockColor.lineStrong))
                PrimaryButton(title: item(2), isLoading: isWorking) { respond(true) }
            }
        }
        .padding(Space.s5)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.emberWash))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.emberDeep))
    }
}
