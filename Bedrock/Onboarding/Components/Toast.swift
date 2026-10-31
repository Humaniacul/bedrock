import SwiftUI

/// A one-line notice under the Dynamic Island: “Picking up where you left off.”,
/// “Link copied.”, “We’ll remind you tomorrow at noon.” (COMPONENTS.md).
/// Drops 12pt and fades in, holds 2s, fades out; announced by VoiceOver.
/// Reduce Motion: fade only. Content, not a control, so it's solid, not glass.
struct Toast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(BedrockFont.toast)
            .foregroundStyle(BedrockColor.inkPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.s4)
            .padding(.vertical, Space.s3)
            .background(Capsule().fill(BedrockColor.bgSurface))
            .overlay(Capsule().strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
            .padding(.horizontal, Space.s6)
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
                        .accessibilityHidden(true) // announced instead, so focus isn't stolen
                }
            }
            .task(id: message) {
                guard let text = message else { return }
                shown = text
                visible = false
                withAnimation(reduceMotion ? BedrockMotion.reducedFade : BedrockMotion.settle) { visible = true }
                AccessibilityNotification.Announcement(text).post()
                try? await Task.sleep(for: .seconds(BedrockTiming.toastHold))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? BedrockMotion.reducedFade : BedrockMotion.riseOut) { visible = false }
                try? await Task.sleep(for: .seconds(BedrockMotion.reducedFadeDuration))
                guard !Task.isCancelled else { return }
                shown = nil
                message = nil
            }
    }
}

#if DEBUG
struct ToastPreview: View {
    /// `autoplay` re-shows the toast so its motion can be watched; off, it sits still.
    var autoplay = false
    @State private var message: String?

    var body: some View {
        PreviewPage(alignment: .top) {
            if !autoplay {
                Toast(text: OnbCopy.string("onb.resume.toast"))
            }
        }
        .bedrockToast($message)
        .task {
            guard autoplay else { return }
            while !Task.isCancelled {
                message = OnbCopy.string("onb.resume.toast")
                try? await Task.sleep(for: .seconds(BedrockTiming.toastHold + 1.5))
            }
        }
    }
}

// Autoplay so the drop (off) and the fade (on) can be compared. The still state
// is `ToastPreview()` with no autoplay.
#Preview("Toast · 402×874", traits: .fixedLayout(width: 402, height: 874)) { ToastPreview(autoplay: true).onboardingPreview(.standard) }
#Preview("Toast · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ToastPreview(autoplay: true).onboardingPreview(.reduceMotion) }
#Preview("Toast · AX5", traits: .fixedLayout(width: 402, height: 874)) { ToastPreview(autoplay: true).onboardingPreview(.ax5) }
#Preview("Toast · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ToastPreview(autoplay: true).onboardingPreview(.ax5ReduceMotion) }
#endif
