import FamilyControls
import SafariServices
import SwiftUI

// Wall · Arrival, Screen Time, the wall goes up, the test (SPEC.md S1–S4, S2-D,
// B2, B9).

// MARK: - S1 · Arrival (and R1)

struct ArrivalScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services

    /// R1: a returning Pro user (an active entitlement found through StoreKit).
    private var returning: Bool { services.paywall.isPremium }
    private var key: (headline: String, body: String, primary: String) {
        returning
            ? ("onb.s1.r1_headline", "onb.s1.r1_body", "onb.s1.r1_primary")
            : ("onb.s1.headline", "onb.s1.body", "onb.s1.primary")
    }

    var body: some View {
        OnboardingScaffold(.s1, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: 0) {
                StoneMark()
                    .fill(LinearGradient(colors: [BedrockColor.emberGlow, BedrockColor.ember],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: BedrockSize.stoneMark.width, height: BedrockSize.stoneMark.height)
                    .padding(.top, BedrockSize.arrivalMarkTop)
                    .bedrockAppear(.settle, delay: 0.12)
                    .accessibilityHidden(true)

                Spacer(minLength: Space.s10)

                Text(OnbCopy.string("onb.s1.eyebrow"))
                    .bedrockEyebrow()
                    .padding(.bottom, Space.s3)
                    .bedrockAppear(.rise, delay: 0.2)
                CarveText(OnbCopy.string(key.headline), delay: 0.2, font: BedrockFont.displayXL)
                    .tracking(BedrockLine.displayXL.tracking)
                    .lineSpacing(BedrockLine.displayXL.lineSpacing)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(OnbCopy.string(key.body))
                    .font(BedrockFont.body)
                    .lineSpacing(BedrockLine.body.lineSpacing)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.s4)
                    .bedrockAppear(.rise, delay: 0.9)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string(key.primary)) { start() }
                .accessibilityHint(OnbCopy.string("onb.s1.a11y_primary"))
                .bedrockAppear(.settle, delay: 1.15)
        } footerAccessory: {
            if !returning {
                LinkButton(title: OnbCopy.string("onb.s1.link")) {
                    flow.track(.action(.support))
                    flow.go(.sp1)
                }
                .accessibilityHint(OnbCopy.string("onb.s1.a11y_link"))
                .bedrockAppear(.rise, delay: 1.35)
            }
        }
    }

    private func start() {
        BedrockHaptics.check()
        flow.track(.action(.buildWall))
        services.blocking.refreshAuthState()
        // Screen Time already authorised: straight to the wall.
        flow.go(services.blocking.authState == .approved ? .s3 : .s2)
    }
}

// MARK: - S2 · Before the Screen Time sheet

struct ScreenTimeScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @State private var asking = false
    @State private var approved = false

    var body: some View {
        OnboardingScaffold(.s2, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s8) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s2.eyebrow"),
                              headline: OnbCopy.string("onb.s2.headline"),
                              text: OnbCopy.string("onb.s2.body"))
                PermissionCard(look: approved ? .approved : .normal)
                    .frame(maxWidth: .infinity)
                    .bedrockAppear(.settle, delay: 0.15)
            }
        } footer: {
            VStack(spacing: Space.s3) {
                Text(OnbCopy.string("onb.s2.caption"))
                    .font(BedrockFont.footnote)
                    .foregroundStyle(BedrockColor.inkTertiary)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: OnbCopy.string("onb.s2.primary"), isLoading: asking) {
                    Task { await request() }
                }
                .accessibilityHint(OnbCopy.string("onb.s2.a11y_primary"))
            }
        }
        .task {
            // The card is the hero: a soft tap as it lands.
            try? await Task.sleep(for: .seconds(0.35))
            BedrockHaptics.stoneLands()
        }
    }

    private func request() async {
        flow.track(.stPermissionPrompted)
        asking = true
        let started = Date.now
        try? await services.blocking.requestAuthorization()
        asking = false
        let ms = Int(Date.now.timeIntervalSince(started) * 1000)
        await ScreenTimeAnswer.handle(services.blocking.authState, ms: ms, flow: flow) {
            withAnimation(BedrockMotion.ember) { approved = true }
        }
    }
}

