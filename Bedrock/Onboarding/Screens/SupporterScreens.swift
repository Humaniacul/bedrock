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
        OnboardingScaffold(.sp1, flow: flow, back: linkedCode == nil, top: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if linkedCode != nil {
                    StoneMarkView()
                        .frame(width: 30, height: 36)
                        .padding(.top, ProtoLayout.controlTop)
                        .bedrockAppear(.settle, delay: 0.12)
                        .accessibilityHidden(true)
                }
                Spacer(minLength: ProtoLayout.topWithBack)
                VStack(alignment: .leading, spacing: 14) {
                    Eyebrow(text: OnbCopy.string("onb.sp1.eyebrow"))
                    CarveText(OnbCopy.string("onb.sp1.headline"))
                        .ptype(.titleL)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(OnbCopy.string("onb.sp1.body"))
                        .ptype(.body)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .bedrockAppear(.rise, delay: 0.5)
                }
                if linkedCode == nil {
                    codeField
                        .padding(.top, 28)
                }
                Color.clear.frame(height: (linkedCode == nil ? Space.s4 : 40) - Space.s2)
            }
        } footer: {
            PrimaryButton(title: linkedCode == nil ? (field.last ?? "") : OnbCopy.string("onb.sp1.primary"),
                          isEnabled: linkedCode != nil || typedCode.count >= 4,
                          isLoading: working) {
                Task { await accept() }
            }
            .bedrockAppear(.settle, delay: linkedCode == nil ? 0 : 0.8)
        }
        .task { flow.track(.supStarted(source: linkedCode == nil ? .organic : .inviteLink)) }
        .environment(\.onboardingScrollAnchor, fieldFocused ? .bottom : nil)
    }

    /// “Invite code” (13pt Ash), a 56pt field (Slate, radius 14, a 1.5pt edge
    /// that turns Glow on an error), the error in 14/20 Glow.
    private var codeField: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(field.first ?? "")
                .ptype(.footnotePlain)
                .foregroundStyle(BedrockColor.inkTertiary)
            TextField("", text: $code,
                      prompt: Text(field.dropFirst().first ?? "").foregroundStyle(BedrockColor.inkTertiary))
                .focused($fieldFocused)
                .ptype(PType(face: .sans, size: 17, line: nil, tracking: 0.5))
                .foregroundStyle(BedrockColor.inkPrimary)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .onSubmit { Task { await accept() } }
                .padding(.horizontal, Space.s4)
                .frame(minHeight: 56)
                .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
                .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(error != nil ? BedrockColor.emberGlow : BedrockColor.lineStrong, lineWidth: 1.5))
                .accessibilityLabel(field.first ?? "")
                .onChange(of: code) { _, _ in error = nil }
            if let error {
                Text(error)
                    .ptype(.note)
                    .foregroundStyle(BedrockColor.emberGlow)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .animation(BedrockMotion.reducedFade, value: error)
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
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
        OnboardingScaffold(.sp2, flow: flow, top: ProtoLayout.topWithBack) {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(headline: OnbCopy.string("onb.sp2.headline"))
                    .padding(.bottom, Space.s6)
                layout {
                    TermsColumn(title: OnbCopy.string("onb.sp2.youll_see_title"),
                                items: OnbCopy.parts("onb.sp2.youll_see"), sees: true)
                        .bedrockAppear(.strata(index: 0))
                    TermsColumn(title: OnbCopy.string("onb.sp2.you_wont_see_title"),
                                items: OnbCopy.parts("onb.sp2.you_wont_see"), sees: false)
                        .bedrockAppear(.strata(index: 1), delay: 0.02)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.sp2.primary")) { flow.go(.sp3) }
        }
        .task { flow.track(.supTermsViewed) }
    }
}

