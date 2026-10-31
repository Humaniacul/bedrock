import SwiftUI

// The Begin chapter's pieces: NotificationPreview (S14), UrgeButton and
// BreathRing (S15, Home) — COMPONENTS.md › Illustration and hero pieces.

// MARK: - NotificationPreview

/// A lock-screen miniature (300 × 232pt, neutral wallpaper, date and time) with
/// one notification using the app icon. The time is a few minutes before the
/// person's first S5 window: the S5 payoff, seen before iOS asks.
struct NotificationPreview: View {
    let time: Date
    let appName: String
    let now: String
    let message: String

    var body: some View {
        VStack(spacing: Space.s1) {
            Text(time.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(BedrockFont.footnote.weight(.semibold))
                .foregroundStyle(BedrockColor.inkPrimary.opacity(0.85))
            Text(time.formatted(.dateTime.hour().minute()))
                .font(BedrockFont.lockScreenTime)
                .foregroundStyle(BedrockColor.inkPrimary)
                .monospacedDigit()
            Spacer(minLength: Space.s3)
            HStack(alignment: .top, spacing: Space.s3) {
                AppIconMark(size: BedrockSize.previewIcon)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(appName)
                            .font(BedrockFont.footnote.weight(.semibold))
                        Spacer()
                        Text(now)
                            .font(BedrockFont.caption)
                            .foregroundStyle(BedrockColor.inkPrimary.opacity(0.6))
                    }
                    Text(message)
                        .font(BedrockFont.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(BedrockColor.inkPrimary)
            }
            .padding(Space.s3)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(BedrockColor.inkPrimary.opacity(0.14)))
        }
        .padding(Space.s5)
        .frame(width: BedrockSize.lockScreenPreview.width)
        .frame(minHeight: BedrockSize.lockScreenPreview.height)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(LinearGradient(colors: [BedrockColor.stoneMid, BedrockColor.bgSurface, BedrockColor.emberDeep.opacity(0.6)],
                                     startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineSubtle))
        .accessibilityElement()
        .accessibilityLabel(OnbCopy.string("onb.s14.a11y_preview"))
    }
}