/// What S2 and S2-D do with iOS's answer.
@MainActor
enum ScreenTimeAnswer {
    static func handle(_ state: BlockingAuthState, ms: Int, flow: FirstLightFlow,
                       approvedBeat: () -> Void) async {
        switch state {
        case .approved:
            flow.track(.stPermissionResult(.approved, msToDecide: ms))
            approvedBeat()
            BedrockHaptics.check()
            try? await Task.sleep(for: .seconds(BedrockTiming.approvedAdvance))
            flow.go(.s3)
        case .denied:
            flow.track(.stPermissionResult(.denied, msToDecide: ms))
            if flow.current != .s2_d { flow.go(.s2_d) }
        case .restricted:
            flow.track(.stPermissionResult(.restricted, msToDecide: ms))
            flow.update { $0.restricted = true }
            flow.go(.b2)
        case .unavailable:
            flow.track(.stPermissionResult(.unavailable, msToDecide: ms))
            flow.go(.b9)
        case .notDetermined:
            break // the sheet was interrupted: wait with the button ready
        }
    }
}

/// S2's illustration: a solid stone card with a shield glyph and “Screen Time”.
/// Dimmed on S2-D and B2; its border warms to ember on approval.
struct PermissionCard: View {
    enum Look { case normal, approved, dimmed }
    let look: Look

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Space.s3) {
            Image(systemName: "shield.lefthalf.filled")
                .font(BedrockFont.title)
                .foregroundStyle(look == .dimmed ? BedrockColor.inkTertiary : BedrockColor.emberGlow)
            Text(OnbCopy.string("onb.s2.card"))
                .font(BedrockFont.headline)
                .foregroundStyle(BedrockColor.inkPrimary)
        }
        .frame(width: BedrockSize.permissionCard.width, height: BedrockSize.permissionCard.height)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            .fill(LinearGradient(colors: [BedrockColor.stoneLight, BedrockColor.stoneMid, BedrockColor.stoneDark],
                                 startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            .strokeBorder(look == .approved ? BedrockColor.ember : BedrockColor.lineStrong,
                          lineWidth: look == .approved ? 1.5 : 1))
        .shadow(color: look == .approved && !reduceMotion ? BedrockColor.emberGlow.opacity(0.5) : .clear, radius: 10)
        .opacity(look == .dimmed ? 0.5 : 1)
        .accessibilityHidden(true)
    }
}

// MARK: - S2-D · Screen Time declined

struct ScreenTimeDeclinedScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    /// iOS won't show its sheet again: send them to Settings.
    @State private var settingsState = false
    @State private var asking = false
    @State private var approved = false

    var body: some View {
        OnboardingScaffold(.s2_d, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s8) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s2_d.eyebrow"),
                              headline: OnbCopy.string(settingsState ? "onb.s2_d.settings_headline" : "onb.s2_d.headline"),
                              text: OnbCopy.string(settingsState ? "onb.s2_d.settings_body" : "onb.s2_d.body"))
                    .id(settingsState)
                    .transition(.opacity)
                PermissionCard(look: approved ? .approved : .dimmed)
                    .frame(maxWidth: .infinity)
            }
            .animation(BedrockMotion.stateCrossfade, value: settingsState)
        } footer: {
            VStack(spacing: Space.s2) {
                PrimaryButton(title: OnbCopy.string(settingsState ? "onb.s2_d.settings_primary" : "onb.s2_d.primary"),
                              isLoading: asking) {
                    if settingsState { openSettings() } else { Task { await retry() } }
                }
                TextButton(title: OnbCopy.string("onb.s2_d.secondary"), fullWidth: true) {
                    flow.track(.action(.continueWithoutWall))
                    flow.update { $0.continuedWithoutWall = true }
                    flow.withoutWall()
                }
                .accessibilityHint(OnbCopy.string("onb.s2_d.a11y_secondary"))
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, settingsState else { return }
            services.blocking.refreshAuthState()
            if services.blocking.authState == .approved {
                Task { await answered(ms: 0) }
            }
        }
    }

    private func retry() async {
        flow.track(.action(.tryAgain))
        asking = true
        let started = Date.now
        try? await services.blocking.requestAuthorization()
        asking = false
        let ms = Int(Date.now.timeIntervalSince(started) * 1000)
        if services.blocking.authState == .denied {
            // Answered with no sheet, or declined again: iOS won't ask from here.
            settingsState = true
            return
        }
        await answered(ms: ms)
    }

    private func answered(ms: Int) async {
        await ScreenTimeAnswer.handle(services.blocking.authState, ms: ms, flow: flow) {
            withAnimation(BedrockMotion.ember) { approved = true }
        }
    }

    private func openSettings() {
        flow.track(.action(.openSettings))
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}

// MARK: - B2 · Screen Time is managed

