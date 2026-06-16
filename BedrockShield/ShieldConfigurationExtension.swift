import ManagedSettings
import ManagedSettingsUI
import UIKit

/// ShieldConfiguration extension (§3, §4 Intercept Moment). Styles the block
/// screen so it is never a dead wall — it points the user back into Bedrock to
/// ride out the urge.
///
/// NOTE: this runs in a separate process and cannot import the SwiftUI `Theme`,
/// so the palette is mirrored here as raw `UIColor`s. Keep in sync with §6.1.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        bedrockShield()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        bedrockShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        bedrockShield()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        bedrockShield()
    }

    private func bedrockShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: Palette.obsidian,
            icon: nil,
            title: ShieldConfiguration.Label(text: "Pause.", color: Palette.quartz),
            subtitle: ShieldConfiguration.Label(
                text: "This is the urge talking. Open Bedrock and ride it out — it passes.",
                color: Palette.ash
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Open Bedrock", color: Palette.obsidian),
            primaryButtonBackgroundColor: Palette.ember,
            secondaryButtonLabel: nil
        )
    }

    // §6.1 palette mirror (process-isolated from the SwiftUI Theme).
    private enum Palette {
        static let obsidian = UIColor(red: 0x0E / 255, green: 0x0F / 255, blue: 0x12 / 255, alpha: 1)
        static let quartz   = UIColor(red: 0xEA / 255, green: 0xE7 / 255, blue: 0xE1 / 255, alpha: 1)
        static let ash      = UIColor(red: 0x6B / 255, green: 0x70 / 255, blue: 0x79 / 255, alpha: 1)
        static let ember    = UIColor(red: 0xE2 / 255, green: 0x68 / 255, blue: 0x3B / 255, alpha: 1)
    }
}
