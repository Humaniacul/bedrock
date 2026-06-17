import SwiftUI

/// A single Bedrock-styled selectable chip (capsule, ember when active).
struct BedrockChip: View {
    let text: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Theme.Typography.callout)
                .foregroundStyle(isOn ? Theme.onAccent : Theme.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Capsule().fill(isOn ? Theme.accent : BedrockColor.basalt))
                .overlay(Capsule().strokeBorder(Theme.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// Single-select wrapping chips. Tapping the active chip clears it.
struct ChoiceChips: View {
    let options: [String]
    @Binding var selection: String?
    var onPick: ((String) -> Void)? = nil

    var body: some View {
        FlowLayout(spacing: Theme.Spacing.sm) {
            ForEach(options, id: \.self) { option in
                BedrockChip(text: option, isOn: selection == option) {
                    BedrockHaptics.selection()
                    selection = (selection == option) ? nil : option
                    onPick?(option)
                }
            }
        }
    }
}

/// Multi-select wrapping chips backed by a `Set`.
struct MultiChips: View {
    let options: [String]
    @Binding var selected: Set<String>

    var body: some View {
        FlowLayout(spacing: Theme.Spacing.sm) {
            ForEach(options, id: \.self) { option in
                BedrockChip(text: option, isOn: selected.contains(option)) {
                    BedrockHaptics.selection()
                    if selected.contains(option) { selected.remove(option) } else { selected.insert(option) }
                }
            }
        }
    }
}

/// Minimal wrapping layout for chips (no third-party deps).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
