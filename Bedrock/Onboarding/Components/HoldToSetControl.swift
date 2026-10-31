import SwiftUI

/// S8's hold control (COMPONENTS.md): an 84pt glass circle with a progress ring
/// and a small stone glyph. Hold 1.4s to set (HoldRamp haptics); releasing early
/// drains the ring over 0.3s. Two short taps show “Keep holding”; a third
/// shows a plain “Set it” button. With VoiceOver, double-tap sets directly.
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
        VStack(spacing: Space.s3) {
            if shortTaps >= 3 {
                PrimaryButton(title: fallbackTitle) { set(.tapFallback) }
                    .bedrockAppear(.settle)
            } else {
                ring
                Text(shortTaps >= 2 ? tapHint : label)
                    .font(BedrockFont.subhead)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .animation(BedrockMotion.reducedFade, value: shortTaps)
                    .accessibilityHidden(true)
            }
        }
        .onAppear { HoldRamp.shared.prepare() }
        .onDisappear { HoldRamp.shared.stopEngine() }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(BedrockColor.lineStrong, lineWidth: BedrockSize.holdRingWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(BedrockColor.ember, style: StrokeStyle(lineWidth: BedrockSize.holdRingWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            StoneMark()
                .fill(progress > 0 ? BedrockColor.emberGlow : BedrockColor.stoneLight)
                .frame(width: BedrockSize.holdGlyph.width, height: BedrockSize.holdGlyph.height)
        }
        .frame(width: BedrockSize.holdControl, height: BedrockSize.holdControl)
        .bedrockGlass(Circle())
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
        withAnimation(.linear(duration: BedrockTiming.holdToSet)) { progress = 1 }
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
