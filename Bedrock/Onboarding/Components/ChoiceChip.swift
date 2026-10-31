import SwiftUI

/// One selectable chip (S5, S6, S7). Min 52pt, radius 14. Unselected: `bgSurface`
/// with a `lineStrong` border. Selected: `emberWash`, an `ember` border and an
/// ember tick. VoiceOver: a toggle button with the selected trait.
struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    /// “No pattern yet”, “Not sure”: picking it clears the others. Enforced by
    /// `ChoiceChipGrid`; carried here so the chip can say so if a screen needs it.
    var isExclusive = false
    /// Single choice (S7): read as a radio, “Steady, 1 of 7.”, and the label warms to ember.
    var position: (index: Int, count: Int)? = nil
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bump: CGFloat = 1

    var body: some View {
        Button(action: tap) {
            HStack(spacing: Space.s2) {
                Text(title)
                    .font(BedrockFont.chip)
                    .foregroundStyle(position != nil && isSelected ? BedrockColor.emberGlow : BedrockColor.inkPrimary)
                    .animation(BedrockMotion.ember, value: isSelected)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "checkmark")
                    .font(BedrockFont.chip.weight(.semibold))
                    .foregroundStyle(BedrockColor.emberGlow)
                    .opacity(isSelected ? 1 : 0) // space kept, so nothing reflows
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Space.s4)
            .padding(.vertical, Space.s3)
            .frame(maxWidth: .infinity, minHeight: BedrockSize.chipMinHeight, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(isSelected ? BedrockColor.emberWash : BedrockColor.bgSurface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
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
        // S5: the chip scales 0.96 → 1 on select. Reduce Motion: colour only.
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

/// Chips in a two-column grid with 10pt gaps; one column at accessibility text
/// sizes. Chips Strata in on arrival. Exclusive options clear the rest, and
/// picking any other option clears them.
struct ChoiceChipGrid: View {
    let options: [String]
    @Binding var selection: Set<String>
    var exclusive: Set<String> = []
    /// One choice at most (S7).
    var single = false

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
                                   position: single ? (index + 1, options.count) : nil) {
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
        // Each row is as tall as its tallest chip, and no taller.
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Option indices, chunked into grid rows.
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

#if DEBUG
struct ChoiceChipPreview: View {
    private let options = OnbCopy.parts("onb.s5.chips")
    @State private var selection: Set<String>

    init() {
        let options = OnbCopy.parts("onb.s5.chips")
        _selection = State(initialValue: Set(options.prefix(2)))
    }

    var body: some View {
        PreviewPage {
            ScrollView {
                ChoiceChipGrid(options: options, selection: $selection,
                               exclusive: Set(options.suffix(1)))
                    .padding(.vertical, Space.s10)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

#Preview("ChoiceChip · 402×874", traits: .fixedLayout(width: 402, height: 874)) { ChoiceChipPreview().onboardingPreview(.standard) }
#Preview("ChoiceChip · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ChoiceChipPreview().onboardingPreview(.reduceMotion) }
#Preview("ChoiceChip · AX5", traits: .fixedLayout(width: 402, height: 874)) { ChoiceChipPreview().onboardingPreview(.ax5) }
#Preview("ChoiceChip · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ChoiceChipPreview().onboardingPreview(.ax5ReduceMotion) }
#endif
