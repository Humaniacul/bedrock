import SwiftUI

/// S18 — willpower, demonstrated as futile. The user presses and holds a door
/// shut; it strains and slips no matter the effort while a meter drains
/// (~4s). Then, with no effort from them, a wall Settles and Locks over the
/// doorway. They *feel* the difference between holding and being held.
struct HoldTheDoor: View {
    /// Fires when the wall has locked (parent reveals payoff + Continue).
    var onCompleted: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    private enum Phase: Equatable { case idle, holding, drained, wallSet }

    @State private var phase: Phase = .idle
    @State private var willpower: CGFloat = 1      // drains while holding
    @State private var doorGap: CGFloat = 0        // the door slipping open
    @State private var jitter: CGFloat = 0
    @State private var drainTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Group {
                switch phase {
                case .idle:    Text("Try to hold the door shut.")
                case .holding: Text("Keep holding…")
                case .drained: Text("That's willpower. It runs out. You already know this.")
                case .wallSet: Text("This doesn't. You don't hold it. It just holds.")
                }
            }
            .font(Theme.Typography.callout)
            .foregroundStyle(phase == .wallSet ? Theme.textPrimary : Theme.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44)
            .animation(Theme.Motion.reduced(.easeInOut(duration: 0.35), when: reduceMotion), value: phase)

            doorway

            if phase == .idle || phase == .holding {
                willpowerMeter
                if voiceOver || reduceMotion {
                    Button("Try to hold the door") { runStatic() }
                        .buttonStyle(.bedrockPrimary)
                }
            }
        }
        .onDisappear { drainTask?.cancel() }
    }

    // MARK: - Pieces

    private var doorway: some View {
        ZStack {
            // The frame.
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(Theme.hairline, lineWidth: 2)
                .frame(width: 130, height: 170)
            if phase == .wallSet {
                // The wall that just… holds.
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(LinearGradient(colors: [BedrockColor.slate, BedrockColor.basalt],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 126, height: 166)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1.5))
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            } else {
                // The door — straining against them.
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(BedrockColor.ash.opacity(0.35))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .strokeBorder(BedrockColor.ash.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [7, 4])))
                    .frame(width: 110, height: 150)
                    .rotation3DEffect(.degrees(Double(doorGap) * 32), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                    .offset(x: jitter)
            }
        }
        .frame(height: 190)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 30, maximumDistance: 90) {
            // Never completes — the drain ends it first. Intentional.
        } onPressingChanged: { pressing in
            guard !voiceOver, !reduceMotion else { return }
            if pressing { beginHold() } else { pauseHold() }
        }
        .accessibilityElement()
        .accessibilityLabel(phase == .wallSet ? "A stone wall now fills the doorway" : "A door you are trying to hold shut")
        .accessibilityHint(phase == .idle ? "Use the button below to try holding it" : "")
    }

    private var willpowerMeter: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline)
                    Capsule()
                        .fill(willpower > 0.35 ? Theme.accent : BedrockColor.bronze)
                        .frame(width: max(4, geo.size.width * willpower))
                }
            }
            .frame(width: 180, height: 5)
            Text("WILLPOWER")
                .font(Theme.Typography.monoCaption)
                .tracking(2.5)
                .foregroundStyle(Theme.textSecondary.opacity(0.8))
        }
        .accessibilityElement()
        .accessibilityLabel("Willpower meter")
        .accessibilityValue("\(Int(willpower * 100)) percent")
    }

    // MARK: - The fight they can't win

    private func beginHold() {
        guard phase == .idle || phase == .holding else { return }
        phase = .holding
        drainTask?.cancel()
        drainTask = Task { @MainActor in
            while !Task.isCancelled && willpower > 0 {
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled else { return }
                willpower = max(0, willpower - 0.032)          // ~4s total
                doorGap = (1 - willpower) * 0.8                // slips regardless
                jitter = CGFloat.random(in: -1.6...1.6)        // fighting their thumb
                BedrockHaptics.selection()
            }
            guard !Task.isCancelled else { return }
            drained()
        }
    }

    private func pauseHold() {
        guard phase == .holding else { return }
        drainTask?.cancel()
        jitter = 0
        // Willpower doesn't come back. That's the point.
    }

    private func drained() {
        phase = .drained
        jitter = 0
        withAnimation(.easeIn(duration: 0.7)) { doorGap = 1 }
        BedrockHaptics.calm()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            setWall()
        }
    }

    /// Reduce-Motion / VoiceOver: one tap runs the condensed honest sequence.
    private func runStatic() {
        phase = .drained
        willpower = 0
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            setWall()
        }
    }

    private func setWall() {
        withAnimation(Theme.Motion.reduced(.spring(response: 0.5, dampingFraction: 0.75), when: reduceMotion)) {
            phase = .wallSet
        }
        BedrockHaptics.stoneSet() // the Lock — it just holds
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 400 : 1200))
            guard !Task.isCancelled else { return }
            onCompleted()
        }
    }
}
