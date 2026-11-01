import Combine
import SwiftUI
import UIKit

/// The frame every onboarding screen sits in, as the prototype lays it out on
/// the 402 × 874 reference (62pt top safe area, 34pt bottom):
///
/// - Content starts at 112pt, or 150pt when back or Finish later shows; 24pt sides.
///   S1 and SP1 start at 0 and place their own stone mark.
/// - The footer (the buttons) is pinned so its last control ends 46pt (40pt on
///   some screens) above the screen's bottom edge; over the keyboard it rides
///   12pt above it. Content scrolls when it doesn't fit, with a hairline over it.
/// - Back and Finish later at 92pt, 20pt in from the sides; close at 58pt.
/// - The backdrop and chapter bar are drawn once by `FirstLightView`.
///
/// Points are reference points; on other iPhones they move with the safe area.
struct OnboardingScaffold<Content: View, Footer: View>: View {
    let screen: ScreenID
    let top: CGFloat
    let bottom: CGFloat
    var onBack: (() -> Void)?
    var onFinishLater: (() -> Void)?
    var onClose: (() -> Void)?
    var closeLabel: String
    let content: Content
    let footer: Footer

    @Environment(\.sharedOnboardingChrome) private var sharedChrome
    @Environment(\.onboardingScrollAnchor) private var scrollAnchor
    @State private var contentUnderFooter = false
    @State private var viewport: CGSize = .zero
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollPosition = ScrollPosition(edge: .top)

    var body: some View {
        GeometryReader { proxy in
            let insets = Insets(proxy.safeAreaInsets)
            let shift = insets.top - BedrockSize.referenceTopInset

            ZStack(alignment: .top) {
                if !sharedChrome {
                    OnboardingBackdrop(level: Dawn.level(for: screen.dawnScreen))
                }

                VStack(spacing: 0) {
                    Color.clear.frame(height: max(top + shift, 0))
                    scrollingContent(bottomInset: hasFooter ? 0 : footerBottom(insets))
                    if hasFooter { footerArea(bottomEdge: footerBottom(insets)) }
                }

                chrome(shift: shift)
            }
        }
        // Laid out over the whole screen, keyboard included: the footer's own
        // bottom padding handles the keyboard, so nothing is subtracted twice.
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            keyboardChanged(note)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { note in
            keyboardChanged(note, hiding: true)
        }
        .privacyCover(screen.usesPrivacyCover)
    }

    // MARK: Layers

    /// No footer (S12, where everything scrolls, the CTA included): the content
    /// runs to the bottom edge and keeps the bottom padding itself.
    private var hasFooter: Bool { Footer.self != EmptyView.self }

