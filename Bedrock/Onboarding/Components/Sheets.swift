import SwiftUI

// The prototype's bottom sheet, toast and privacy cover.

// MARK: - BedrockSheet

/// A bottom sheet as the prototype draws it: edge to edge, `bgSurface`, 32pt
/// top corners, a 1pt `lineStrong` top edge and a soft shadow; a 36 × 5
/// grabber 22pt above the content, 24pt sides, the home-indicator area below;
/// an optional serif 30/34 title. Over a 62% scrim that closes it.
struct BedrockSheet<Content: View>: View {
    let title: String?
    var titleGap: CGFloat = 10
    @ViewBuilder var content: Content

    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(BedrockColor.lineStrong)
                .frame(width: BedrockSize.grabber.width, height: BedrockSize.grabber.height)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 22)
                .accessibilityHidden(true)
            if let title {
                Text(title)
                    .ptype(.sheetTitle)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)
                    .padding(.bottom, titleGap)
            }
            content
        }
        .padding(.horizontal, ProtoLayout.side)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { titleFocused = true }
    }
}

extension View {
    /// Presents a `BedrockSheet` from the bottom edge, sized to its content (it
    /// scrolls when that's taller than the screen, at accessibility text sizes).
    /// A tap on the scrim, a drag down or the VoiceOver escape gesture closes it.
    func bedrockSheet<Content: View>(isPresented: Binding<Bool>,
                                     title: String?,
                                     titleGap: CGFloat = 10,
                                     @ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(BedrockSheetPresenter(isPresented: isPresented, title: title, titleGap: titleGap, sheetContent: content))
    }
}

private struct BedrockSheetPresenter<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String?
    let titleGap: CGFloat
    let sheetContent: () -> SheetContent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drag: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(isPresented)
            .overlay {
                ZStack(alignment: .bottom) {
                    if isPresented {
                        BedrockColor.scrim
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture { close() }
                            .transition(.opacity)
                            .accessibilityHidden(true)
                        card
                            .offset(y: drag)
                            .gesture(dragToClose)
                            .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                    }
                }
                .animation(reduceMotion ? BedrockMotion.reducedFade : .spring(response: 0.42, dampingFraction: 0.92),
                           value: isPresented)
            }
    }

    private var card: some View {
        ViewThatFits(in: .vertical) {
            sheet
            ScrollView { sheet }
                .scrollBounceBehavior(.basedOnSize)
        }
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32, style: .continuous)
                .fill(BedrockColor.bgSurface)
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32, style: .continuous)
                        .stroke(BedrockColor.lineStrong, lineWidth: 1)
                        .mask(alignment: .top) { Rectangle().frame(height: 33) }
                }
                .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: -20)
                .ignoresSafeArea(edges: .bottom)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { close() }
    }

    private var sheet: some View {
        BedrockSheet(title: title, titleGap: titleGap, content: sheetContent)
    }

    private var dragToClose: some Gesture {
        DragGesture()
            .onChanged { value in drag = max(value.translation.height, 0) }
            .onEnded { value in
                if value.translation.height > 120 || value.predictedEndTranslation.height > 260 {
                    close()
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { drag = 0 }
            }
    }

    private func close() {
        isPresented = false
    }
}

/// Body text inside a sheet: 17/24 Limestone.
struct SheetBody: View {
    let text: String
    var bottom: CGFloat = 24

    var body: some View {
        Text(text)
            .ptype(.body)
            .foregroundStyle(BedrockColor.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, bottom)
    }
}

// MARK: - Toast

/// A one-line notice at 58pt: a raised pill, 14pt Chalk, a soft shadow. Drops
/// 12pt and fades in, holds, fades out; announced by VoiceOver.
struct Toast: View {
    let text: String

    var body: some View {
        Text(text)
            .ptype(.notePlain)
            .foregroundStyle(BedrockColor.inkPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.s4)
            .padding(.vertical, 10)
            .background(Capsule().fill(BedrockColor.bgRaised))
            .overlay(Capsule().strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
            .padding(.horizontal, ProtoLayout.side)
    }
}

extension View {
    /// Shows `message` as a toast when it's set, then clears it.
    func bedrockToast(_ message: Binding<String?>) -> some View {
        modifier(ToastPresenter(message: message))
    }
}

private struct ToastPresenter: ViewModifier {
    @Binding var message: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: String?
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let shown {
                    Toast(text: shown)
                        .opacity(visible ? 1 : 0)
                        .offset(y: visible || reduceMotion ? 0 : -BedrockSize.toastDrop)
                        .padding(.top, ProtoLayout.toastTop - BedrockSize.referenceTopInset)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
            }
            .task(id: message) {
                guard let text = message else { return }
                shown = text
                visible = false
                withAnimation(reduceMotion ? BedrockMotion.reducedFade : .easeOut(duration: 0.3)) { visible = true }
                AccessibilityNotification.Announcement(text).post()
                try? await Task.sleep(for: .seconds(BedrockTiming.toastHold))
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: 0.38)) { visible = false }
                try? await Task.sleep(for: .seconds(0.4))
                guard !Task.isCancelled else { return }
                shown = nil
                message = nil
            }
    }
}

// MARK: - Privacy cover

/// Full-window obsidian with the stone mark, shown in the app switcher on S5–S8,
/// S13.1 and Home, so answers and the letter never sit in a snapshot.
struct PrivacyCover: View {
    var body: some View {
        ZStack {
            BedrockColor.bgBase
            StoneMarkView()
                .frame(width: 30, height: 36)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Covers the window with `PrivacyCover` whenever the scene isn't active.
    func privacyCover(_ isEnabled: Bool = true) -> some View {
        modifier(PrivacyCoverModifier(isEnabled: isEnabled))
    }
}

private struct PrivacyCoverModifier: ViewModifier {
    let isEnabled: Bool
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.overlay {
            if isEnabled && scenePhase != .active { PrivacyCover() }
        }
    }
}
