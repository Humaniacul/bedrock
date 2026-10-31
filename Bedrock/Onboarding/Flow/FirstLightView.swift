import SwiftUI

/// The First Light onboarding (SPEC.md). One backdrop and one chapter bar sit
/// under every screen, so the horizon and the bar's fill move from screen to
/// screen instead of fading with them; each screen Rises in and out above them.
/// The flow-wide pieces live here too: the resume toast, the Finish later and
/// crisis sheets, and B9's Preview tag.
struct FirstLightView: View {
    let mode: FirstLightFlow.Mode
    let onFinish: (FirstLightFlow.Ending) -> Void

    /// Made once, on appear: the flow loads and saves state, so it must not be
    /// rebuilt each time a parent re-renders.
    @State private var flow: FirstLightFlow?

    var body: some View {
        if let flow {
            FirstLightStage(flow: flow)
        } else {
            OnboardingBackdrop(level: 0)
                .onAppear { flow = FirstLightFlow(mode: mode, onFinish: onFinish) }
        }
    }
}

private struct FirstLightStage: View {
    @Bindable var flow: FirstLightFlow

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var dawn: Double {
        flow.dawnOverride ?? Dawn.level(for: flow.current.dawnScreen)
    }

    var body: some View {
        ZStack(alignment: .top) {
            OnboardingBackdrop(level: dawn)

            screen(flow.current)
                .id(flow.current)
                .transition(.rise(reduceMotion: reduceMotion))

            chapterBar
        }
        .animation(BedrockMotion.riseOut, value: flow.current)
        .environment(flow)
        .environment(\.sharedOnboardingChrome, true)
        .overlay(alignment: .top) { previewTag }
        .bedrockToast($flow.toast)
        .bedrockSheet(isPresented: $flow.showsFinishLater, title: OnbCopy.string("onb.fl.sheet_title")) {
            FinishLaterSheet()
                .environment(flow)
        }
        .bedrockSheet(isPresented: $flow.showsCrisis, title: CrisisSheetContent.title) {
            CrisisSheetContent { flow.showsCrisis = false }
        }
        .onChange(of: flow.showsCrisis) { _, shown in
            if shown { flow.track(.crisisOpened) }
        }
        .task { flow.track(.screenViewed) }
    }

    @ViewBuilder private func screen(_ id: ScreenID) -> some View {
        switch id {
        case .s1, .r1: ArrivalScreen()
        case .s2: ScreenTimeScreen()
        case .s2_d: ScreenTimeDeclinedScreen()
        case .b2: ManagedScreen()
        case .b9: PreviewModeScreen()
        case .s3: WallUpScreen()
        case .s4: WallTestScreen()
        case .s5: HardHoursScreen()
        case .s6: UnderneathScreen()
        case .s7: WordScreen()
        case .s8: StoneScreen()
        case .s9: DoorScreen()
        case .s10: PathScreen()
        case .s11: KeyHolderScreen()
        case .s12: PaywallScreen()
        case .s12u: NotReadyScreen()
        case .siwa: SignInScreen()
        case .s13_1: LetterScreen()
        case .s13_2b: BlindEntryIntroScreen()
        case .s13_3b: PracticeScreen()
        case .s13_4b: RealRunScreen()
        case .s13_5a: CodeCheckScreen()
        case .s13_5b: SwitchOffScreen()
        case .s13_6: SealedScreen()
        case .s13_7a: CodeMismatchScreen()
        case .s13_7b: LockNotSavedScreen()
        case .s13_2p: InviteScreen()
        case .s14: HeadsUpScreen()
        case .s15: PressOnceScreen()
        case .sp1: SupporterWelcomeScreen()
        case .sp2: SupporterTermsScreen()
        case .sp3: SupporterAlertsScreen()
        case .sp4: SupporterDoneScreen()
        case .home: OnboardingBackdrop(level: 1) // Home lives outside the flow
        }
    }

