import SwiftUI

/// The signature text animation — words *carved into stone*, glyph by glyph, at
/// a deliberate hand-carved cadence with a fine chisel tick + dust burst per
/// glyph and the active glyph glowing ember (the chisel tip). Tap to skip.
/// Instant and silent under Reduce Motion. The full string is exposed to
/// VoiceOver immediately (never the partial reveal).
struct ChiselText: View {
    let text: String
    var font: Font = .system(.largeTitle, design: .serif, weight: .semibold)
    var color: Color = Theme.textPrimary
    var cadence: Double = 0.045
    var alignment: TextAlignment = .center
    var onFinished: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = 0
    @State private var dust = 0
    @State private var finished = false
    @State private var task: Task<Void, Never>?

    private var chars: [Character] { Array(text) }

    var body: some View {
        Text(carved)
            .font(font)
            .multilineTextAlignment(alignment)
            .lineSpacing(4)
            .overlay {
                if !reduceMotion {
                    StoneParticles(trigger: dust, color: BedrockColor.ash, burst: 3)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { skip() }
            .accessibilityElement()
            .accessibilityLabel(text)
            .onAppear { start() }
            .onDisappear { task?.cancel() }
    }

    /// Whole string laid out once (stable, no reflow); unrevealed glyphs are
    /// clear, the freshest glyph is ember, the rest are `color`.
    private var carved: AttributedString {
        var result = AttributedString()
        for (i, ch) in chars.enumerated() {
            var run = AttributedString(String(ch))
            if i < revealed - 1 {
                run.foregroundColor = color
            } else if i == revealed - 1 {
                run.foregroundColor = Theme.accent
            } else {
                run.foregroundColor = .clear
            }
            result += run
        }
        return result
    }

    private func start() {
        guard !finished else { return }
        if reduceMotion {
            revealed = chars.count
            finish()
            return
        }
        task?.cancel()
        task = Task { @MainActor in
            for i in chars.indices {
                let pause = delay(beforeIndex: i)
                try? await Task.sleep(for: .seconds(pause))
                if Task.isCancelled { return }
                revealed = i + 1
                if !chars[i].isWhitespace {
                    BedrockHaptics.chiselTick()
                    dust += 1
                }
            }
            finish()
        }
    }

    /// Cadence with a hand-carved feel: a pause lingers *after* sentence-ending
    /// and clause punctuation, plus a little jitter.
    private func delay(beforeIndex i: Int) -> Double {
        var d = cadence + Double.random(in: -0.015...0.015)
        if i > 0 {
            let prev = chars[i - 1]
            if ".!?".contains(prev) { d += 0.34 }
            else if ",;:—".contains(prev) { d += 0.14 }
        }
        return max(0.01, d)
    }

    private func skip() {
        guard !finished, revealed < chars.count else { return }
        task?.cancel()
        revealed = chars.count
        BedrockHaptics.set()
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinished?()
    }
}