struct ManagedScreen: View {
    @Environment(FirstLightFlow.self) private var flow

    var body: some View {
        OnboardingScaffold(.b2, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s8) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.b2.eyebrow"),
                              headline: OnbCopy.string("onb.b2.headline"),
                              text: OnbCopy.string("onb.b2.body"))
                PermissionCard(look: .dimmed)
                    .frame(maxWidth: .infinity)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.b2.primary")) {
                flow.update { $0.restricted = true }
                flow.withoutWall()
            }
        }
    }
}

// MARK: - B9 · Screen Time isn't available here

struct PreviewModeScreen: View {
    @Environment(FirstLightFlow.self) private var flow

    var body: some View {
        OnboardingScaffold(.b9, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s8) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.b9.eyebrow"),
                              headline: OnbCopy.string("onb.b9.headline"),
                              text: OnbCopy.string("onb.b9.body"))
                PermissionCard(look: .dimmed)
                    .frame(maxWidth: .infinity)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.b9.primary")) {
                flow.update { $0.previewMode = true }
                flow.go(.s3)
            }
        }
    }
}

// MARK: - S3 · The wall goes up

struct WallUpScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.openURL) private var openURL

    enum Phase { case choosing, building, up, failed }

    @State private var phase: Phase = .choosing
    @State private var web: WallView.Course = .empty
    @State private var apps: WallView.Course = .empty
    @State private var schedule: WallView.Course = .empty
    @State private var pickerShown = false
    @State private var warm = false
    @State private var primaryShown = false

    private var hasApps: Bool {
        !services.blocking.selection.applicationTokens.isEmpty || !services.blocking.selection.categoryTokens.isEmpty
    }

    private var stages: [WallStage] { hasApps ? [.web, .apps, .schedule] : [.web, .schedule] }

    var body: some View {
        OnboardingScaffold(.s3, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s7) {
                heading
                WallView(web: web, apps: hasApps ? apps : nil, schedule: schedule)
                    .frame(maxWidth: .infinity)
                    .accessibilityElement()
                    .accessibilityLabel(OnbCopy.format("onb.s3.a11y_wall", landedCount, stages.count))
                rows
            }
        } footer: {
            footer
        }
        .familyActivityPicker(isPresented: $pickerShown, selection: selection)
        .onChange(of: pickerShown) { _, shown in
            guard !shown else { return }
            let picked = services.blocking.selection
            flow.track(.pickerResult(apps: CountBucket(picked.applicationTokens.count),
                                     categories: CountBucket(picked.categoryTokens.count)))
        }
        .onAppear(perform: restore)
    }

    // MARK: Pieces

    @ViewBuilder private var heading: some View {
        switch phase {
        case .choosing:
            ScreenHeading(eyebrow: OnbCopy.string("onb.s3.eyebrow"), headline: OnbCopy.string("onb.s3.headline"))
        case .building:
            ScreenHeading(eyebrow: OnbCopy.string("onb.s3.eyebrow"), headline: OnbCopy.string("onb.s3.building"))
                .transition(.opacity)
        case .up:
            VStack(alignment: .leading, spacing: 0) {
                Text(OnbCopy.string("onb.s3.eyebrow"))
                    .bedrockEyebrow()
                    .padding(.bottom, Space.s3)
                WarmLastWord(text: OnbCopy.string("onb.s3.up"), warm: warm, font: BedrockFont.title)
                    .accessibilityAddTraits(.isHeader)
            }
            .transition(.opacity)
        case .failed:
            ScreenHeading(eyebrow: OnbCopy.string("onb.s3.eyebrow"),
                          headline: OnbCopy.string("onb.s3.error_headline"),
                          text: OnbCopy.string("onb.s3.error_body"))
                .transition(.opacity)
        }
    }

    private var rows: some View {
        let row1 = OnbCopy.parts("onb.s3.row_1")
        let row2 = row2Parts
        let row3 = OnbCopy.parts("onb.s3.row_3")
        return VStack(spacing: 0) {
            WallRow(title: part(row1, 0), detail: part(row1, 1), accessory: .label(part(row1, 2)), course: web)
            Rectangle().fill(BedrockColor.lineSubtle).frame(height: 1).padding(.leading, Space.s4)
            WallRow(title: part(row2, 0), detail: part(row2, 1),
                    accessory: phase == .choosing ? .button(part(row2, 2)) { openPicker() } : .label(""),
                    course: hasApps ? apps : .empty)
            Rectangle().fill(BedrockColor.lineSubtle).frame(height: 1).padding(.leading, Space.s4)
            WallRow(title: part(row3, 0), detail: part(row3, 1), accessory: .label(part(row3, 2)), course: schedule)
        }
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineSubtle))
    }

    /// Row 2 before and after the picker: “Apps that pull you in · Optional · Add”,
    /// then “3 apps · Their names never leave this iPhone · Edit”.
    private var row2Parts: [String] {
        let selection = services.blocking.selection
        let apps = selection.applicationTokens.count
        let categories = selection.categoryTokens.count
        guard apps + categories > 0 else { return OnbCopy.parts("onb.s3.row_2") }
        if categories > 0 {
            return OnbCopy.string("onb.s3.row_2_mixed")
                .replacingOccurrences(of: "{n}", with: "\(apps + categories)").components(separatedBy: " · ")
        }
        if apps == 1 { return OnbCopy.parts("onb.s3.row_2_one") }
        return OnbCopy.string("onb.s3.row_2_count")
            .replacingOccurrences(of: "{n}", with: "\(apps)").components(separatedBy: " · ")
    }

    @ViewBuilder private var footer: some View {
        switch phase {
        case .choosing:
            PrimaryButton(title: OnbCopy.string("onb.s3.primary")) { build() }
        case .building:
            PrimaryButton(title: OnbCopy.string("onb.s3.primary")) {}
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        case .up:
            PrimaryButton(title: OnbCopy.string("onb.s3.up_primary")) { flow.go(.s4) }
                .opacity(primaryShown ? 1 : 0)
                .bedrockAppear(.settle, delay: BedrockTiming.wallUpPrimary)
        case .failed:
            VStack(spacing: Space.s2) {
                PrimaryButton(title: OnbCopy.string("onb.s3.error_primary")) { build() }
                TextButton(title: OnbCopy.string("onb.s3.error_secondary"), fullWidth: true) {
                    if let url = Support.mailURL(subject: OnbCopy.string("onb.s3.error_headline")) { openURL(url) }
                }
            }
        }
    }

    private var selection: Binding<FamilyActivitySelection> {
        Binding(get: { services.blocking.selection }, set: { services.blocking.selection = $0 })
    }

    private var landedCount: Int {
        [web, hasApps ? apps : nil, schedule].compactMap { $0 }.filter { $0 == .landed }.count
    }

    private func part(_ parts: [String], _ index: Int) -> String {
        parts.indices.contains(index) ? parts[index] : ""
    }

    // MARK: Actions

    private func openPicker() {
        flow.track(.pickerOpened)
        pickerShown = true
    }

    /// Already up (back from S4, or resumed): show the finished wall.
    private func restore() {
        guard flow.state.wallUp else { return }
        web = .landed
        apps = .landed
        schedule = .landed
        phase = .up
        warm = true
        primaryShown = true
        flow.dawnOverride = Dawn.level(for: .s4)
    }

    private func build() {
        BedrockHaptics.check()
        let started = Date.now
        withAnimation(BedrockMotion.stateCrossfade) { phase = .building }
        for stage in stages where course(stage) == .failed { setCourse(stage, .empty) }
        Task {
            for stage in stages where course(stage) != .landed {
                // Each course lands as its write returns; a short beat between
                // writes lets each one read.
                try? await Task.sleep(for: .seconds(BedrockTiming.wallStageGap))
                do {
                    if !flow.state.previewMode { try services.blocking.applyStage(stage) }
                    setCourse(stage, .landed)
                    BedrockHaptics.check()
                } catch {
                    setCourse(stage, .failed)
                    flow.track(.wallApplyFailed(stage))
                    BedrockHaptics.needsAction()
                    withAnimation(BedrockMotion.stateCrossfade) { phase = .failed }
                    return
                }
            }
            // WallView Locks itself (dip, heavy + success, ember bloom) once every course is in.
            flow.update { $0.wallUp = true }
            flow.track(.wallApplied(webFilter: true, schedule: true,
                                    apps: CountBucket(services.blocking.selection.applicationTokens.count),
                                    applyMs: Int(Date.now.timeIntervalSince(started) * 1000)))
            withAnimation(BedrockMotion.stateCrossfade) { phase = .up }
            withAnimation(BedrockMotion.ember) { warm = true }
            flow.dawnOverride = Dawn.level(for: .s4)
            AccessibilityNotification.Announcement(OnbCopy.string("onb.s3.up")).post()
            primaryShown = true
        }
    }

    private func course(_ stage: WallStage) -> WallView.Course {
        switch stage {
        case .web: web
        case .apps: apps
        case .schedule: schedule
        }
    }

    private func setCourse(_ stage: WallStage, _ value: WallView.Course) {
        switch stage {
        case .web: web = value
        case .apps: apps = value
        case .schedule: schedule = value
        }
    }
}

