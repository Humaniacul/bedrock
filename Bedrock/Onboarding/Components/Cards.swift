import SwiftUI

// OptionCard (S11), PlanCard (S12), HomeCard and StatusChip (Home), as the
// prototype draws them.

// MARK: - OptionCard

/// S11: radius 20, 1.5pt edge (ember when chosen), `emberWash` when chosen;
/// a serif 26 title, a 15pt body, a small raised tag in Glow.
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
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .ptype(.option)
                    .foregroundStyle(BedrockColor.inkPrimary)
                Text(detail)
                    .ptype(.subhead)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(tag)
                    .ptype(.captionPlain)
                    .foregroundStyle(BedrockColor.emberGlow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(BedrockColor.bgRaised))
                    .padding(.top, Space.s1)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, Space.s4)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(isSelected ? BedrockColor.emberWash : BedrockColor.bgSurface))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(isSelected ? BedrockColor.ember : BedrockColor.lineStrong, lineWidth: 1.5))
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

/// S12: radius 18, min 132pt, 1.5pt edge, a badge pill overlapping the top edge
/// at the right. Title 15 semibold, the price in serif 26, a 12.5pt line.
/// Prices never animate.
struct PlanCard: View {
    enum BadgeStyle { case ember, deep }

    let title: String
    let price: String
    let subline: String
    let badge: String?
    var badgeStyle: BadgeStyle = .ember
    let isSelected: Bool
    let accessibilityText: String
    let action: () -> Void

    var body: some View {
        Button {
            BedrockHaptics.select()
            action()
        } label: {
            VStack(alignment: .leading, spacing: Space.s1) {
                Text(title)
                    .ptype(.subheadSemibold)
                Text(price)
                    .ptype(.option)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .transaction { $0.animation = nil }
                Text(subline)
                    .ptype(.caption)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transaction { $0.animation = nil }
                Spacer(minLength: 0)
            }
            .foregroundStyle(BedrockColor.inkPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: BedrockSize.planCardMinHeight, alignment: .topLeading)
            .padding(.horizontal, 14)
            .padding(.top, Space.s4)
            .padding(.bottom, 14)
            .background(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
                .fill(isSelected ? BedrockColor.emberWash : BedrockColor.bgSurface))
            .overlay(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
                .strokeBorder(isSelected ? BedrockColor.ember : BedrockColor.lineStrong, lineWidth: 1.5))
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .ptype(.badge)
                        .foregroundStyle(badgeStyle == .ember ? BedrockColor.onEmber : BedrockColor.inkPrimary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(badgeStyle == .ember ? BedrockColor.ember : BedrockColor.emberDeep))
                        .fixedSize()
                        .offset(x: -10, y: -10)
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

// MARK: - HomeCard

/// Home: radius 18, translucent basalt, a title (16 semibold) and a line (14pt),
/// a chevron when it opens something, × to dismiss (except “Finish setting up”).
struct HomeCard: View {
    let title: String
    let subtitle: String
    var action: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            Button {
                action?()
            } label: {
                HStack(spacing: Space.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .ptype(.calloutSemibold)
                            .foregroundStyle(BedrockColor.inkPrimary)
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .ptype(.rowDetail)
                                .foregroundStyle(BedrockColor.inkSecondary)
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if action != nil {
                        ProtoIcon.chevronRight
                            .stroke(BedrockColor.inkTertiary, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                            .frame(width: 8, height: 14)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.leading, Space.s4)
                .padding(.trailing, 6)
                .padding(.vertical, 10)
                // As the prototype renders them: 64pt when it opens something,
                // 84pt when it only informs.
                .frame(minHeight: action == nil ? 84 : 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressOpacityStyle())
            .disabled(action == nil)
            .accessibilityElement(children: .combine)

            if let onDismiss {
                Button(action: onDismiss) {
                    ViewBoxShape(viewBox: CGSize(width: 10, height: 10), path: Path { p in
                        p.move(to: CGPoint(x: 1.5, y: 1.5)); p.addLine(to: CGPoint(x: 8.5, y: 8.5))
                        p.move(to: CGPoint(x: 8.5, y: 1.5)); p.addLine(to: CGPoint(x: 1.5, y: 8.5))
                    })
                    .stroke(BedrockColor.inkTertiary, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                    .frame(width: 10, height: 10)
                    .frame(width: 48)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressOpacityStyle())
                .accessibilityLabel(OnbCopy.string("onb.common.dismiss"))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(BedrockColor.homeCardFill))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(BedrockColor.lineSubtle, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - StatusChip

/// Home's status: a 32pt glass capsule, an 8pt dot (Glow with a halo, or Dust
/// when the wall isn't up), 12.5pt text. A button into S10 (free) or S2 (no wall).
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
            HStack(spacing: 7) {
                Circle()
                    .fill(status == .noWall ? BedrockColor.inkDisabled : BedrockColor.emberGlow)
                    .background(Circle().fill(BedrockColor.emberGlow.opacity(status == .noWall ? 0 : 0.18)).padding(-3))
                    .frame(width: 8, height: 8)
                Text(text)
                    .ptype(.captionPlain)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, Space.s3)
            .frame(height: 32)
            .controlGlass(Capsule(), soft: true)
            .contentShape(Capsule())
        }
        .buttonStyle(PressOpacityStyle())
        .disabled(action == nil)
        .accessibilityElement(children: .combine)
    }
}
