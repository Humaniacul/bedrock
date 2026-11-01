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

    /// “Build it now,” / “while you mean it.”: one line each, carved 180ms apart.
    private var headlineLines: [String] {
        let headline = OnbCopy.string(key.headline)
        guard let comma = headline.range(of: ", ") else { return [headline] }
        return [String(headline[..<comma.lowerBound]) + ",", String(headline[comma.upperBound...])]
    }

    var body: some View {
        OnboardingScaffold(.s1, flow: flow, back: false, top: 0) {
            VStack(alignment: .leading, spacing: 0) {
                StoneMarkView()
                    .frame(width: 30, height: 36)
                    .padding(.top, ProtoLayout.controlTop)
                    .bedrockAppear(.settle, delay: 0.12)
                    .accessibilityHidden(true)

                Spacer(minLength: Space.s6)

                VStack(alignment: .leading, spacing: 14) {
                    Eyebrow(text: OnbCopy.string("onb.s1.eyebrow"))
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(headlineLines.enumerated()), id: \.offset) { index, line in
                            CarveText(line, delay: 0.2 + Double(index) * 0.18)
                                .ptype(.display)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(OnbCopy.string(key.headline))
                    .accessibilityAddTraits(.isHeader)
                    Text(OnbCopy.string(key.body))
                        .ptype(.body)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .bedrockAppear(.rise, delay: 0.9)
                }
                .padding(.bottom, 40 - Space.s2)
            }
        } footer: {
            VStack(spacing: ProtoLayout.buttonGap) {
                PrimaryButton(title: OnbCopy.string(key.primary)) { start() }
                    .accessibilityHint(OnbCopy.string("onb.s1.a11y_primary"))
                if !returning {
                    QuietLink(title: OnbCopy.string("onb.s1.link")) {
                        flow.track(.action(.support))
                        flow.go(.sp1)
                    }
                    .accessibilityHint(OnbCopy.string("onb.s1.a11y_link"))
                }
            }
            .bedrockAppear(.settle, delay: 1.15)
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
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s2.eyebrow"),
                              headline: OnbCopy.string("onb.s2.headline"),
                              text: OnbCopy.string("onb.s2.body"))
                Spacer(minLength: Space.s6)
                PermissionCard(look: approved ? .approved : .normal)
                    .frame(maxWidth: .infinity)
                    .bedrockAppear(.settle, delay: 0.15)
                Spacer(minLength: Space.s6)
            }
        } footer: {
            Text(OnbCopy.string("onb.s2.caption"))
                .ptype(.subheadPlain)
                .foregroundStyle(BedrockColor.inkTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, Space.s3)
            PrimaryButton(title: OnbCopy.string("onb.s2.primary"), isLoading: asking) {
                Task { await request() }
            }
            .accessibilityHint(OnbCopy.string("onb.s2.a11y_primary"))
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
            withAnimation(.easeInOut(duration: 0.6)) { approved = true }
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

/// S2's card: 220 × 150, Basalt, radius 20, a 1.5pt Seam edge that warms to
/// Ember on approval; a 44 × 52 shield (Glow, with a Chalk check) over
/// “Screen Time” (15 semibold). S2-D dims it to 45% with a 1pt edge, an Ash
/// shield and no check.
struct PermissionCard: View {
    enum Look { case normal, approved, dimmed }
    let look: Look

    var body: some View {
        let dimmed = look == .dimmed
        VStack(spacing: Space.s3) {
            ZStack {
                ProtoIcon.shield
                    .stroke(dimmed ? BedrockColor.inkTertiary : BedrockColor.emberGlow,
                            style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
                if !dimmed {
                    ProtoIcon.shieldCheck
                        .stroke(BedrockColor.inkPrimary, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(width: 44, height: 52)
            Text(OnbCopy.string("onb.s2.card"))
                .ptype(.subheadSemibold)
                .foregroundStyle(dimmed ? BedrockColor.inkSecondary : BedrockColor.inkPrimary)
        }
        .frame(width: BedrockSize.permissionCard.width, height: BedrockSize.permissionCard.height)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
            .strokeBorder(look == .approved ? BedrockColor.ember : BedrockColor.lineSubtle, lineWidth: dimmed ? 1 : 1.5))
        .opacity(dimmed ? 0.45 : 1)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s2_d.eyebrow"),
                              headline: OnbCopy.string(settingsState ? "onb.s2_d.settings_headline" : "onb.s2_d.headline"),
                              text: OnbCopy.string(settingsState ? "onb.s2_d.settings_body" : "onb.s2_d.body"))
                    .id(settingsState)
                    .transition(.opacity)
                Spacer(minLength: Space.s6)
                PermissionCard(look: approved ? .approved : .dimmed)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: Space.s6)
            }
            .animation(BedrockMotion.stateCrossfade, value: settingsState)
        } footer: {
            VStack(spacing: ProtoLayout.buttonGap) {
                PrimaryButton(title: OnbCopy.string(settingsState ? "onb.s2_d.settings_primary" : "onb.s2_d.primary"),
                              isLoading: asking) {
                    if settingsState { openSettings() } else { Task { await retry() } }
                }
                TextButton(title: OnbCopy.string("onb.s2_d.secondary")) {
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
            withAnimation(.easeInOut(duration: 0.6)) { approved = true }
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
            ScreenHeading(eyebrow: OnbCopy.string("onb.b2.eyebrow"),
                          headline: OnbCopy.string("onb.b2.headline"),
                          text: OnbCopy.string("onb.b2.body"))
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
            ScreenHeading(eyebrow: OnbCopy.string("onb.b9.eyebrow"),
                          headline: OnbCopy.string("onb.b9.headline"),
                          text: OnbCopy.string("onb.b9.body"))
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

    private var hasApps: Bool {
        !services.blocking.selection.applicationTokens.isEmpty || !services.blocking.selection.categoryTokens.isEmpty
    }

    private var stages: [WallStage] { hasApps ? [.web, .apps, .schedule] : [.web, .schedule] }

    var body: some View {
        OnboardingScaffold(.s3, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: OnbCopy.string("onb.s3.eyebrow"))
                    .padding(.bottom, Space.s3)
                heading
                    .frame(minHeight: 84, alignment: .topLeading)
                    .animation(BedrockMotion.stateCrossfade, value: phase)
                WallView(web: web, apps: hasApps ? apps : nil, schedule: schedule, choosing: phase == .choosing)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Space.s2)
                    .padding(.bottom, 14)
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
            headline(OnbCopy.string("onb.s3.headline"))
        case .building:
            headline(OnbCopy.string("onb.s3.building"))
        case .up:
            WarmLastWord(text: OnbCopy.string("onb.s3.up"), warm: warm)
                .accessibilityAddTraits(.isHeader)
                .transition(.opacity)
        case .failed:
            ScreenHeading(headline: OnbCopy.string("onb.s3.error_headline"),
                          text: OnbCopy.string("onb.s3.error_body"))
                .transition(.opacity)
        }
    }

    private func headline(_ text: String) -> some View {
        Text(text)
            .ptype(.title)
            .foregroundStyle(BedrockColor.inkPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .id(text)
            .transition(.opacity)
    }

    private var rows: some View {
        let row1 = OnbCopy.parts("onb.s3.row_1")
        let row2 = row2Parts
        let row3 = OnbCopy.parts("onb.s3.row_3")
        let choosing = phase == .choosing
        return VStack(spacing: 0) {
            Rectangle().fill(BedrockColor.lineSubtle).frame(height: 1)
            WallRow(icon: .lock, title: part(row1, 0), detail: part(row1, 1),
                    trailing: .label(part(row1, 2), BedrockColor.emberGlow), course: web, choosing: choosing)
            WallRow(icon: .grid, title: part(row2, 0), detail: part(row2, 1),
                    trailing: choosing ? .button(part(row2, 2)) { openPicker() } : .none,
                    course: hasApps ? apps : nil, choosing: choosing)
            WallRow(icon: .clock, title: part(row3, 0), detail: part(row3, 1), detailType: .rowDetail,
                    trailing: .label(part(row3, 2), BedrockColor.inkTertiary), course: schedule, choosing: choosing)
        }
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
            Color.clear.frame(height: BedrockSize.primaryHeight)
        case .up:
            PrimaryButton(title: OnbCopy.string("onb.s3.up_primary")) { flow.go(.s4) }
                .bedrockAppear(.settle, delay: BedrockTiming.wallUpPrimary)
        case .failed:
            VStack(spacing: ProtoLayout.buttonGap) {
                PrimaryButton(title: OnbCopy.string("onb.s3.error_primary")) { build() }
                TextButton(title: OnbCopy.string("onb.s3.error_secondary")) {
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
                } catch {
                    setCourse(stage, .failed)
                    flow.track(.wallApplyFailed(stage))
                    BedrockHaptics.needsAction()
                    withAnimation(BedrockMotion.stateCrossfade) { phase = .failed }
                    return
                }
            }
            // WallView Locks itself (dip, heavy + success, ember bloom) once every course is in.
            try? await Task.sleep(for: .seconds(0.4))
            flow.update { $0.wallUp = true }
            flow.track(.wallApplied(webFilter: true, schedule: true,
                                    apps: CountBucket(services.blocking.selection.applicationTokens.count),
                                    applyMs: Int(Date.now.timeIntervalSince(started) * 1000)))
            withAnimation(BedrockMotion.stateCrossfade) { phase = .up }
            withAnimation(BedrockMotion.ember.delay(0.15)) { warm = true }
            flow.dawnOverride = Dawn.level(for: .s4)
            AccessibilityNotification.Announcement(OnbCopy.string("onb.s3.up")).post()
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

/// One S3 row, as the prototype lays it out: a 30pt icon column, the title
/// (17 semibold) over its detail (14pt Ash), a trailing label or pill; 12pt
/// gaps and padding, a Seam line under it. Once building, the icon becomes an
/// ember check that pops 0.5s after its course lands (an empty ring for apps
/// when none were picked).
private struct WallRow: View {
    enum Icon { case lock, grid, clock }
    enum Trailing {
        case none
        case label(String, Color)
        case button(String, () -> Void)
    }

    let icon: Icon
    let title: String
    let detail: String
    var detailType: PType = .notePlain
    let trailing: Trailing
    /// nil: apps, with none picked.
    let course: WallView.Course?
    let choosing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var checked = false

    var body: some View {
        // At accessibility sizes the trailing label or pill moves under the text.
        let stacked = dynamicTypeSize.isAccessibilitySize
        HStack(alignment: stacked ? .top : .center, spacing: Space.s3) {
            leading
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .ptype(.rowTitle)
                        .foregroundStyle(BedrockColor.inkPrimary)
                    Text(detail)
                        .ptype(detailType)
                        .foregroundStyle(BedrockColor.inkTertiary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                if stacked { trailingView.padding(.top, Space.s1) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !stacked { trailingView }
        }
        .padding(.vertical, Space.s3)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BedrockColor.lineSubtle).frame(height: 1)
        }
        .onAppear { checked = course == .landed && !choosing }
        .onChange(of: course) { _, new in
            guard new == .landed else { checked = false; return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(reduceMotion ? 0 : 0.5))
                withAnimation(reduceMotion ? BedrockMotion.reducedFade : BedrockMotion.pop) { checked = true }
                BedrockHaptics.check()
            }
        }
    }

    @ViewBuilder private var leading: some View {
        if choosing {
            switch icon {
            case .lock:
                ZStack {
                    ProtoIcon.lockBody.fill(BedrockColor.emberGlow)
                    ProtoIcon.lockShackle.stroke(BedrockColor.emberGlow, lineWidth: 1.8)
                }
                .frame(width: 14, height: 18)
            case .grid:
                ProtoIcon.grid.stroke(BedrockColor.inkSecondary, lineWidth: 1.5).frame(width: 18, height: 18)
            case .clock:
                ProtoIcon.clock
                    .stroke(BedrockColor.inkSecondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 18, height: 18)
            }
        } else if course == nil {
            Circle().strokeBorder(BedrockColor.lineStrong, lineWidth: 1).frame(width: 24, height: 24)
        } else {
            CheckDot()
                .scaleEffect(checked ? 1 : 0.4)
                .opacity(checked ? 1 : 0)
        }
    }

    @ViewBuilder private var trailingView: some View {
        if course == .failed {
            Text(OnbCopy.string("onb.s3.row_error"))
                .ptype(.footnotePlain)
                .foregroundStyle(BedrockColor.emberGlow)
        } else {
            switch trailing {
            case .none:
                EmptyView()
            case .label(let text, let color):
                Text(text)
                    .ptype(.footnotePlain)
                    .foregroundStyle(color)
            case .button(let text, let action):
                PillButton(title: text, action: action)
            }
        }
    }
}

/// A headline whose last word warms from Chalk to Glow (S3's “up.”).
struct WarmLastWord: View {
    let text: String
    let warm: Bool
    var type: PType = .title

    var body: some View {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        let head = words.dropLast().joined(separator: " ")
        let last = String(words.last ?? "")
        let lead = Text(verbatim: head.isEmpty ? "" : head + " ").foregroundStyle(BedrockColor.inkPrimary)
        let end = Text(verbatim: last).foregroundStyle(warm ? BedrockColor.emberGlow : BedrockColor.inkPrimary)
        Text("\(lead)\(end)")
            .ptype(type)
            .fixedSize(horizontal: false, vertical: true)
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

    var body: some View {
        OnboardingScaffold(.s4, flow: flow, back: false, top: ProtoLayout.topWithBack) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: OnbCopy.string("onb.s4.eyebrow"))
                    .padding(.bottom, Space.s3)
                heading
                    .id(headingID)
                    .transition(.opacity)
                Spacer(minLength: Space.s6)
                illustration
                    .frame(maxWidth: .infinity)
                Spacer(minLength: Space.s6)
            }
            .animation(BedrockMotion.stateCrossfade, value: headingID)
        } footer: {
            footer
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

    private var headingID: Result {
        result == .checking || result == .rebuilding ? .ready : result
    }

    @ViewBuilder private var heading: some View {
        switch result {
        case .ready, .checking, .rebuilding:
            plain("onb.s4.headline", "onb.s4.body")
        case .held:
            VStack(alignment: .leading, spacing: 0) {
                Text(OnbCopy.string("onb.s4.held_headline"))
                    .ptype(.held)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .scaleEffect(heldScale, anchor: .leading)
                    .accessibilityAddTraits(.isHeader)
                Text(OnbCopy.string("onb.s4.held_body"))
                    .ptype(.body)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.s4)
                    .bedrockAppear(.rise, delay: 0.25)
            }
        case .opened:
            plain("onb.s4.opened_headline", "onb.s4.opened_body")
        case .unverified:
            plain("onb.s4.unverified_headline", "onb.s4.unverified_body")
        }
    }

    private func plain(_ headline: String, _ body: String) -> some View {
        ScreenHeading(headline: OnbCopy.string(headline), text: OnbCopy.string(body))
    }

    /// The small wall; a glow under it once held, “One moment” while checking.
    private var illustration: some View {
        VStack(spacing: 5) {
            MiniWall.test
            if result == .held {
                EmberGlow(width: 200, height: 26)
                    .padding(.top, -6)
                    .transition(.opacity)
            }
            if result == .checking || result == .rebuilding {
                Text(OnbCopy.string("onb.s4.checking"))
                    .ptype(.footnotePlain)
                    .foregroundStyle(BedrockColor.inkTertiary)
                    .padding(.top, 14 - 5)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.6), value: result)
    }

    @ViewBuilder private var footer: some View {
        switch result {
        case .ready:
            VStack(spacing: ProtoLayout.buttonGap) {
                PrimaryButton(title: OnbCopy.string("onb.s4.primary")) {
                    flow.track(.wallTestStarted)
                    safariShown = true
                }
                TextButton(title: OnbCopy.string("onb.s4.secondary")) {
                    flow.track(.wallTestSkipped)
                    flow.update { $0.wallTest = .skipped }
                    flow.afterWallTest()
                }
            }
        case .checking, .rebuilding:
            Color.clear.frame(height: BedrockSize.primaryHeight + ProtoLayout.buttonGap + BedrockSize.textButtonHeight)
        case .held, .unverified:
            VStack(spacing: 0) {
                PrimaryButton(title: OnbCopy.string("onb.s4.held_primary")) { flow.afterWallTest() }
                    .bedrockAppear(.settle, delay: result == .held ? 0.4 : 0)
                Color.clear.frame(height: 50)
            }
        case .opened:
            VStack(spacing: 0) {
                PrimaryButton(title: OnbCopy.string("onb.s4.opened_primary")) { rebuild() }
                Color.clear.frame(height: 50)
            }
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
            BedrockHaptics.lock()
            AccessibilityNotification.Announcement(OnbCopy.string("onb.s4.a11y_held")).post()
            if !reduceMotion { heldScale = 1.06 }
            result = .held
            withAnimation(BedrockMotion.lock) { heldScale = 1 }
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
