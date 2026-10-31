import SwiftUI

/// Full-window obsidian with the stone mark, shown in the app switcher on S5–S8,
/// S13.1 and Home so answers and the letter never sit in a snapshot (SPEC.md
/// RESUME). `OnboardingScaffold` applies it; use `.privacyCover(_:)` elsewhere.
struct PrivacyCover: View {
    var body: some View {
        ZStack {
            BedrockColor.bgBase
            StoneMark()
                .fill(BedrockColor.stoneLight)
                .frame(width: BedrockSize.stoneMark.width, height: BedrockSize.stoneMark.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Covers the window with `PrivacyCover` whenever the scene isn't active —
    /// which is when iOS takes the app-switcher snapshot.
    func privacyCover(_ isEnabled: Bool = true) -> some View {
        modifier(PrivacyCoverModifier(isEnabled: isEnabled))
    }
}

private struct PrivacyCoverModifier: ViewModifier {
    let isEnabled: Bool
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.overlay {
            if isEnabled && scenePhase != .active {
                PrivacyCover()
            }
        }
    }
}

/// The five-point stone silhouette (ASSETS.md: “Prefer a Shape so it scales”).
/// ASSUMED outline: the canvas vector isn't in the handoff; swap the points for it.
struct StoneMark: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [CGPoint] = [
            CGPoint(x: 0.24, y: 0.00),
            CGPoint(x: 0.86, y: 0.08),
            CGPoint(x: 1.00, y: 0.64),
            CGPoint(x: 0.58, y: 1.00),
            CGPoint(x: 0.00, y: 0.76),
        ]
        var path = Path()
        path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
        path.closeSubpath()
        return path
    }
}

#if DEBUG
struct PrivacyCoverPreview: View {
    var body: some View { PrivacyCover() }
}

#Preview("PrivacyCover · 402×874", traits: .fixedLayout(width: 402, height: 874)) { PrivacyCoverPreview().onboardingPreview(.standard) }
#Preview("PrivacyCover · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { PrivacyCoverPreview().onboardingPreview(.reduceMotion) }
#Preview("PrivacyCover · AX5", traits: .fixedLayout(width: 402, height: 874)) { PrivacyCoverPreview().onboardingPreview(.ax5) }
#Preview("PrivacyCover · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { PrivacyCoverPreview().onboardingPreview(.ax5ReduceMotion) }
#endif
