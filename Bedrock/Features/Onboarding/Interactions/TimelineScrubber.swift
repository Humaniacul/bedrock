import SwiftUI

/// S17 — the honest road ahead, explored rather than sold. The user drags
/// along a stone path; each stage uncovers as the scrub passes it, and their
/// best-self word waits Embered at the end.
struct TimelineScrubber: View {
    struct Stage {
        let label: String
        let detail: String
    }

    let stages: [Stage]
    let emphasisIndex: Int
    let destinationWord: String
    /// Rises monotonically; parent enables Continue when ≥ ~0.9.
    @Binding var progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var lastMilestone = -1

    private var revealedCount: Int {
        // Stage i uncovers as the scrub crosses its marker.
        stages.indices.filter { progress >= threshold($0) }.count
    }

    private func threshold(_ index: Int) -> Double {
        Double(index) / Double(max(1, stages.count)) + 0.08
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if voiceOver || reduceMotion {
                // Static, fully readable equivalent.
                staticList
            } else {
                path
                stageCards
            }
        }
        .onChange(of: revealedCount) { _, new in
            if new > lastMilestone {
                lastMilestone = new
                BedrockHaptics.set() // each stage lands like a marker stone
            }
        }
    }

    // MARK: - The path

    private var path: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(BedrockColor.slate.opacity(0.6))
                    .frame(height: 10)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.accent, BedrockColor.emberGlow],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(10, width * progress), height: 10)
                // Marker stones.
                ForEach(stages.indices, id: \.self) { i in
                    Circle()
                        .fill(progress >= threshold(i) ? Theme.accent : BedrockColor.basalt)
                        .overlay(Circle().strokeBorder(progress >= threshold(i) ? BedrockColor.emberGlow : Theme.hairline))
                        .frame(width: 16, height: 16)
                        .position(x: width * threshold(i), y: geo.size.height / 2)
                }
                // The destination — their word.
                Text(destinationWord)
                    .font(.system(.callout, design: .serif, weight: .semibold))
                    .foregroundStyle(progress > 0.9 ? Theme.accent : Theme.textSecondary.opacity(0.55))
                    .position(x: width - 24, y: geo.size.height / 2 - 26)
                    .animation(.easeInOut(duration: 0.9), value: progress > 0.9)
            }
            .contentShape(Rectangle().inset(by: -20))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        // Only forward — the road ahead doesn't rewind.
                        progress = max(progress, min(1, drag.location.x / width))
                    }
            )
        }
        .frame(height: 56)
        .accessibilityHidden(true) // static list is the accessible form
    }

    private var stageCards: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(stages.indices, id: \.self) { i in
                if progress >= threshold(i) {
                    stageCard(i)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: revealedCount)
    }

    private var staticList: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(stages.indices, id: \.self) { i in
                stageCard(i)
            }
            HStack(spacing: 6) {
                Text("Destination:")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text(destinationWord)
                    .font(.system(.body, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .onAppear { progress = 1 } // nothing gated behind the gesture
    }

    private func stageCard(_ i: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.md) {
            Text(stages[i].label)
                .font(Theme.Typography.monoCaption.weight(.bold))
                .tracking(1)
                .foregroundStyle(i == emphasisIndex ? Theme.accent : Theme.textSecondary)
                .frame(width: 88, alignment: .leading)
            Text(stages[i].detail)
                .font(i == emphasisIndex ? Theme.Typography.callout.weight(.semibold) : Theme.Typography.callout)
                .foregroundStyle(i == emphasisIndex ? Theme.textPrimary : Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md)
            .fill(BedrockColor.slate.opacity(i == emphasisIndex ? 0.7 : 0.35)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
            .strokeBorder(i == emphasisIndex ? Theme.accent.opacity(0.5) : Theme.hairline))
        .accessibilityElement(children: .combine)
    }
}
