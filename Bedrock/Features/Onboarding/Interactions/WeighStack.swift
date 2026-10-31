import SwiftUI

/// Weigh (spec v2 S11): "Drag the one that hurts most to the top." Ranking
/// forces deeper processing than a multi-select ever could. Only the top slot
/// matters — the item dropped there becomes `topCost`, quoted back at S12 and
/// on the paywall.
struct WeighStack: View {
    let items: [String]
    @Binding var topCost: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draggingItem: String?
    @State private var dragOffset: CGSize = .zero

    private let rowHeight: CGFloat = 54

    /// Display order: the chosen top first, then the rest in original order.
    private var ordered: [String] {
        guard let top = topCost, items.contains(top) else { return items }
        return [top] + items.filter { $0 != top }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(ordered.enumerated()), id: \.element) { index, item in
                row(item, index: index)
            }
        }
        .animation(Theme.Motion.reduced(.spring(response: 0.4, dampingFraction: 0.78), when: reduceMotion), value: ordered)
    }

    private func row(_ item: String, index: Int) -> some View {
        let isTop = topCost == item
        let isDragging = draggingItem == item
        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
            Text(item)
                .font(Theme.Typography.callout.weight(isTop ? .semibold : .medium))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
            if isTop {
                Text("HURTS MOST")
                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                    .tracking(1)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: rowHeight)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md)
            .fill(BedrockColor.slate.opacity(isTop ? 0.85 : 0.5)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
            .strokeBorder(isTop ? Theme.accent.opacity(0.7) : Theme.hairline, lineWidth: isTop ? 1.5 : 1))
        .offset(isDragging ? dragOffset : .zero)
        .zIndex(isDragging ? 2 : 0)
        .shadow(color: isDragging ? .black.opacity(0.45) : .clear, radius: 10, y: 5)
        .gesture(
            DragGesture()
                .onChanged { drag in
                    draggingItem = item
                    dragOffset = CGSize(width: 0, height: drag.translation.height)
                }
                .onEnded { drag in
                    defer { draggingItem = nil; dragOffset = .zero }
                    // Dropped above the stack's first row → this one hurts most.
                    let rowsMoved = Int((-drag.translation.height / (rowHeight + Theme.Spacing.sm)).rounded())
                    if index - rowsMoved <= 0, item != topCost {
                        topCost = item
                        BedrockHaptics.stoneSet() // it lands with weight
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isTop ? "\(item). Currently marked as what hurts most." : item)
        .accessibilityHint("Double-tap to mark as the one that hurts most")
        .accessibilityAction {
            topCost = item
            BedrockHaptics.stoneSet()
        }
    }
}