/// The app icon, drawn: the cut stone on obsidian with a low ember horizon
/// (the notification preview). Matches the AppIcon asset.
struct AppIconMark: View {
    var size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .fill(LinearGradient(colors: [BedrockColor.bgRaised, BedrockColor.bgBase],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .bottom) {
                Ellipse()
                    .fill(RadialGradient(colors: [BedrockColor.ember.opacity(0.4), .clear],
                                         center: .center, startRadius: 0, endRadius: size * 0.6))
                    .frame(width: size * 1.2, height: size * 0.6)
                    .offset(y: size * 0.3)
            }
            .overlay {
                ZStack {
                    StoneMark()
                        .fill(LinearGradient(colors: [BedrockColor.emberHot, BedrockColor.emberGlow, BedrockColor.ember],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    StoneFacet(points: StoneFacet.lit).fill(BedrockColor.inkPrimary.opacity(0.18))
                    StoneFacet(points: StoneFacet.shade).fill(BedrockColor.emberDeep.opacity(0.4))
                }
                .frame(width: size * 0.40, height: size * 0.57)
                .shadow(color: BedrockColor.emberGlow.opacity(0.45), radius: size * 0.08)
            }
            .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// One plane of the cut stone (the icon's lit top face and shaded lower face).
private struct StoneFacet: Shape {
    let points: [CGPoint]

    static let lit = [CGPoint(x: 0.24, y: 0.00), CGPoint(x: 0.86, y: 0.08), CGPoint(x: 0.52, y: 0.40), CGPoint(x: 0.00, y: 0.76)]
    static let shade = [CGPoint(x: 0.52, y: 0.40), CGPoint(x: 1.00, y: 0.64), CGPoint(x: 0.58, y: 1.00)]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
        path.closeSubpath()
        return path
    }
}

// MARK: - UrgeButton

/// The urge button. S15: a 168pt circle of ember glass that Breathes. Home: a
/// full-width 64pt capsule. Press: medium impact.
struct UrgeButton: View {
    enum Style { case circle, capsule }

    let title: String
    var style: Style = .capsule
    var accessibilityHint: String = ""
    let action: () -> Void

    var body: some View {
        Button {
            BedrockHaptics.urge()
            action()
        } label: {
            switch style {
            case .circle:
                Text(title)
                    .font(BedrockFont.headline)
                    .foregroundStyle(BedrockColor.onEmber)
                    .multilineTextAlignment(.center)
                    .padding(Space.s5)
                    .frame(width: BedrockSize.urgeCircle, height: BedrockSize.urgeCircle)
                    .background(Circle().fill(BedrockColor.primaryFill))
                    .overlay(Circle().strokeBorder(BedrockColor.primaryBorder, lineWidth: 1))
                    .background(Circle().fill(BedrockColor.primaryShadow).blur(radius: BedrockSize.primaryShadowRadius))
                    .bedrockBreath()
            case .capsule:
                HStack(spacing: Space.s2) {
                    Image(systemName: "wind")
                    Text(title)
                }
                .font(BedrockFont.headline)
                .foregroundStyle(BedrockColor.onEmber)
                .frame(maxWidth: .infinity, minHeight: BedrockSize.urgeCapsule)
                .background(Capsule().fill(BedrockColor.primaryFill))
                .overlay(Capsule().strokeBorder(BedrockColor.primaryBorder, lineWidth: 1))
            }
        }
        .buttonStyle(PressOpacityStyle())
        .accessibilityHint(accessibilityHint)
    }
}

// MARK: - BreathRing

/// S15: replaces the urge button after the press. Scale 0.56 → 1 over 4s (in),
/// back over 4s (out), a soft transient at each phase change; the phase labels
/// are announced. Reduce Motion: brightness changes instead of size.
struct BreathRing: View {
    let inLabel: String
    let outLabel: String
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    @State private var label = ""

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [BedrockColor.emberGlow.opacity(0.5), BedrockColor.ember.opacity(0.15)],
                                     center: .center, startRadius: 0, endRadius: BedrockSize.urgeCircle / 2))
                .overlay(Circle().strokeBorder(BedrockColor.emberGlow.opacity(0.6), lineWidth: 1.5))
                .frame(width: BedrockSize.urgeCircle, height: BedrockSize.urgeCircle)
                .scaleEffect(reduceMotion ? 1 : (expanded ? 1 : BedrockSize.breathMinScale))
                .brightness(reduceMotion ? (expanded ? 0.15 : -0.1) : 0)
            Text(label)
                .font(BedrockFont.headline)
                .foregroundStyle(BedrockColor.inkPrimary)
                .contentTransition(.opacity)
        }
        .frame(width: BedrockSize.urgeCircle, height: BedrockSize.urgeCircle)
        .task { await breathe() }
        .accessibilityElement()
        .accessibilityLabel(label)
    }

    private func breathe() async {
        HoldRamp.shared.prepare()
        phase(inLabel)
        withAnimation(.easeInOut(duration: BedrockTiming.breathIn)) { expanded = true }
        try? await Task.sleep(for: .seconds(BedrockTiming.breathIn))
        guard !Task.isCancelled else { return }
        phase(outLabel)
        withAnimation(.easeInOut(duration: BedrockTiming.breathOut)) { expanded = false }
        try? await Task.sleep(for: .seconds(BedrockTiming.breathOut))
        guard !Task.isCancelled else { return }
        HoldRamp.shared.stopEngine()
        onDone()
    }

    private func phase(_ text: String) {
        withAnimation(BedrockMotion.reducedFade) { label = text }
        BedrockHaptics.breathPhase()
        AccessibilityNotification.Announcement(text).post()
    }
}
