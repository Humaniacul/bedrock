import SwiftUI

/// The dawn horizon behind every onboarding screen, as the prototype draws it:
/// an ellipse 1.8× the screen's width and 560pt tall whose centre sits 20pt above
/// the bottom edge, Glow at 0.36 fading to Ember at 0.12 (55%) and to nothing.
/// Its opacity is the screen's Dawn level, animated with `BedrockMotion.dawn`.
struct HorizonGlow: View {
    let level: Double

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * BedrockSize.horizonWidthFactor
            EllipticalGradient(stops: [
                .init(color: BedrockColor.horizonCore, location: 0),
                .init(color: BedrockColor.horizonMid, location: 0.55),
                .init(color: .clear, location: 1),
            ], center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
            .frame(width: width, height: BedrockSize.horizonHeight)
            .position(x: proxy.size.width / 2, y: proxy.size.height - BedrockSize.horizonLift)
        }
        .opacity(level)
        .animation(BedrockMotion.dawn, value: level)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