/// One S3 list row: title, detail, and a trailing accessory that becomes a check
/// (Pop) when its course lands, or “Didn't apply” when it fails.
private struct WallRow: View {
    enum Accessory {
        case label(String)
        case button(String, () -> Void)
    }

    let title: String
    let detail: String
    let accessory: Accessory
    let course: WallView.Course

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var checkScale: CGFloat = 1

    var body: some View {
        HStack(alignment: .center, spacing: Space.s3) {
            VStack(alignment: .leading, spacing: Space.s1) {
                Text(title)
                    .font(BedrockFont.headline)
                    .foregroundStyle(BedrockColor.inkPrimary)
                Text(detail)
                    .font(BedrockFont.footnote)
                    .foregroundStyle(BedrockColor.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            trailing
        }
        .padding(.horizontal, Space.s4)
        .padding(.vertical, Space.s3)
        .frame(minHeight: BedrockSize.chipMinHeight)
        .onChange(of: course) { _, new in
            guard new == .landed, !reduceMotion else { return }
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { checkScale = 1.15 }
            withAnimation(BedrockMotion.pop) { checkScale = 1 }
        }
    }

    @ViewBuilder private var trailing: some View {
        switch course {
        case .landed:
            Image(systemName: "checkmark.circle.fill")
                .font(BedrockFont.headline)
                .foregroundStyle(BedrockColor.emberGlow)
                .scaleEffect(checkScale)
                .transition(.opacity)
                .accessibilityHidden(true)
        case .failed:
            Text(OnbCopy.string("onb.s3.row_error"))
                .font(BedrockFont.subhead)
                .foregroundStyle(BedrockColor.emberGlow)
        case .empty:
            switch accessory {
            case .label(let text):
                Text(text)
                    .font(BedrockFont.subhead)
                    .foregroundStyle(BedrockColor.inkSecondary)
            case .button(let text, let action):
                Button(action: action) {
                    Text(text)
                        .font(BedrockFont.subhead.weight(.semibold))
                        .foregroundStyle(BedrockColor.emberGlow)
                        .frame(minWidth: BedrockSize.circleButton, minHeight: BedrockSize.circleButton)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressOpacityStyle())
            }
        }
    }
}

/// A line whose last word warms from Chalk to Glow (S3's “up.”, S13.6's “Sealed.”).
struct WarmLastWord: View {
    let text: String
    let warm: Bool
    var font: Font = BedrockFont.title

    var body: some View {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        let head = words.dropLast().joined(separator: " ")
        let last = String(words.last ?? "")
        let lead = Text(verbatim: head.isEmpty ? "" : head + " ").foregroundStyle(BedrockColor.inkPrimary)
        let end = Text(verbatim: last).foregroundStyle(warm ? BedrockColor.emberGlow : BedrockColor.inkPrimary)
        Text("\(lead)\(end)")
            .font(font)
            .tracking(BedrockLine.title.tracking)
            .lineSpacing(BedrockLine.title.lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .animation(BedrockMotion.ember, value: warm)
    }
}

// MARK: - S4 · Try it

struct WallTestScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Result: Equatable { case ready, checking, held, opened, unverified, rebuilding }

    @State private var result: Result = .ready
    @State private var safariShown = false
    @State private var heldScale: CGFloat = 1
    @State private var flash = false

    var body: some View {
        OnboardingScaffold(.s4, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: 0) {
                heading
                    .id(result == .checking || result == .rebuilding ? Result.ready : result)
                    .transition(.opacity)
            }
            .animation(BedrockMotion.stateCrossfade, value: result)
        } footer: {
            VStack(spacing: Space.s5) {
                WallView(web: .landed, apps: nil, schedule: .landed, scale: BedrockSize.wallGlyphScale)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(BedrockColor.emberGlow)
                            .blendMode(.plusLighter)
                            .opacity(flash ? 0.55 : 0)
                    }
                    .colorMultiply(result == .held && reduceMotion ? BedrockColor.emberGlow : .white)
                primary
            }
        } footerAccessory: {
            if result == .ready {
                TextButton(title: OnbCopy.string("onb.s4.secondary")) {
                    flow.track(.wallTestSkipped)
                    flow.update { $0.wallTest = .skipped }
                    flow.afterWallTest()
                }
            }
        }
        .fullScreenCover(isPresented: $safariShown, onDismiss: check) {
            SafariView(url: WallTestPage.url) { safariShown = false }
                .ignoresSafeArea()
        }
        .onAppear {
            switch flow.state.wallTest {
            case .held: result = .held
            case .unverified: result = .unverified
            default: break
            }
        }
    }

