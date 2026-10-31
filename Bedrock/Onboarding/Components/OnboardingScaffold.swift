import SwiftUI

/// The frame every onboarding screen sits in (COMPONENTS.md).
///
/// - Chapter bar at 58pt; back and Finish later (or close) at 92pt; content from
///   112pt, or 150pt when the back row shows; 24pt side margins. Points are from
///   the top of the 402 × 874 reference and move with the safe area elsewhere.
/// - The footer (the primary area) is pinned so the primary button sits 46pt above
///   the home indicator. `footerAccessory` (a link or text button, e.g. S1's link,
///   S4's Skip) sits in that 46pt band, under the primary.
/// - Background: `bgBase`, then `HorizonGlow` at the screen's Dawn level, then the
///   noise tile at 6%.
/// - Content scrolls when it doesn't fit (accessibility text sizes); while there's
///   content under the footer, a 1pt `lineSubtle` hairline shows on top of it.
/// - On S5–S8, S13.1 and Home, `PrivacyCover` covers the window when the scene goes
///   inactive.
///
/// The spec's `showsBack` / `showsFinishLater` / `showsClose` are the presence of
/// `onBack` / `onFinishLater` / `onClose`, so a control can't show without an action.
struct OnboardingScaffold<Content: View, Footer: View, Accessory: View>: View {
    let screen: ScreenID
    var chapter: Chapter?
    /// 0–1 within `chapter`.
    var chapterProgress: Double
    /// Overrides the screen's Dawn level (S3 rises a step once the wall is up; S9 dims).
    var dawn: Double?
    var onBack: (() -> Void)?
    var onFinishLater: (() -> Void)?
    var onClose: (() -> Void)?
    /// VoiceOver label for close: what it does (S12: “Keep the free wall”).
    var closeLabel: String
    let content: Content
    let footer: Footer
    let footerAccessory: Accessory

    /// Inside `FirstLightView`, the backdrop and chapter bar are drawn once by the
    /// router so the horizon and the bar's fill move between screens instead of
    /// fading with them. The scaffold keeps their space.
    @Environment(\.sharedOnboardingChrome) private var sharedChrome
    @State private var contentUnderFooter = false
    @State private var viewportHeight: CGFloat = 0

    init(screen: ScreenID,
         chapter: Chapter? = nil,
         chapterProgress: Double = 0,
         dawn: Double? = nil,
         onBack: (() -> Void)? = nil,
         onFinishLater: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         closeLabel: String = "",
         @ViewBuilder content: () -> Content,
         @ViewBuilder footer: () -> Footer,
         @ViewBuilder footerAccessory: () -> Accessory) {
        self.screen = screen
        self.chapter = chapter
        self.chapterProgress = chapterProgress
        self.dawn = dawn
        self.onBack = onBack
        self.onFinishLater = onFinishLater
        self.onClose = onClose
        self.closeLabel = closeLabel
        self.content = content()
        self.footer = footer()
        self.footerAccessory = footerAccessory()
    }

    private var showsChapterBar: Bool { chapter?.barLabelKey != nil }
    private var showsBackRow: Bool { onBack != nil || onFinishLater != nil || onClose != nil }

    var body: some View {
        GeometryReader { proxy in
            let insets = Insets(proxy.safeAreaInsets)
            let shift = insets.top - BedrockSize.referenceTopInset

            ZStack(alignment: .top) {
                if !sharedChrome { background }

                VStack(spacing: 0) {
                    Color.clear.frame(height: contentTop + shift)
                    scrollingContent
                    footerArea(bottomInset: insets.bottom)
                }

                chrome(shift: shift)
            }
        }
        .ignoresSafeArea(.container)
        .privacyCover(screen.usesPrivacyCover)
    }

    // MARK: Layers

    private var background: some View {
        OnboardingBackdrop(level: dawn ?? Dawn.level(for: screen.dawnScreen))
    }

    private var contentTop: CGFloat {
        if showsBackRow { return Space.contentTopWithBack }
        if showsChapterBar { return Space.contentTopWithChapter }
        return BedrockSize.referenceTopInset
    }