    private func scrollingContent(bottomInset: CGFloat) -> some View {
        ScrollView {
            // At least the visible height, so a screen's Spacers can centre an
            // illustration or push a block down, as the prototype's flex column does.
            FillHeight(minHeight: viewport.height, width: viewport.width) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ProtoLayout.side)
                    .padding(.bottom, bottomInset)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .defaultScrollAnchor(scrollAnchor, for: .sizeChanges)
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.visibleRect.maxY < geometry.contentSize.height - 1
        } action: { _, isUnder in
            contentUnderFooter = isUnder
        }
        .onScrollGeometryChange(for: CGSize.self) { $0.containerSize } action: { _, size in
            viewport = size
        }
    }

    private func footerArea(bottomEdge: CGFloat) -> some View {
        VStack(spacing: 0) { footer }
            .padding(.horizontal, ProtoLayout.side)
            .padding(.top, Space.s2)
            .padding(.bottom, bottomEdge)
            .overlay(alignment: .top) {
                if contentUnderFooter {
                    Rectangle()
                        .fill(BedrockColor.lineSubtle)
                        .frame(height: 1)
                        .accessibilityHidden(true)
                }
            }
    }

    /// 46pt (or 40pt) above the bottom edge on the reference, moved with the
    /// home-indicator inset; 12pt above the keyboard when it's up.
    private func footerBottom(_ insets: Insets) -> CGFloat {
        if keyboardHeight > 0 { return keyboardHeight + Space.s3 }
        return max(bottom + insets.bottom - BedrockSize.referenceBottomInset, Space.s4)
    }

    private func chrome(shift: CGFloat) -> some View {
        ZStack(alignment: .top) {
            if onBack != nil || onFinishLater != nil {
                HStack(spacing: Space.s2) {
                    if let onBack {
                        GlassCircleButton(kind: .back, accessibilityLabel: OnbCopy.string("onb.common.back"), action: onBack)
                    }
                    Spacer(minLength: 0)
                    if let onFinishLater { FinishLaterButton(action: onFinishLater) }
                }
                .padding(.horizontal, ProtoLayout.controlSide)
                .padding(.top, ProtoLayout.controlTop + shift)
            }
            if let onClose {
                HStack {
                    Spacer()
                    GlassCircleButton(kind: .close, accessibilityLabel: closeLabel, action: onClose)
                }
                .padding(.horizontal, ProtoLayout.controlSide)
                .padding(.top, ProtoLayout.closeTop + shift)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    // MARK: Keyboard

    private func keyboardChanged(_ note: Notification, hiding: Bool = false) {
        let end = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let screenHeight = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.height }.first ?? end.maxY
        let height = hiding ? 0 : max(0, screenHeight - end.minY)
        withAnimation(.easeOut(duration: duration)) { keyboardHeight = height }
        // Bring the field and what's under it into view once the keyboard settles.
        guard height > 0, scrollAnchor == .bottom else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            withAnimation(BedrockMotion.expand) { scrollPosition.scrollTo(edge: .bottom) }
        }
    }

    // MARK: Insets

    /// Safe-area insets, or the reference device's when there are none at all
    /// (a fixed-size preview); any real iPhone has a top inset.
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

extension OnboardingScaffold {
    /// A First Light screen. Back shows when there's somewhere to go back to;
    /// Finish later on S4–S11 once the wall is up. Content starts at 150pt with
    /// either, else 112pt, unless the screen sets its own `top`.
    init(_ screen: ScreenID,
         flow: FirstLightFlow,
         back: Bool = true,
         top: CGFloat? = nil,
         bottom: CGFloat = ProtoLayout.bottom,
         onClose: (() -> Void)? = nil,
         closeLabel: String = "",
         @ViewBuilder content: () -> Content,
         @ViewBuilder footer: () -> Footer) {
        let canLeave = flow.canGoBack || flow.mode != .firstRun
        let showsBack = back && canLeave
        let finishLater = screen.showsFinishLater && flow.mode == .firstRun
            && (flow.state.wallUp || flow.state.previewMode) && !flow.state.hasNoWall
        self.screen = screen
        self.top = top ?? (showsBack || finishLater ? ProtoLayout.topWithBack : ProtoLayout.topWithChapter)
        self.bottom = bottom
        self.onBack = showsBack ? { flow.back() } : nil
        self.onFinishLater = finishLater ? { flow.showsFinishLater = true } : nil
        self.onClose = onClose
        self.closeLabel = closeLabel
        self.content = content()
        self.footer = footer()
    }
}

extension OnboardingScaffold where Footer == EmptyView {
    /// A screen whose controls all scroll with its content.
    init(_ screen: ScreenID,
         flow: FirstLightFlow,
         back: Bool = true,
         top: CGFloat? = nil,
         bottom: CGFloat = ProtoLayout.bottom,
         onClose: (() -> Void)? = nil,
         closeLabel: String = "",
         @ViewBuilder content: () -> Content) {
        self.init(screen, flow: flow, back: back, top: top, bottom: bottom, onClose: onClose, closeLabel: closeLabel,
                  content: content, footer: { EmptyView() })
    }
}

extension OnboardingScaffold {
    /// A footer with a secondary control under the primary, 6pt apart.
    init<Primary: View, Accessory: View>(_ screen: ScreenID,
                                         flow: FirstLightFlow,
                                         back: Bool = true,
                                         top: CGFloat? = nil,
                                         bottom: CGFloat = ProtoLayout.bottom,
                                         onClose: (() -> Void)? = nil,
                                         closeLabel: String = "",
                                         @ViewBuilder content: () -> Content,
                                         @ViewBuilder footer: () -> Primary,
                                         @ViewBuilder footerAccessory: () -> Accessory)
    where Footer == TupleView<(Primary, Accessory)> {
        let primary = footer()
        let accessory = footerAccessory()
        self.init(screen, flow: flow, back: back, top: top, bottom: bottom, onClose: onClose, closeLabel: closeLabel,
                  content: content, footer: { primary; accessory })
    }
}

/// Lays its content out at least `minHeight` tall, proposing the final height so
/// Spacers inside can expand; taller content keeps its own height (and scrolls).
struct FillHeight: Layout {
    var minHeight: CGFloat
    /// The width to measure at when the scroll view doesn't propose one, so
    /// wrapping text is measured as it will be laid out.
    var width: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let measureWidth = proposal.width ?? (width > 0 ? width : nil)
        let ideal = child.sizeThatFits(ProposedViewSize(width: measureWidth, height: nil))
        return CGSize(width: measureWidth ?? ideal.width, height: max(ideal.height, minHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(bounds.size))
    }
}

/// Obsidian, the horizon at a Dawn level, and the noise tile at 6%.
struct OnboardingBackdrop: View {
    let level: Double

    var body: some View {
        ZStack {
            BedrockColor.bgBase
            HorizonGlow(level: level)
            Image("NoiseTile")
                .resizable(resizingMode: .tile)
                .opacity(BedrockSize.noiseOpacity)
                .blendMode(.overlay)
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

extension EnvironmentValues {
    /// Set by `FirstLightView`: the backdrop and chapter bar are drawn above the screens.
    @Entry var sharedOnboardingChrome = false
    /// Where the content stays pinned when the visible area changes size.
    @Entry var onboardingScrollAnchor: UnitPoint? = nil
}
