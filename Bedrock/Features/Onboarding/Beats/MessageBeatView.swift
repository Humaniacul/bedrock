import SwiftUI

/// The data-driven narrative/quote screen — eyebrow, title, body, a serif "wow"
/// quote, an optional signature motif, and the advance button. Staggered rise-in.
struct MessageBeatView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let content: MessageContent
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer(minLength: Theme.Spacing.lg)

            if content.motif != .none {
                MotifView(motif: content.motif)
                    .frame(height: 96)
                    .riseIn(0, reduceMotion: reduceMotion)
            }
            if let eyebrow = content.eyebrow {
                Text(eyebrow)
                    .font(Theme.Typography.monoCaption)
                    .tracking(3)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .riseIn(0.08, reduceMotion: reduceMotion)
            }
            if let title = content.title {
                Text(title)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .riseIn(0.16, reduceMotion: reduceMotion)
            }
            if let quote = content.quote {
                Text(quote)
                    .font(.system(.title, design: .serif, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.vertical, Theme.Spacing.xs)
                    .riseIn(0.24, reduceMotion: reduceMotion)
            }
            if let body = content.body {
                Text(body)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .riseIn(0.32, reduceMotion: reduceMotion)
            }

            Spacer()
            Button(content.cta) { onNext() }
                .buttonStyle(.bedrockPrimary)
                .riseIn(0.45, reduceMotion: reduceMotion)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

/// Small signature visual per motif. Reduce-Motion → settles instantly.
private struct MotifView: View {
    let motif: Motif
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        Group {
            switch motif {
            case .ember: ember
            case .sandToRock, .strata: strata
            case .carve: carve
            case .none: EmptyView()
            }
        }
        .onAppear { if !reduceMotion { animate = true } }
        .accessibilityHidden(true)
    }

    private var ember: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.accent.opacity(0.6), Theme.accent.opacity(0.02)],
                                     center: .center, startRadius: 2, endRadius: 60))
                .frame(width: 120, height: 120)
                .scaleEffect(animate ? 1.0 : 0.85)
                .opacity(animate ? 1 : 0.7)
                .animation(reduceMotion ? nil : .easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: animate)
            Circle().fill(Theme.accent).frame(width: 10, height: 10)
        }
    }

    // Three strata settling into place — sand becoming rock.
    private var strata: some View {
        VStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(BedrockColor.slate.opacity(0.5 + Double(i) * 0.18))
                    .frame(width: CGFloat(120 - i * 16), height: 16)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.accent.opacity(i == 2 ? 0.5 : 0.15)))
                    .offset(y: animate ? 0 : -CGFloat(30 - i * 8))
                    .opacity(animate ? 1 : 0)
                    .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.12), value: animate)
            }
        }
    }

    // A carved groove drawn across stone.
    private var carve: some View {
        ZStack {
            Capsule().fill(BedrockColor.basalt).frame(width: 120, height: 14)
            Capsule()
                .fill(Theme.accent)
                .frame(width: animate ? 104 : 0, height: 4)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.9), value: animate)
        }
    }
}
