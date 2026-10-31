import SwiftUI

// OptionCard (S11), PlanCard (S12), HomeCard and StatusChip (Home) —
// COMPONENTS.md › Choices, Sheets.

// MARK: - OptionCard

/// S11 key holder. Full width, radius 20, title in serif 26, body 15, a small
/// tag pill. Selected: ember border, `emberWash`, the title warms (Ember).
/// VoiceOver: a radio button, “Bedrock keeps it, 1 of 2”, with body and tag as hint.
struct OptionCard: View {
    let title: String
    let detail: String
    let tag: String
    let isSelected: Bool
    let position: (index: Int, count: Int)
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settle: CGFloat = 1

    var body: some View {
        Button {
            BedrockHaptics.select()
            action()
            guard !reduceMotion else { return }
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { settle = BedrockMotion.cardSelectScale }
            withAnimation(BedrockMotion.settle) { settle = 1 }
        } label: {
            VStack(alignment: .leading, spacing: Space.s2) {
                Text(title)
                    .font(BedrockFont.optionTitle)
                    .foregroundStyle(isSelected ? BedrockColor.emberGlow : BedrockColor.inkPrimary)
                    .animation(BedrockMotion.ember, value: isSelected)
                Text(detail)
                    .font(BedrockFont.subhead)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(tag)
                    .font(BedrockFont.footnote.weight(.medium))
                    .foregroundStyle(isSelected ? BedrockColor.inkPrimary : BedrockColor.inkSecondary)
                    .padding(.horizontal, Space.s2)
                    .padding(.vertical, Space.s1)
                    .background(Capsule().fill(isSelected ? BedrockColor.emberDeep : BedrockColor.bgRaised))
                    .padding(.top, Space.s1)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.s5)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(isSelected ? BedrockColor.emberWash : BedrockColor.bgSurface))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(isSelected ? BedrockColor.ember : BedrockColor.lineStrong, lineWidth: isSelected ? 1.5 : 1))
            .animation(BedrockMotion.chipColour, value: isSelected)
            .contentShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .scaleEffect(settle)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(OnbCopy.format("onb.common.a11y_option", title, position.index, position.count))
        .accessibilityHint("\(detail) \(tag)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - PlanCard

/// S12. Radius 18, min 132pt tall, a badge pill overlapping the top edge. Prices
/// never animate; the badge shows only when StoreKit says the trial applies.
struct PlanCard: View {
    let title: String
    let price: String
    /// The StoreKit price inside `price` (“$69.99” in “$69.99 a year”), set
    /// large; the period around it stays small so the line fits the card.
    var priceEmphasis: String? = nil
    let subline: String
    let badge: String?
    let isSelected: Bool
    let accessibilityText: String
    let action: () -> Void

    var body: some View {
        Button {
            BedrockHaptics.select()
            action()
        } label: {
            VStack(alignment: .leading, spacing: Space.s2) {
                Text(title)
                    .font(BedrockFont.headline)
                    .foregroundStyle(BedrockColor.inkPrimary)
                priceText
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .transaction { $0.animation = nil } // prices never animate
                Text(subline)
                    .font(BedrockFont.footnote)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transaction { $0.animation = nil }
                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: BedrockSize.planCardMinHeight, alignment: .topLeading)
            .padding(.horizontal, Space.s4)
            .padding(.top, Space.s5)
            .padding(.bottom, Space.s4)
            .background(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
                .fill(isSelected ? BedrockColor.emberWash : BedrockColor.bgSurface))
            .overlay(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
                .strokeBorder(isSelected ? BedrockColor.ember : BedrockColor.lineStrong, lineWidth: isSelected ? 1.5 : 1))
            .overlay(alignment: .top) {
                if let badge {
                    Text(badge)
                        .font(BedrockFont.footnote.weight(.semibold))
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .padding(.horizontal, Space.s3)
                        .padding(.vertical, Space.s1)
                        .background(Capsule().fill(BedrockColor.emberDeep))
                        .fixedSize()
                        .offset(y: -BedrockSize.badgeOverlap)
                }
            }
            .animation(BedrockMotion.chipColour, value: isSelected)
            .contentShape(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

extension PlanCard {
    private var priceText: Text {
        guard let emphasis = priceEmphasis, let range = price.range(of: emphasis) else {
            return Text(price).font(BedrockFont.planPrice)
        }
        return Text(String(price[..<range.lowerBound])).font(BedrockFont.subhead.weight(.medium))
            + Text(emphasis).font(BedrockFont.planPrice)
            + Text(String(price[range.upperBound...])).font(BedrockFont.subhead.weight(.medium))
    }
}

// MARK: - HomeCard

/// Home (COMPONENTS.md): title + subtitle, a chevron when tappable, × to dismiss
/// (except “Finish setting up”).
struct HomeCard: View {
    let title: String
    let subtitle: String
    var action: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: Space.s3) {
            Button {
                action?()
            } label: {
                HStack(spacing: Space.s3) {
                    VStack(alignment: .leading, spacing: Space.s1) {
                        Text(title)
                            .font(BedrockFont.headline)
                            .foregroundStyle(BedrockColor.inkPrimary)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(BedrockFont.subhead)
                                .foregroundStyle(BedrockColor.inkSecondary)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    if action != nil {
                        Image(systemName: "chevron.right")
                            .font(BedrockFont.subhead.weight(.semibold))
                            .foregroundStyle(BedrockColor.inkTertiary)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressOpacityStyle())
            .disabled(action == nil)
            .accessibilityElement(children: .combine)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(BedrockFont.footnote.weight(.semibold))
                        .foregroundStyle(BedrockColor.inkTertiary)
                        .frame(width: BedrockSize.circleButton, height: BedrockSize.circleButton)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressOpacityStyle())
                .accessibilityLabel(OnbCopy.string("onb.common.dismiss"))
            }
        }
        .padding(.leading, Space.s5)
        .padding(.trailing, onDismiss == nil ? Space.s5 : Space.s2)
        .padding(.vertical, Space.s3)
        .frame(minHeight: BedrockSize.homeCardMinHeight)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineSubtle))
    }
}

// MARK: - StatusChip

/// Home's status: “Wall up · Strict Mode on / off” or “Wall not up”, with a dot.
/// On the free wall it's a button into S10 → S12; with no wall it opens S2.
struct StatusChip: View {
    enum Status { case pro, free, noWall }

    let status: Status
    var action: (() -> Void)?

    private var text: String {
        switch status {
        case .pro: OnbCopy.string("onb.home.status_pro")
        case .free: OnbCopy.string("onb.home.status_free")
        case .noWall: OnbCopy.string("onb.home.status_no_wall")
        }
    }

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: Space.s2) {
                Circle()
                    .fill(status == .noWall ? BedrockColor.inkTertiary : BedrockColor.emberGlow)
                    .frame(width: BedrockSize.statusDot, height: BedrockSize.statusDot)
                Text(text)
                    .font(BedrockFont.footnote.weight(.medium))
                    .foregroundStyle(BedrockColor.inkPrimary)
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(BedrockFont.caption.weight(.semibold))
                        .foregroundStyle(BedrockColor.inkTertiary)
                }
            }
            .padding(.horizontal, Space.s3)
            .frame(minHeight: BedrockSize.textButtonHeight)
            .background(Capsule().fill(BedrockColor.bgSurface))
            .overlay(Capsule().strokeBorder(BedrockColor.lineSubtle))
        }
        .buttonStyle(PressOpacityStyle())
        .disabled(action == nil)
        .accessibilityElement(children: .combine)
    }
}
