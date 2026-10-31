#if DEBUG
import SwiftUI

/// The four states every onboarding component is previewed in: the 402 × 874
/// reference at the default text size and at AX5, each with Reduce Motion on
/// and off. Reduce Motion is forced through the underscored environment key,
/// which feeds `accessibilityReduceMotion` (the public one is read-only).
enum OnboardingPreviewVariant: String, CaseIterable {
    case standard, reduceMotion, ax5, ax5ReduceMotion

    var isAX5: Bool { self == .ax5 || self == .ax5ReduceMotion }
    var reducesMotion: Bool { self == .reduceMotion || self == .ax5ReduceMotion }
}

extension View {
    func onboardingPreview(_ variant: OnboardingPreviewVariant) -> some View {
        self
            .environment(\.dynamicTypeSize, variant.isAX5 ? .accessibility5 : .large)
            .environment(\._accessibilityReduceMotion, variant.reducesMotion)
            .preferredColorScheme(.dark)
    }
}

/// A plain obsidian page at the reference size, for components shown on their own.
struct PreviewPage<Content: View>: View {
    var alignment: Alignment = .center
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: alignment) {
            BedrockColor.bgBase.ignoresSafeArea()
            content
                .padding(.horizontal, Space.s6)
        }
    }
}
#endif