    @ViewBuilder private var heading: some View {
        switch result {
        case .ready, .checking, .rebuilding:
            ScreenHeading(eyebrow: OnbCopy.string("onb.s4.eyebrow"),
                          headline: OnbCopy.string("onb.s4.headline"),
                          text: OnbCopy.string("onb.s4.body"))
        case .held:
            ScreenHeading(eyebrow: OnbCopy.string("onb.s4.eyebrow"),
                          headline: OnbCopy.string("onb.s4.held_headline"),
                          headlineType: .held,
                          text: OnbCopy.string("onb.s4.held_body"))
                .scaleEffect(heldScale, anchor: .leading)
        case .opened:
            ScreenHeading(eyebrow: OnbCopy.string("onb.s4.eyebrow"),
                          headline: OnbCopy.string("onb.s4.opened_headline"),
                          text: OnbCopy.string("onb.s4.opened_body"))
        case .unverified:
            ScreenHeading(eyebrow: OnbCopy.string("onb.s4.eyebrow"),
                          headline: OnbCopy.string("onb.s4.unverified_headline"),
                          text: OnbCopy.string("onb.s4.unverified_body"))
        }
    }

    @ViewBuilder private var primary: some View {
        switch result {
        case .ready:
            PrimaryButton(title: OnbCopy.string("onb.s4.primary")) {
                flow.track(.wallTestStarted)
                safariShown = true
            }
        case .checking:
            PrimaryButton(title: OnbCopy.string("onb.s4.checking"), isLoading: true) {}
        case .rebuilding:
            PrimaryButton(title: OnbCopy.string("onb.s4.opened_primary"), isLoading: true) {}
        case .held, .unverified:
            PrimaryButton(title: OnbCopy.string("onb.s4.held_primary")) { flow.afterWallTest() }
        case .opened:
            PrimaryButton(title: OnbCopy.string("onb.s4.opened_primary")) { rebuild() }
        }
    }

