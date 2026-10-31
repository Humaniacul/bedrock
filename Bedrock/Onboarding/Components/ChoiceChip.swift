import SwiftUI

/// One answer chip (S5, S6, S7): min 52pt, radius 14, 16pt label left, a 20pt
/// tick circle right. Chosen: ember border, `emberWash` fill, the tick filled
/// ember with a dark check. Unchosen: `lineStrong` border, `bgSurface`, an empty
/// tick with a `lineMuted` edge.
struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    /// “No pattern yet”, “Not sure”: picking it clears the others.
    var isExclusive = false
    /// Single choice (S7): read as a radio, “Steady, 1 of 7.”
    var position: (index: Int, count: Int)? = nil
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bump: CGFloat = 1

    var body: some View {
        Button(action: tap) {
            HStack(spacing: Space.s2) {
                Text(title)
                    .ptype(.callout)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Circle()
                    .fill(isSelected ? BedrockColor.ember : .clear)
                    .overlay(Circle().strokeBorder(isSelected ? BedrockColor.ember : BedrockColor.lineMuted, lineWidth: 1))
                    .overlay {
                        ProtoIcon.check
                            .stroke(BedrockColor.bgBase, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 10, height: 10)
                    }
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Space.s4)
            .frame(maxWidth: .infinity, minHeight: BedrockSize.chipMinHeight, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(isSelected ? BedrockColor.emberWash : BedrockColor.bgSurface))
            .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(isSelected ? BedrockColor.ember : BedrockColor.lineStrong, lineWidth: 1))
            .animation(BedrockMotion.chipColour, value: isSelected)
            .contentShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .scaleEffect(bump)
        }
        .buttonStyle(.plain)
        .modifier(ChipAccessibility(title: title, isSelected: isSelected, isExclusive: isExclusive, position: position))
    }

    private func tap() {
        BedrockHaptics.select()
        action()
        guard !reduceMotion else { return }
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) { bump = BedrockMotion.chipBumpScale }
        withAnimation(BedrockMotion.chipBump) { bump = 1 }
    }
}

/// Toggle chips (S5, S6) or radio chips (S7), per SPEC.md's VoiceOver notes.
private struct ChipAccessibility: ViewModifier {
    let title: String
    let isSelected: Bool
    let isExclusive: Bool
    let position: (index: Int, count: Int)?

    func body(content: Content) -> some View {
        if let position {
            content
                .accessibilityLabel(OnbCopy.format("onb.common.a11y_option", title, position.index, position.count))
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        } else {
            content
                .accessibilityAddTraits(isSelected ? [.isToggle, .isSelected] : .isToggle)
                .accessibilityHint(isExclusive ? OnbCopy.string("onb.common.a11y_exclusive") : "")
        }
    }
}

/// Chips in a two-column grid with 10pt gaps (one column at accessibility text
/// sizes), Strata in on arrival. Exclusive options clear the rest.
struct ChoiceChipGrid: View {
    let options: [String]
    @Binding var selection: Set<String>
    var exclusive: Set<String> = []
    /// One choice at most (S7).
    var single = false
    /// For radio labels when the grid is part of a longer list (S7's own word).
    var totalCount: Int? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: Int { dynamicTypeSize.isAccessibilitySize ? 1 : 2 }

    var body: some View {
        Grid(horizontalSpacing: BedrockSize.chipGridGap, verticalSpacing: BedrockSize.chipGridGap) {
            ForEach(rows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { index in
                        let option = options[index]
                        ChoiceChip(title: option,
                                   isSelected: selection.contains(option),
                                   isExclusive: exclusive.contains(option),
                                   position: single ? (index + 1, totalCount ?? options.count) : nil) {
                            toggle(option)
                        }
                        .bedrockAppear(.strata(index: index))
                    }
                    if row.count < columns {
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var rows: [[Int]] {
        stride(from: 0, to: options.count, by: columns).map { start in
            Array(start..<min(start + columns, options.count))
        }
    }

    private func toggle(_ option: String) {
        if single {
            selection = [option]
        } else if exclusive.contains(option) {
            selection = selection.contains(option) ? [] : [option]
        } else {
            selection.subtract(exclusive)
            if selection.contains(option) { selection.remove(option) } else { selection.insert(option) }
        }
    }
}