    /// The chapter bar at 58pt, moved with the safe area like the scaffold's chrome.
    private var chapterBar: some View {
        GeometryReader { proxy in
            if let bar = flow.current.chapterBar {
                ChapterBar(current: bar.chapter, progress: bar.progress)
                    .padding(.horizontal, Space.s6)
                    .padding(.top, BedrockSize.chapterBarTop + proxy.safeAreaInsets.top - BedrockSize.referenceTopInset)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea(.container)
        .animation(BedrockMotion.reducedFade, value: flow.current.chapterBar == nil)
        .allowsHitTesting(false)
    }

    /// B9: “Preview” under the Dynamic Island for the rest of the flow.
    @ViewBuilder private var previewTag: some View {
        if flow.state.previewMode {
            PreviewTag()
                .offset(y: -BedrockSize.previewTagLift)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Finish later (FL)

private struct FinishLaterSheet: View {
    @Environment(FirstLightFlow.self) private var flow

    var body: some View {
        Text(OnbCopy.string("onb.fl.sheet_body"))
            .font(BedrockFont.body)
            .lineSpacing(BedrockLine.body.lineSpacing)
            .foregroundStyle(BedrockColor.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
        VStack(spacing: Space.s2) {
            PrimaryButton(title: OnbCopy.string("onb.fl.primary")) {
                flow.showsFinishLater = false
                flow.finishLater()
            }
            TextButton(title: OnbCopy.string("onb.fl.secondary"), fullWidth: true) {
                flow.showsFinishLater = false
            }
        }
        .padding(.top, Space.s3)
    }
}

// MARK: - Rise (screen to screen)

/// Out: ease-in 0.18s, fade and 8pt up. In: Settle after 0.08s, from 16pt below
/// at 98%. Reduce Motion: a fade.
private struct RiseEffect: ViewModifier {
    let y: CGFloat
    let scale: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(y: y)
    }
}

extension AnyTransition {
    static func rise(reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return AnyTransition.opacity.animation(BedrockMotion.reducedFade) }
        let rest = RiseEffect(y: 0, scale: 1, opacity: 1)
        let insertion = AnyTransition
            .modifier(active: RiseEffect(y: 16, scale: 0.98, opacity: 0), identity: rest)
            .animation(BedrockMotion.settle.delay(BedrockMotion.riseInDelay))
        let removal = AnyTransition
            .modifier(active: RiseEffect(y: -8, scale: 1, opacity: 0), identity: rest)
            .animation(BedrockMotion.riseOut)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

// MARK: - Scaffold for flow screens

extension OnboardingScaffold {
    /// A First Light screen: its chapter bar, back (when there's somewhere to go
    /// back to) and Finish later (S4–S11, once the wall is up) come from the flow.
    init(_ screen: ScreenID,
         flow: FirstLightFlow,
         back: Bool = true,
         onClose: (() -> Void)? = nil,
         closeLabel: String = "",
         @ViewBuilder content: () -> Content,
         @ViewBuilder footer: () -> Footer,
         @ViewBuilder footerAccessory: () -> Accessory) {
        let canLeave = flow.canGoBack || flow.mode != .firstRun
        let finishLater = screen.showsFinishLater && flow.mode == .firstRun
            && (flow.state.wallUp || flow.state.previewMode)
        self.init(screen: screen,
                  chapter: screen.chapterBar?.chapter,
                  chapterProgress: screen.chapterBar?.progress ?? 0,
                  onBack: back && canLeave ? { flow.back() } : nil,
                  onFinishLater: finishLater ? { flow.showsFinishLater = true } : nil,
                  onClose: onClose,
                  closeLabel: closeLabel,
                  content: content,
                  footer: footer,
                  footerAccessory: footerAccessory)
    }
}

extension OnboardingScaffold where Accessory == EmptyView {
    init(_ screen: ScreenID,
         flow: FirstLightFlow,
         back: Bool = true,
         onClose: (() -> Void)? = nil,
         closeLabel: String = "",
         @ViewBuilder content: () -> Content,
         @ViewBuilder footer: () -> Footer) {
        self.init(screen, flow: flow, back: back, onClose: onClose, closeLabel: closeLabel,
                  content: content, footer: footer, footerAccessory: { EmptyView() })
    }
}
