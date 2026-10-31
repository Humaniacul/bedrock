import SwiftUI
import UIKit

/// The dawn horizon behind every onboarding screen (COMPONENTS.md): a radial
/// glow, 724 × 560pt so its edges never show, whose opacity animates to the
/// screen's `Dawn.level` with `BedrockMotion.dawn`. Never a live blur.
///
/// ASSETS.md specifies a pre-rendered PNG named for this. It isn't in the
/// handoff, so until a `HorizonGlow` image is added to the asset catalog this
/// draws an equivalent gradient once into its own layer (`horizonCore`, ASSUMED).
struct HorizonGlow: View {
    let level: Double

    var body: some View {
        glow
            .frame(width: BedrockSize.horizonGlow.width, height: BedrockSize.horizonGlow.height)
            .opacity(level)
            .animation(BedrockMotion.dawn, value: level)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var glow: some View {
        if let image = Self.asset {
            Image(uiImage: image).resizable()
        } else {
            EllipticalGradient(colors: [BedrockColor.horizonCore, .clear], center: .center)
                .drawingGroup()
        }
    }

    private static let asset = UIImage(named: "HorizonGlow")
}
