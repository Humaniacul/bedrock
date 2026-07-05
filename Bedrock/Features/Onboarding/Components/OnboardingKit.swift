import SwiftUI

// The onboarding design kit (spec v1.0 §Design system): named motion
// primitives + the small shared controls every beat composes. Motion names
// match the spec — Carve (ChiselText), Settle, Strata, Ember, Breath, Lock —
// so beats read like the storyboard.

// MARK: - Settle (elements arrive with mass; nothing snaps)

struct SettleIn: ViewModifier {
    let delay: Double
    let reduceMotion: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            .scaleEffect(shown ? 1 : 0.98)
            .onAppear {
                guard !shown else { return }
                if reduceMotion { shown = true } else {
                    // ~520ms spring, damping .82 — a 2% overshoot, never a snap.
                    withAnimation(.spring(response: 0.52, dampingFraction: 0.82).delay(delay)) {
                        shown = true
                    }
                }
            }
    }
}

extension View {
    /// Arrive with mass (spec: Settle). Instant under Reduce Motion.
    func settleIn(_ delay: Double = 0, reduceMotion: Bool) -> some View {
        modifier(SettleIn(delay: delay, reduceMotion: reduceMotion))
    }

    /// Stacked planes sliding up in sequence (spec: Strata) — a Settle at the
    /// block's index. 90ms stagger.
    func strata(_ index: Int, base: Double = 0.1, reduceMotion: Bool) -> some View {
        settleIn(base + Double(index) * 0.09, reduceMotion: reduceMotion)
    }

    /// Held moments breathe — 1.0 → 1.02 → 1.0 over ~4s (spec: Breath).
    func breath(_ active: Bool = true, reduceMotion: Bool) -> some View {
        modifier(BreathModifier(active: active && !reduceMotion))
    }
}

private struct BreathModifier: ViewModifier {
    let active: Bool
    @State private var inhale = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(active && inhale ? 1.02 : 1)
            .animation(active ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : nil, value: inhale)
            .onAppear { if active { inhale = true } }
    }
}

// MARK: - Ember (one key phrase warms ink → ember; rationed, no haptic)

struct EmberPhrase: View {
    let text: String
    var font: Font = .system(.title2, design: .serif, weight: .semibold)
    var delay: Double = 0.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var warmed = false

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(warmed ? Theme.accent : Theme.textPrimary)
            .multilineTextAlignment(.center)
            .onAppear {
                if reduceMotion { warmed = true } else {
                    withAnimation(.easeInOut(duration: 0.9).delay(delay)) { warmed = true }
                }
            }
    }
}

// MARK: - Carve sequence (multi-line Carve, one line at a time)

/// Carves a line, optionally warms it to ember when it lands, then hands off
/// to the next. `dimsPrevious` fades finished lines to 30% (S3 Recognition);
/// `interlinePause` lets emotional beats breathe between lines.
struct CarveSequence: View {
    struct Line {
        let text: String
        var font: Font = .system(.title2, design: .serif, weight: .semibold)
        var ember = false
    }

    let lines: [Line]
    var spacing: CGFloat = Theme.Spacing.lg
    var dimsPrevious = false
    var interlinePause: Double = 0.35
    var onAllFinished: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealedCount = 1
    @State private var finishedCount = 0

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if index < revealedCount {
                    CarveThenEmber(text: line.text, font: line.font, embers: line.ember) {
                        lineFinished(index)
                    }
                    .opacity(dimsPrevious && index < finishedCount && index < lines.count - 1 ? 0.3 : 1)
                    .animation(Theme.Motion.reduced(.easeInOut(duration: 0.8), when: reduceMotion),
                               value: finishedCount)
                }
            }
        }
    }

    private func lineFinished(_ index: Int) {
        guard index == revealedCount - 1 else { return }
        let pause = reduceMotion ? 0 : interlinePause
        Task { @MainActor in
            if pause > 0 { try? await Task.sleep(for: .seconds(pause)) }
            finishedCount = max(finishedCount, index + 1)
            if revealedCount < lines.count {
                revealedCount += 1
            } else {
                onAllFinished?()
            }
        }
    }
}

/// A carved line that can warm ink → ember once it lands (spec: Ember, 900ms).
struct CarveThenEmber: View {
    let text: String
    var font: Font = .system(.title2, design: .serif, weight: .semibold)
    var embers = false
    var onFinished: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var warmed = false

    var body: some View {
        ZStack {
            ChiselText(text: text, font: font) {
                if embers {
                    withAnimation(.easeInOut(duration: reduceMotion ? 0 : 0.9)) { warmed = true }
                }
                onFinished?()
            }
            if embers {
                // Identical metrics laid over the carved base — only color moves.
                Text(text)
                    .font(font)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundStyle(Theme.accent)
                    .opacity(warmed ? 1 : 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Tap-to-continue affordance (emotional beats have no chrome)

struct TapToContinue: View {
    let visible: Bool
    var body: some View {
        Text("Tap to continue")
            .font(Theme.Typography.monoCaption)
            .tracking(2)
            .foregroundStyle(Theme.textSecondary.opacity(0.7))
            .opacity(visible ? 1 : 0)
            .animation(.easeIn(duration: 0.6), value: visible)
            .accessibilityHidden(true) // the whole screen is the button
    }
}

// MARK: - Eyebrow (mono, wide letter-spacing: THE THRESHOLD, QUESTION 01)

struct OnboardingEyebrow: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.Typography.monoCaption)
            .tracking(3.5)
            .foregroundStyle(Theme.textSecondary)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Primary button (title + optional quiet subtitle)

struct OnboardingPrimaryButton: View {
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(title) { action() }
                .buttonStyle(.bedrockPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Option card (stone tile; ember edge + Lock on select)

struct OnboardingOptionCard: View {
    let label: String
    var icon: String? = nil
    var detail: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            BedrockHaptics.set() // Lock — stone into place
            action()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                if let icon {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                        .frame(width: 26)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(Theme.Typography.callout.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail {
                        Text(detail)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.hairline)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(BedrockColor.slate.opacity(isSelected ? 0.9 : 0.55)))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .strokeBorder(isSelected ? Theme.accent.opacity(0.8) : Theme.hairline,
                                  lineWidth: isSelected ? 1.5 : 1))
            .shadow(color: isSelected ? BedrockColor.ember.opacity(0.18) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Progress bar (coordinator chrome; question block only)

struct OnboardingProgressBar: View {
    let fraction: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: max(8, geo.size.width * fraction))
            }
        }
        .frame(height: 3)
        .animation(Theme.Motion.reduced(.smooth(duration: 0.4), when: reduceMotion), value: fraction)
        .accessibilityElement()
        .accessibilityLabel("Question progress")
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}

// MARK: - Vulnerable-user safeguard (quiet, always-available)

struct StrugglingLink: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(URL(string: "https://findahelpline.com")!)
        } label: {
            Text("If you're really struggling, you're not alone — help is here.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.85))
                .underline()
                .multilineTextAlignment(.center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("If you're really struggling, you're not alone. Opens a directory of support helplines.")
    }
}
