import SwiftUI

/// Fade + lift into place, optionally staggered. Instant under Reduce Motion.
/// Shared by the onboarding beats and the paywall.
struct RiseIn: ViewModifier {
    let delay: Double
    let reduceMotion: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 16)
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                } else {
                    withAnimation(.smooth(duration: 0.6).delay(delay)) { shown = true }
                }
            }
    }
}

extension View {
    /// Fade + lift entrance, optionally staggered. Instant under Reduce Motion.
    func riseIn(_ delay: Double = 0, reduceMotion: Bool) -> some View {
        modifier(RiseIn(delay: delay, reduceMotion: reduceMotion))
    }
}