    /// After Safari's Done: the silent background check.
    private func check() {
        result = .checking
        Task {
            let outcome: WallTestOutcome
            if flow.state.previewMode {
                try? await Task.sleep(for: .seconds(1))
                outcome = .held
            } else {
                let tester = WallTester()
                outcome = await tester.run()
            }
            finish(outcome)
        }
    }

    private func finish(_ outcome: WallTestOutcome) {
        flow.update { $0.wallTest = outcome }
        switch outcome {
        case .held:
            flow.track(.wallTestResult(.held))
            result = .held
            BedrockHaptics.lock()
            AccessibilityNotification.Announcement(OnbCopy.string("onb.s4.a11y_held")).post()
            guard !reduceMotion else { return }
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { heldScale = 1.06 }
            withAnimation(BedrockMotion.lock) { heldScale = 1 }
            withAnimation(BedrockMotion.ember) { flash = true }
            withAnimation(BedrockMotion.ember.delay(0.6)) { flash = false }
        case .opened:
            flow.track(.wallTestResult(.opened))
            result = .opened
        case .unverified, .skipped:
            flow.track(.wallTestResult(.unverified))
            result = .unverified
        }
    }

    /// “Put it back up”: re-run S3's writes, then test again.
    private func rebuild() {
        result = .rebuilding
        Task {
            try? await Task.sleep(for: .seconds(BedrockTiming.wallStageGap))
            if !flow.state.previewMode {
                for stage in [WallStage.web, .apps, .schedule] { try? services.blocking.applyStage(stage) }
            }
            BedrockHaptics.lock()
            result = .ready
        }
    }
}

/// SFSafariViewController for the S4 test page: “You won't leave Bedrock.”
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onDone: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onDone: onDone) }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .done
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onDone: () -> Void
        init(onDone: @escaping () -> Void) { self.onDone = onDone }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onDone()
        }
    }
}

/// help@thebedrock.app, with a subject.
enum Support {
    static let email = "help@thebedrock.app"

    static func mailURL(subject: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [URLQueryItem(name: "subject", value: subject)]
        return components.url
    }
}