/// SP2's two cards: “You'll see” (warm: Ember Night, a Kiln edge, Glow
/// heading, Chalk items) and “You won't see” (Basalt, a Fault edge, Ash
/// heading, Limestone items). Each item is a small icon over its text.
private struct TermsColumn: View {
    let title: String
    let items: [String]
    let sees: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Text(title)
                .ptype(.columnHead)
                .textCase(.uppercase)
                .foregroundStyle(sees ? BedrockColor.emberGlow : BedrockColor.inkTertiary)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Space.s4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: Space.s2) {
                        icon(index)
                            .frame(width: 26, height: 18)
                            .accessibilityHidden(true)
                        Text(item)
                            .ptype(.listItem)
                            .foregroundStyle(sees ? BedrockColor.inkPrimary : BedrockColor.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, Space.s4)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
            .fill(sees ? BedrockColor.emberNight : BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
            .strokeBorder(sees ? BedrockColor.emberDeep : BedrockColor.lineStrong, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private func icon(_ index: Int) -> some View {
        if !sees {
            ProtoIcon.spEyeSlash
                .stroke(BedrockColor.inkTertiary, style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
        } else {
            switch index {
            case 0:
                ZStack {
                    ProtoIcon.spWallTop.fill(BedrockColor.ember)
                    ProtoIcon.spWallHalves.fill(BedrockColor.emberDeep)
                }
            case 1:
                ProtoIcon.spKey
                    .stroke(BedrockColor.emberGlow, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            default:
                ZStack {
                    ProtoIcon.spPulse
                        .stroke(BedrockColor.emberGlow, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    ProtoIcon.spPulseTail
                        .stroke(BedrockColor.emberDeep, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1.5, 3]))
                }
            }
        }
    }
}

// MARK: - SP3 · Alerts

struct SupporterAlertsScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @State private var asking = false

    var body: some View {
        let message = OnbCopy.string("onb.sp4.alert_later")
        OnboardingScaffold(.sp3, flow: flow, top: ProtoLayout.topWithBack) {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(headline: OnbCopy.string("onb.sp3.headline"),
                              text: OnbCopy.string("onb.sp3.body"))
                Spacer(minLength: Space.s4)
                NotificationPreview(date: Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                                    time: "9:41",
                                    appName: OnbCopy.parts("onb.s14.preview").first ?? "",
                                    now: OnbCopy.parts("onb.s14.preview").dropFirst().first ?? "",
                                    message: message,
                                    wallpaper: .warm,
                                    messageType: PType(face: .sans, size: 14.5, line: 19, relativeTo: .subheadline),
                                    accessibilityText: OnbCopy.string("onb.common.a11y_notification")
                                        .replacingOccurrences(of: "{message}", with: message))
                    .frame(maxWidth: .infinity)
                Spacer(minLength: Space.s4)
            }
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
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: OnbCopy.string("onb.sp1.eyebrow"), color: BedrockColor.emberGlow)
                    .padding(.bottom, Space.s3)
                Text(OnbCopy.string("onb.sp4.headline"))
                    .ptype(.titleL)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 22)
                SupporterStatusCard(person: services.accountability.supporting.first)
                    .bedrockAppear(.settle, delay: 0.2)
                SupporterNotes(notificationsOff: notificationsOff)
                    .padding(.top, 20)
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
        VStack(alignment: .leading, spacing: 14) {
            Text(OnbCopy.string("onb.sp4.body"))
                .ptype(.body)
                .foregroundStyle(BedrockColor.inkSecondary)
            Text(OnbCopy.string("onb.sp4.quiet_note"))
                .ptype(.note)
                .foregroundStyle(BedrockColor.inkTertiary)
            if notificationsOff {
                Text(OnbCopy.string("onb.sp4.notif_denied"))
                    .ptype(.note)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, Space.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.emberWash))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(BedrockColor.emberDeep, lineWidth: 1))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// “Wall up · Checked in 2 hours ago”, read as one element: Basalt, radius
/// 20, a Fault edge; the small wall with its glow, the two lines, a Glow dot.
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
            ZStack(alignment: .bottom) {
                MiniWall.status
                    .padding(.bottom, Space.s1)
                    .opacity(isUp ? 1 : 0.45)
                if isUp {
                    EmberGlow(width: 57, height: 10)
                        .offset(y: Space.s1)
                }
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(OnbCopy.string(isUp ? "onb.sp4.status_up" : "onb.sp4.status_down"))
                    .ptype(.rowTitle)
                    .foregroundStyle(BedrockColor.inkPrimary)
                Text(checked)
                    .ptype(.notePlain)
                    .foregroundStyle(BedrockColor.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Circle()
                .fill(isUp ? BedrockColor.emberGlow : BedrockColor.inkDisabled)
                .frame(width: 10, height: 10)
                .background(Circle().fill(BedrockColor.emberGlow.opacity(isUp ? 0.16 : 0)).padding(-4))
                .accessibilityHidden(true)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                .mask(alignment: .top) { Rectangle().frame(height: 1.5) }
        }
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
                        Eyebrow(text: OnbCopy.string("onb.sp_home.eyebrow"), color: BedrockColor.emberGlow)
                            .padding(.bottom, Space.s3)
                        Text(OnbCopy.string("onb.sp4.headline"))
                            .ptype(.titleL)
                            .foregroundStyle(BedrockColor.inkPrimary)
                            .fixedSize(horizontal: false, vertical: true)
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
                            .ptype(.note)
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
                .padding(.horizontal, ProtoLayout.side)
                .padding(.top, ProtoLayout.topWithChapter - BedrockSize.referenceTopInset)
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
                .ptype(.quote)
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(item(1))
                .ptype(.note)
                .foregroundStyle(BedrockColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Space.s3) {
                SheetButton(title: item(3)) { respond(false) }
                PrimaryButton(title: item(2), isLoading: isWorking) { respond(true) }
            }
        }
        .padding(Space.s4)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.emberWash))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.emberDeep))
    }
}