    private var scrollingContent: some View {
        ScrollView {
            // At least the visible height, so a screen can push part of its
            // content down with a Spacer (S1's lower-half text) and still scroll
            // once it outgrows the screen.
            FillHeight(minHeight: viewportHeight) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Space.s6)
                    .padding(.bottom, Space.s6)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.visibleRect.maxY < geometry.contentSize.height - 1
        } action: { _, isUnder in
            contentUnderFooter = isUnder
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, height in
            viewportHeight = height
        }
    }

    private func footerArea(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            footer
                .padding(.horizontal, Space.s6)
            // A container, so the 46pt band holds even when there's no accessory
            // (a frame on EmptyView lays out as nothing).
            ZStack { footerAccessory }
                .frame(maxWidth: .infinity, minHeight: Space.primaryBottom)
                .padding(.horizontal, Space.s6)
        }
        .padding(.top, Space.s3)
        .padding(.bottom, bottomInset)
        .overlay(alignment: .top) {
            if contentUnderFooter {
                Rectangle()
                    .fill(BedrockColor.lineSubtle)
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }
        }
    }

    private func chrome(shift: CGFloat) -> some View {
        ZStack(alignment: .top) {
            if let chapter, showsChapterBar, !sharedChrome {
                ChapterBar(current: chapter, progress: chapterProgress)
                    .padding(.horizontal, Space.s6)
                    .padding(.top, BedrockSize.chapterBarTop + shift)
            }
            if showsBackRow {
                HStack(spacing: Space.s2) {
                    if let onBack {
                        GlassCircleButton(kind: .back, accessibilityLabel: OnbCopy.string("onb.common.back"), action: onBack)
                    }
                    Spacer(minLength: 0)
                    if let onFinishLater {
                        FinishLaterButton(action: onFinishLater)
                    }
                    if let onClose {
                        GlassCircleButton(kind: .close, accessibilityLabel: closeLabel, action: onClose)
                    }
                }
                .padding(.horizontal, Space.s6)
                .padding(.top, BedrockSize.backRowTop + shift)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    // MARK: Insets

    /// Safe-area insets, or the reference device's when there are none at all
    /// (a fixed-size canvas preview); any real iPhone has a top inset.
    private struct Insets {
        let top: CGFloat
        let bottom: CGFloat

        init(_ edges: EdgeInsets) {
            if edges.top == 0 && edges.bottom == 0 {
                top = BedrockSize.referenceTopInset
                bottom = BedrockSize.referenceBottomInset
            } else {
                top = edges.top
                bottom = edges.bottom
            }
        }
    }
}

/// Lays its content out at least `minHeight` tall, proposing the final height so
/// Spacers inside can expand; taller content keeps its own height (and scrolls).
struct FillHeight: Layout {
    var minHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let ideal = child.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        return CGSize(width: proposal.width ?? ideal.width, height: max(ideal.height, minHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
    }
}

/// Obsidian, the horizon glow at a Dawn level, and the noise tile at 6%.
struct OnboardingBackdrop: View {
    let level: Double

    var body: some View {
        ZStack {
            BedrockColor.bgBase
            Color.clear.overlay(alignment: .bottom) {
                // Centred on the bottom edge; overlay so its 724pt width never sizes the layout.
                HorizonGlow(level: level)
                    .offset(y: BedrockSize.horizonGlow.height / 2)
            }
            Image("NoiseTile")
                .resizable(resizingMode: .tile)
                .opacity(BedrockSize.noiseOpacity)
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

extension EnvironmentValues {
    /// Set by `FirstLightView`: the backdrop and chapter bar are drawn above the screens.
    @Entry var sharedOnboardingChrome = false
}

extension OnboardingScaffold where Accessory == EmptyView {
    init(screen: ScreenID,
         chapter: Chapter? = nil,
         chapterProgress: Double = 0,
         dawn: Double? = nil,
         onBack: (() -> Void)? = nil,
         onFinishLater: (() -> Void)? = nil,
         onClose: (() -> Void)? = nil,
         closeLabel: String = "",
         @ViewBuilder content: () -> Content,
         @ViewBuilder footer: () -> Footer) {
        self.init(screen: screen, chapter: chapter, chapterProgress: chapterProgress, dawn: dawn,
                  onBack: onBack, onFinishLater: onFinishLater, onClose: onClose, closeLabel: closeLabel,
                  content: content, footer: footer, footerAccessory: { EmptyView() })
    }
}

#if DEBUG
/// The scaffold with chrome on: back, Finish later, the chapter bar, a disabled
/// primary. S5's copy, so lengths are real; not the S5 screen.
struct ScaffoldPreview: View {
    var body: some View {
        OnboardingScaffold(screen: .s5, chapter: .you, chapterProgress: 0.25,
                           onBack: {}, onFinishLater: {}) {
            PreviewHeading(prefix: "onb.s5")
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s5.primary"), isEnabled: false,
                          disabledHint: OnbCopy.string("onb.common.pick_at_least_one")) {}
        }
    }
}

/// The scaffold's footer band: a primary with a text button under it. S4's copy.
struct ScaffoldAccessoryPreview: View {
    var body: some View {
        OnboardingScaffold(screen: .s4, chapter: .wall, chapterProgress: 0.75,
                           onFinishLater: {}) {
            PreviewHeading(prefix: "onb.s4")
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s4.primary")) {}
        } footerAccessory: {
            TextButton(title: OnbCopy.string("onb.s4.secondary")) {}
        }
    }
}

/// Eyebrow, Title headline and body for a screen prefix, in the spec's type styles.
struct PreviewHeading: View {
    let prefix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(OnbCopy.string("\(prefix).eyebrow"))
                .bedrockEyebrow()
                .padding(.bottom, Space.s3)
            Text(OnbCopy.string("\(prefix).headline"))
                .font(BedrockFont.title)
                .tracking(BedrockLine.title.tracking)
                .lineSpacing(BedrockLine.title.lineSpacing)
                .foregroundStyle(BedrockColor.inkPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Space.s4)
            Text(OnbCopy.string("\(prefix).body"))
                .font(BedrockFont.body)
                .lineSpacing(BedrockLine.body.lineSpacing)
                .foregroundStyle(BedrockColor.inkSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Scaffold · 402×874", traits: .fixedLayout(width: 402, height: 874)) { ScaffoldPreview().onboardingPreview(.standard) }
#Preview("Scaffold · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ScaffoldPreview().onboardingPreview(.reduceMotion) }
#Preview("Scaffold · AX5", traits: .fixedLayout(width: 402, height: 874)) { ScaffoldPreview().onboardingPreview(.ax5) }
#Preview("Scaffold · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ScaffoldPreview().onboardingPreview(.ax5ReduceMotion) }

#Preview("Scaffold accessory · 402×874", traits: .fixedLayout(width: 402, height: 874)) { ScaffoldAccessoryPreview().onboardingPreview(.standard) }
#Preview("Scaffold accessory · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ScaffoldAccessoryPreview().onboardingPreview(.reduceMotion) }
#Preview("Scaffold accessory · AX5", traits: .fixedLayout(width: 402, height: 874)) { ScaffoldAccessoryPreview().onboardingPreview(.ax5) }
#Preview("Scaffold accessory · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ScaffoldAccessoryPreview().onboardingPreview(.ax5ReduceMotion) }
#endif
