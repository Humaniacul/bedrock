import SwiftUI

/// S8's hold control, as the prototype draws it: an 84pt glass circle with a
/// 3pt ring (r 36) that fills ember over 1.4s, a small standing-stone glyph in
/// the middle, the label under it (15pt Limestone). Releasing early drains the
/// ring. Two short taps show “Keep holding” (Glow); a third adds a “Set it”
/// pill. With VoiceOver, double-tap sets it directly.
struct HoldToSetControl: View {
    let label: String
    let tapHint: String
    let fallbackTitle: String
    /// How it was set, and how many attempts it took (for `onb_stone_set`).
    let onSet: (StoneMethod, Int) -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var progress: CGFloat = 0
    @State private var pressStarted: Date?
    @State private var shortTaps = 0
    @State private var attempts = 0
    @State private var done = false

    var body: some View {
        VStack(spacing: 10) {
            ring
            Text(label)
                .ptype(.subheadPlain)
                .foregroundStyle(BedrockColor.inkSecondary)
                .accessibilityHidden(true)
            if shortTaps >= 2 {
                Text(tapHint)
                    .ptype(.notePlain)
                    .foregroundStyle(BedrockColor.emberGlow)
                    .transition(.opacity)
            }
            if shortTaps >= 3 {
                PillButton(title: fallbackTitle, height: 44, padding: 18) { set(.tapFallback) }
                    .transition(.opacity)
            }
        }
        .animation(BedrockMotion.reducedFade, value: shortTaps)
        .onAppear { HoldRamp.shared.prepare() }
        .onDisappear { HoldRamp.shared.stopEngine() }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(BedrockColor.lineSubtle, lineWidth: 3)
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(BedrockColor.ember, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 72, height: 72)
            UnitPolygon.holdGlyph
                .fill(LinearGradient(colors: [BedrockColor.glyphHi, BedrockColor.glyphLo],
                                     startPoint: UnitPoint(x: 0.33, y: 0), endPoint: UnitPoint(x: 0.67, y: 1)))
                .frame(width: 22, height: 24)
        }
        .frame(width: BedrockSize.holdControl, height: BedrockSize.holdControl)
        .controlGlass(Circle(), soft: true)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: BedrockTiming.holdToSet, maximumDistance: BedrockSize.holdSlop) {
            set(voiceOver ? .voiceover : .hold)
        } onPressingChanged: { pressing in
            pressing ? beginHold() : endHold()
        }
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(OnbCopy.string("onb.s8.a11y_hold"))
        .accessibilityAction { set(.voiceover) }
    }

    private func beginHold() {
        guard !done else { return }
        pressStarted = .now
        attempts += 1
        HoldRamp.shared.begin()
        // The ring always fills, even with Reduce Motion: it's feedback, not decoration.
        withAnimation(.linear(duration: BedrockTiming.holdToSet * (1 - progress))) { progress = 1 }
    }

    private func endHold() {
        guard !done else { return }
        if let started = pressStarted, Date.now.timeIntervalSince(started) < BedrockTiming.shortTap {
            shortTaps += 1
        }
        pressStarted = nil
        HoldRamp.shared.cancel()
        withAnimation(BedrockMotion.drain) { progress = 0 }
    }

    private func set(_ method: StoneMethod) {
        guard !done else { return }
        done = true
        progress = 1
        HoldRamp.shared.complete()
        BedrockHaptics.lock()
        onSet(method, max(attempts, 1))
    }
}
