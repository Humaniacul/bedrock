import SwiftUI

/// A statement/quote screen rendered with the Chisel-Type engine: the headline
/// is carved glyph-by-glyph (tap to skip), then the body + button fade in.
struct ChiselBeatView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let content: ChiselContent
    var onNext: () -> Void

    @State private var carved = false

    private var headlineFont: Font {
        content.isQuote
            ? .system(.largeTitle, design: .serif, weight: .bold)
            : .system(.title, design: .serif, weight: .semibold)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            if let eyebrow = content.eyebrow {
                Text(eyebrow)
                    .font(Theme.Typography.monoCaption)
                    .tracking(3)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .riseIn(0, reduceMotion: reduceMotion)
            }

            ChiselText(
                text: content.headline,
                font: headlineFont,
                onFinished: { withAnimation(.smooth(duration: 0.5)) { carved = true } }
            )
            .id(content.headline) // restart the carve if the beat's text changes

            if let body = content.body {
                Text(body)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(carved ? 1 : 0)
                    .animation(.smooth(duration: 0.5), value: carved)
            }

            Spacer()
            Button(content.cta) { onNext() }
                .buttonStyle(.bedrockPrimary)
                .opacity(carved ? 1 : 0)
                .animation(.smooth(duration: 0.4), value: carved)
                .allowsHitTesting(carved)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
