import SwiftUI

/// The real-time wall (S21/S24): one stone block Locks into place per choice
/// the user makes. Blocks arrive with mass (Settle) and a single deep haptic.
struct FoundationWall: View {
    /// How many blocks are set (each guardrail = one block).
    let blocks: Int
    var capstone: String? = nil   // S24: the best-self word crowning the wall

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let layout: [Int] = [2, 3] // bottom row 3, top row 2 (drawn top-down)

    var body: some View {
        VStack(spacing: 5) {
            if let capstone {
                CornerstoneView(line: capstone, compact: true)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            ForEach(Array(layout.enumerated()), id: \.offset) { rowIndex, count in
                HStack(spacing: 5) {
                    ForEach(0..<count, id: \.self) { col in
                        block(index: blockIndex(row: rowIndex, col: col))
                    }
                }
            }
        }
        .animation(Theme.Motion.reduced(.spring(response: 0.45, dampingFraction: 0.72), when: reduceMotion), value: blocks)
        .animation(Theme.Motion.reduced(.spring(response: 0.45, dampingFraction: 0.72), when: reduceMotion), value: capstone)
        .accessibilityElement()
        .accessibilityLabel(wallLabel)
    }

    private var wallLabel: String {
        var label = "Your foundation wall: \(blocks) of 5 stones set."
        if let capstone { label += " Cornerstone reads \(capstone)." }
        return label
    }

    /// Fill bottom row first — walls are built from the ground up.
    private func blockIndex(row: Int, col: Int) -> Int {
        row == 1 ? col : layout[1] + col
    }

    @ViewBuilder private func block(index: Int) -> some View {
        let set = index < blocks
        RoundedRectangle(cornerRadius: 6)
            .fill(set
                  ? AnyShapeStyle(LinearGradient(colors: [BedrockColor.slate, BedrockColor.basalt],
                                                 startPoint: .top, endPoint: .bottom))
                  : AnyShapeStyle(BedrockColor.basalt.opacity(0.35)))
            .frame(width: 74, height: 34)
            .overlay(RoundedRectangle(cornerRadius: 6)
                .strokeBorder(set ? Theme.accent.opacity(0.45) : Theme.hairline, lineWidth: 1))
            .shadow(color: set ? BedrockColor.ember.opacity(0.15) : .clear, radius: 6, y: 3)
            .scaleEffect(set ? 1 : 0.96)
            .opacity(set ? 1 : 0.6)
    }
}

/// A stone block bearing carved words — the contract, the why, the best-self
/// word. The same asset the app home inherits, so Day One feels continuous.
struct CornerstoneView: View {
    let line: String
    var sub: String? = nil
    var compact = false

    var body: some View {
        VStack(spacing: 4) {
            Text(line)
                .font(compact
                      ? .system(.callout, design: .serif, weight: .semibold)
                      : .system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.6), radius: 0.5, y: 1) // carved, not printed
                .fixedSize(horizontal: false, vertical: true)
            if let sub, !sub.isEmpty {
                Text(sub)
                    .font(Theme.Typography.monoCaption)
                    .tracking(2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, compact ? Theme.Spacing.md : Theme.Spacing.lg)
        .padding(.vertical, compact ? Theme.Spacing.sm : Theme.Spacing.md)
        .frame(maxWidth: compact ? nil : .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(LinearGradient(colors: [BedrockColor.slate, BedrockColor.basalt],
                                     startPoint: .top, endPoint: .bottom)))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .strokeBorder(Theme.accent.opacity(0.4), lineWidth: 1))
        .shadow(color: BedrockColor.ember.opacity(0.12), radius: 10, y: 5)
    }
}
