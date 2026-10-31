import SwiftUI

/// Bottom sheet for Bedrock content: crisis, limits, existing passcode, other
/// plans, Finish later, stuck (COMPONENTS.md). A system sheet — the spec calls for
/// standard presentation and system behaviour under Reduce Motion — styled with
/// `bgSurface`, rounded top corners, a 1pt `lineStrong` top border and a 36 × 5
/// grabber. VoiceOver focus starts on the title. Dismissed by dragging, tapping
/// the dimmed area, or the sheet's own button.
struct BedrockSheet<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Capsule()
                .fill(BedrockColor.lineStrong)
                .frame(width: BedrockSize.grabber.width, height: BedrockSize.grabber.height)
                .frame(maxWidth: .infinity)
                .padding(.bottom, Space.s2)
                .accessibilityHidden(true)

            Text(title)
                .font(BedrockFont.titleS)
                .lineSpacing(BedrockLine.titleS.lineSpacing)
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)

            content
        }
        .padding(.horizontal, Space.s6)
        .padding(.top, Space.s3)
        .padding(.bottom, Space.s6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { titleFocused = true }
    }
}

extension View {
    /// Presents a `BedrockSheet`, sized to its content (scrolls when that's taller
    /// than the screen, e.g. at accessibility text sizes).
    func bedrockSheet<Content: View>(isPresented: Binding<Bool>,
                                     title: String,
                                     @ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(BedrockSheetPresenter(isPresented: isPresented, title: title, sheetContent: content))
    }
}

/// Carries the presenter's text size into the sheet. A sheet is a new presentation,
/// so a size set in the view tree (previews, or a screen that caps it) doesn't
/// reach it on its own; with the system setting the two are the same.
private struct BedrockSheetPresenter<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let sheetContent: () -> SheetContent

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            BedrockSheetHost(title: title, content: sheetContent)
                .dynamicTypeSize(dynamicTypeSize)
        }
    }
}

private struct BedrockSheetHost<Content: View>: View {
    let title: String
    let content: () -> Content

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            BedrockSheet(title: title, content: content)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight)] : [.medium])
        .presentationCornerRadius(Radius.sheet)
        .presentationDragIndicator(.hidden) // our own grabber, in Bedrock's colours
        .presentationBackground {
            ZStack(alignment: .top) {
                BedrockColor.bgSurface
                SheetTopBorder()
            }
        }
    }
}

/// The 1pt `lineStrong` border along the sheet's top edge and corners.
private struct SheetTopBorder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous)
            .inset(by: 0.5)
            .stroke(BedrockColor.lineStrong, lineWidth: 1)
            .mask(alignment: .top) {
                Rectangle().frame(height: Radius.sheet)
            }
            .accessibilityHidden(true)
    }
}

#if DEBUG
struct BedrockSheetPreview: View {
    @State private var isPresented = true

    var body: some View {
        PreviewPage {
            TextButton(title: OnbCopy.string("onb.s4.top_right")) { isPresented = true }
        }
        .bedrockSheet(isPresented: $isPresented, title: OnbCopy.string("onb.fl.sheet_title")) {
            Text(OnbCopy.string("onb.fl.sheet_body"))
                .font(BedrockFont.body)
                .lineSpacing(BedrockLine.body.lineSpacing)
                .foregroundStyle(BedrockColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: Space.s2) {
                PrimaryButton(title: OnbCopy.string("onb.fl.primary")) { isPresented = false }
                TextButton(title: OnbCopy.string("onb.fl.secondary"), fullWidth: true) { isPresented = false }
            }
            .padding(.top, Space.s3)
        }
    }
}

#Preview("BedrockSheet · 402×874", traits: .fixedLayout(width: 402, height: 874)) { BedrockSheetPreview().onboardingPreview(.standard) }
#Preview("BedrockSheet · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { BedrockSheetPreview().onboardingPreview(.reduceMotion) }
#Preview("BedrockSheet · AX5", traits: .fixedLayout(width: 402, height: 874)) { BedrockSheetPreview().onboardingPreview(.ax5) }
#Preview("BedrockSheet · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { BedrockSheetPreview().onboardingPreview(.ax5ReduceMotion) }
#endif
