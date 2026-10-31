import ManagedSettings
import ManagedSettingsUI
import SwiftUI
import UIKit

/// The shield over apps and sites behind the wall (SPEC.md S7: “The word …
/// sits on every shield instead of a lecture”). Nothing on it says what Bedrock
/// is for: a neutral title, their own word, the stone mark, Bedrock's colours.
/// Close shuts it; “I need a minute” (handled by BedrockShieldAction) sends a
/// quiet notification that opens the urge flow.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        bedrockShield()
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        bedrockShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        bedrockShield()
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        bedrockShield()
    }

    private func bedrockShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(BedrockColor.bgBase),
            icon: Self.stoneMark,
            title: ShieldConfiguration.Label(text: copy("onb.shield.title"), color: UIColor(BedrockColor.inkPrimary)),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: UIColor(BedrockColor.inkSecondary)),
            primaryButtonLabel: ShieldConfiguration.Label(text: copy("onb.shield.close"), color: UIColor(BedrockColor.onEmber)),
            primaryButtonBackgroundColor: UIColor(BedrockColor.ember),
            secondaryButtonLabel: ShieldConfiguration.Label(text: copy("onb.shield.minute"), color: UIColor(BedrockColor.emberGlow))
        )
    }

    /// “You want to be steady.” — or a neutral line before a word is chosen.
    private var subtitle: String {
        let word = AppGroup.defaults.string(forKey: AppGroup.Key.userWord)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !word.isEmpty else { return copy("onb.shield.subtitle_no_word") }
        return copy("onb.shield.subtitle").replacingOccurrences(of: "{word}", with: word)
    }

    private func copy(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }

    /// The five-point stone mark in ember, drawn once (matches the app icon).
    private static let stoneMark: UIImage = {
        let size = CGSize(width: 56, height: 80)
        let points: [CGPoint] = [CGPoint(x: 0.24, y: 0.00), CGPoint(x: 0.86, y: 0.08), CGPoint(x: 1.00, y: 0.64),
                                 CGPoint(x: 0.58, y: 1.00), CGPoint(x: 0.00, y: 0.76)]
        return UIGraphicsImageRenderer(size: size).image { context in
            let path = UIBezierPath()
            for (index, point) in points.enumerated() {
                let p = CGPoint(x: point.x * size.width, y: point.y * size.height)
                index == 0 ? path.move(to: p) : path.addLine(to: p)
            }
            path.close()
            path.addClip()
            let colors = [UIColor(BedrockColor.emberHot).cgColor, UIColor(BedrockColor.ember).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                context.cgContext.drawLinearGradient(gradient, start: .zero,
                                                     end: CGPoint(x: size.width, y: size.height), options: [])
            }
        }
    }()
}
