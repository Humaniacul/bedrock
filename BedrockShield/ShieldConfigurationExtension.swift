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

    /// The prototype's shield mark, drawn once: the grey standing stone (64 × 76,
    /// 160°, #4A433C → #241F1B) with an ember line across it, glowing, tilted 8°.
    private static let stoneMark: UIImage = {
        let size = CGSize(width: 64, height: 76)
        let points: [CGPoint] = [CGPoint(x: 0.14, y: 0.03), CGPoint(x: 0.50, y: 0.00), CGPoint(x: 0.86, y: 0.04),
                                 CGPoint(x: 1.00, y: 1.00), CGPoint(x: 0.00, y: 1.00)]
        return UIGraphicsImageRenderer(size: size).image { context in
            let cg = context.cgContext
            let path = UIBezierPath()
            for (index, point) in points.enumerated() {
                let p = CGPoint(x: point.x * size.width, y: point.y * size.height)
                index == 0 ? path.move(to: p) : path.addLine(to: p)
            }
            path.close()
            cg.saveGState()
            path.addClip()
            // CSS 160°: from the top, slightly left, to the bottom, slightly right.
            let angle = 160 * CGFloat.pi / 180
            let direction = CGPoint(x: sin(angle), y: -cos(angle))
            let length = abs(size.width * sin(angle)) + abs(size.height * cos(angle))
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let colors = [UIColor(red: 0x4A / 255, green: 0x43 / 255, blue: 0x3C / 255, alpha: 1).cgColor,
                          UIColor(red: 0x24 / 255, green: 0x1F / 255, blue: 0x1B / 255, alpha: 1).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(gradient,
                                      start: CGPoint(x: center.x - direction.x * length / 2, y: center.y - direction.y * length / 2),
                                      end: CGPoint(x: center.x + direction.x * length / 2, y: center.y + direction.y * length / 2),
                                      options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
            // The line: 10pt in from the left, 12pt from the right, 50pt down.
            let line = CGRect(x: 10, y: 50, width: size.width - 22, height: 2)
            cg.translateBy(x: line.midX, y: line.midY)
            cg.rotate(by: -8 * .pi / 180)
            cg.setShadow(offset: .zero, blur: 8, color: UIColor(BedrockColor.emberGlow).withAlphaComponent(0.9).cgColor)
            cg.setFillColor(UIColor(BedrockColor.emberGlow).cgColor)
            cg.fill(CGRect(x: -line.width / 2, y: -line.height / 2, width: line.width, height: line.height))
            cg.restoreGState()
        }
    }()
}
