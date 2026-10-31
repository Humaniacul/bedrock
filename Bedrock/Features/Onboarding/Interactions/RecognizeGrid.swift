import SwiftUI

/// Recognize (spec v2 §Interaction primitives): tap the specifics that are
/// true. Each tapped tile flares ember, then dims into shadow as a vignette
/// gathers across the screen — self-admission, performed with the thumb.
/// Never gamey: no counts, no ticks, just weight.
struct RecognizeGrid: View {
    let options: [String]
    @Binding var selected: Set<String>

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flaring: String?

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                tile(option)
                    .strata(index, base: 0.15, reduceMotion: reduceMotion)
            }
        }
    }

    private func tile(_ option: String) -> some View {
        let isOn = selected.contains(option)
        let isFlaring = flaring == option
        return Button {
            tap(option)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Text(option)
                    .font(Theme.Typography.callout.weight(.medium))
                    .foregroundStyle(isFlaring ? Theme.onAccent : (isOn ? Theme.textSecondary : Theme.textPrimary))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if isOn && !isFlaring {
                    // The admitted mark — quiet, not a reward.
                    Circle()
                        .fill(Theme.accent.opacity(0.55))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(isFlaring
                          ? AnyShapeStyle(Theme.accent)
                          : AnyShapeStyle(BedrockColor.slate.opacity(isOn ? 0.35 : 0.6))))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .strokeBorder(isOn ? Theme.accent.opacity(0.35) : Theme.hairline))
        }
        .buttonStyle(.plain)
        .animation(Theme.Motion.reduced(.easeInOut(duration: 0.5), when: reduceMotion), value: isOn)
        .animation(Theme.Motion.reduced(.easeInOut(duration: 0.25), when: reduceMotion), value: isFlaring)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isOn ? "Tap to unmark" : "Tap if this is true for you")
    }

    private func tap(_ option: String) {
        if selected.contains(option) {
            selected.remove(option)
            BedrockHaptics.selection()
            return
        }
        selected.insert(option)
        BedrockHaptics.set()
        guard !reduceMotion else { return }
        // Flare ember, then dim into shadow.
        flaring = option
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            if flaring == option { flaring = nil }
        }
    }
}

/// The gathering shadow behind a Recognize screen — deepens per admission.
/// Overlay this on the beat, under the content.
struct GatheringShadow: View {
    let count: Int

    var body: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(min(0.55, Double(count) * 0.09))],
            center: .center, startRadius: 110, endRadius: 460)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .animation(.easeInOut(duration: 0.8), value: count)
    }
}
