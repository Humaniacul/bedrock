import SwiftUI

// The lock-screen preview (S14, SP3), the app icon tile, S15's urge button and
// breath ring, Home's urge capsule — as the prototype draws them.

// MARK: - Lock-screen preview

/// A 300 × 232 lock screen (radius 30): a wallpaper, the date and a large
/// clock, and one notification at the bottom with Bedrock's icon. S14 uses the
/// cool wallpaper and drops the notification in; SP3 the warm one.
struct NotificationPreview: View {
    enum Wallpaper { case cool, warm }

    let date: String
    let time: String
    let appName: String
    let now: String
    let message: String
    var wallpaper: Wallpaper = .cool
    var messageType: PType = .listItem
    var accessibilityText: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text(date)
                    .ptype(.lockDate)
                    .foregroundStyle(.white.opacity(0.78))
                Text(time)
                    .ptype(.lockTime)
                    .foregroundStyle(.white.opacity(0.92))
                    .monospacedDigit()
            }
            .padding(.top, 20)
            .frame(maxHeight: .infinity, alignment: .top)

            HStack(spacing: 10) {
                AppIconMark(size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: Space.s2) {
                        Text(appName)
                            .ptype(.subheadSemibold)
                            .foregroundStyle(.white)
                        Spacer(minLength: 0)
                        Text(now)
                            .ptype(.footnotePlain)
                            .foregroundStyle(BedrockColor.notifSecondary)
                    }
                    Text(message)
                        .ptype(messageType)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, Space.s3)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(wallpaper == .cool ? BedrockColor.notifCool : BedrockColor.notifWarm))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.14), .clear], startPoint: .top,
                                             endPoint: UnitPoint(x: 0.5, y: 0.1)), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
            .padding(.horizontal, Space.s3)
            .padding(.bottom, 14)
            .opacity(arrived ? 1 : 0)
            .offset(y: arrived || reduceMotion ? 0 : -24)
            .scaleEffect(arrived || reduceMotion ? 1 : 0.98)
        }
        .frame(width: BedrockSize.lockScreenPreview.width, height: BedrockSize.lockScreenPreview.height)
        .background(wallpaperFill)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 30, x: 0, y: 24)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
        .task {
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(reduceMotion ? BedrockMotion.reducedFade : .spring(response: 0.5, dampingFraction: 0.75)) {
                arrived = true
            }
            BedrockHaptics.stoneLands()
        }
    }

    /// radial-gradient(120% 90% at 28% 0%, …)
    private var wallpaperFill: some View {
        let colors = wallpaper == .cool
            ? [BedrockColor.lockCoolHi, BedrockColor.lockCoolMid, BedrockColor.lockCoolLo]
            : [BedrockColor.lockWarmHi, BedrockColor.lockWarmMid, BedrockColor.lockWarmLo]
        return GeometryReader { proxy in
            EllipticalGradient(stops: [
                .init(color: colors[0], location: 0), .init(color: colors[1], location: 0.55), .init(color: colors[2], location: 1),
            ], center: UnitPoint(x: 0.28, y: 0), startRadiusFraction: 0, endRadiusFraction: 1)
            .frame(width: proxy.size.width * 2.4, height: proxy.size.height * 1.8)
            .position(x: proxy.size.width * 0.28, y: 0)
        }
        .background(colors[2])
    }
}

/// Bedrock's icon as the prototype draws it (the notification preview): a dark
/// tile, the grey standing stone, an ember horizon line under it. Matches the
/// AppIcon asset.
struct AppIconMark: View {
    var size: CGFloat

    var body: some View {
        let unit = size / 38
        RoundedRectangle(cornerRadius: 9 * unit, style: .continuous)
            .fill(LinearGradient(colors: [BedrockColor.iconTileHi, BedrockColor.bgBase],
                                 startPoint: UnitPoint(x: 0.33, y: 0), endPoint: UnitPoint(x: 0.67, y: 1)))
            .overlay(RoundedRectangle(cornerRadius: 9 * unit, style: .continuous).strokeBorder(.white.opacity(0.14), lineWidth: 0.5))
            .overlay(alignment: .topLeading) {
                StoneMarkView(top: BedrockColor.iconStoneHi, bottom: BedrockColor.iconStoneLo)
                    .frame(width: 16 * unit, height: 19 * unit)
                    .offset(x: 11 * unit, y: 8 * unit)
            }
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 1 * unit)
                    .fill(BedrockColor.emberGlow)
                    .frame(height: 2 * unit)
                    .padding(.horizontal, 8 * unit)
                    .padding(.bottom, 9 * unit)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - S15 · The urge button

/// A 168pt ember button inside a 240pt breathing halo: lit from above, a warm
/// edge, inner shade, a faint 12pt ring and a glow. Medium impact on press.
struct UrgeCircle: View {
    let title: String
    var accessibilityHint: String = ""
    let action: () -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(EllipticalGradient(stops: [
                    .init(color: BedrockColor.emberGlow.opacity(0.24), location: 0),
                    .init(color: BedrockColor.ember.opacity(0.06), location: 0.7),
                    .init(color: .clear, location: 1),
                ], center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5))
                .padding(6)
                .bedrockBreath()
                .accessibilityHidden(true)
            Button {
                BedrockHaptics.urge()
                action()
            } label: {
                Text(title)
                    .ptype(.urgeCircle)
                    .foregroundStyle(BedrockColor.onEmber)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .frame(width: BedrockSize.urgeCircle, height: BedrockSize.urgeCircle)
                    .background(
                        Circle()
                            .fill(EllipticalGradient(stops: [
                                .init(color: BedrockColor.urgeHi, location: 0),
                                .init(color: BedrockColor.urgeMid, location: 0.55),
                                .init(color: BedrockColor.urgeLo, location: 1),
                            ], center: UnitPoint(x: 0.5, y: 0.28), startRadiusFraction: 0, endRadiusFraction: 0.85))
                            .shadow(color: BedrockColor.urgeGlow, radius: 28, x: 0, y: 24)
                            .background(Circle().fill(BedrockColor.urgeHalo).padding(-12))
                    )
                    .overlay(Circle().strokeBorder(BedrockColor.urgeBorder, lineWidth: 1))
                    .overlay(Circle().strokeBorder(LinearGradient(colors: [BedrockColor.urgeInset, .clear],
                                                                  startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.1)), lineWidth: 1.5))
                    .overlay(Circle().fill(LinearGradient(colors: [.clear, BedrockColor.urgeLo.opacity(0.35)],
                                                          startPoint: UnitPoint(x: 0.5, y: 0.6), endPoint: .bottom))
                        .allowsHitTesting(false))
                    .contentShape(Circle())
            }
            .buttonStyle(PressOpacityStyle())
            .bedrockBreath()
            .accessibilityHint(accessibilityHint)
        }
        .frame(width: 240, height: 240)
    }
}

/// S15 after the press: a dashed 240pt circle and an ember ring that grows to
/// full over 4s (in) and back to 0.56 over 4s (out), the phase in serif 28.
/// Reduce Motion: the ring holds at 0.82 and brightens and dims instead.
struct BreathRing: View {
    let inLabel: String
    let outLabel: String
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false
    @State private var label = ""
    @State private var done = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(BedrockColor.lineStrong, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            Circle()
                .fill(EllipticalGradient(stops: [
                    .init(color: BedrockColor.emberGlow.opacity(0.5), location: 0),
                    .init(color: BedrockColor.ember.opacity(0.24), location: 0.62),
                    .init(color: BedrockColor.ember.opacity(0.05), location: 1),
                ], center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5))
                .overlay(Circle().strokeBorder(BedrockColor.emberGlow.opacity(0.55), lineWidth: 1.5))
                .shadow(color: BedrockColor.emberGlow.opacity(0.18), radius: 20)
                .scaleEffect(reduceMotion ? 0.82 : (expanded ? 1 : BedrockSize.breathMinScale))
                .opacity(reduceMotion ? (expanded ? 1 : 0.45) : 1)
            Text(label)
                .ptype(.reflect)
                .foregroundStyle(BedrockColor.inkPrimary)
                .contentTransition(.opacity)
        }
        .frame(width: 240, height: 240)
        .task { await breathe() }
        .accessibilityElement()
        .accessibilityLabel(done ? OnbCopy.string("onb.s15.a11y_done") : label)
    }

    private func breathe() async {
        HoldRamp.shared.prepare()
        phase(inLabel)
        withAnimation(.timingCurve(0.45, 0, 0.55, 1, duration: BedrockTiming.breathIn)) { expanded = true }
        try? await Task.sleep(for: .seconds(BedrockTiming.breathIn))
        guard !Task.isCancelled else { return }
        phase(outLabel)
        withAnimation(.timingCurve(0.45, 0, 0.55, 1, duration: BedrockTiming.breathOut)) { expanded = false }
        try? await Task.sleep(for: .seconds(BedrockTiming.breathOut))
        guard !Task.isCancelled else { return }
        HoldRamp.shared.stopEngine()
        withAnimation(BedrockMotion.reducedFade) { label = "" }
        done = true
        onDone()
    }

    private func phase(_ text: String) {
        withAnimation(BedrockMotion.reducedFade) { label = text }
        BedrockHaptics.breathPhase()
        AccessibilityNotification.Announcement(text).post()
    }
}

// MARK: - Home · The urge capsule

/// Home's urge button: a full-width 64pt ember capsule, 18pt semibold.
struct UrgeCapsule: View {
    let title: String
    var accessibilityHint: String = ""
    let action: () -> Void

    var body: some View {
        Button {
            BedrockHaptics.urge()
            action()
        } label: {
            Text(title)
                .ptype(.urgeCapsule)
                .foregroundStyle(BedrockColor.onEmber)
                .frame(maxWidth: .infinity, minHeight: BedrockSize.urgeCapsule)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [BedrockColor.capsuleHi, BedrockColor.capsuleLo], startPoint: .top, endPoint: .bottom))
                        .shadow(color: BedrockColor.urgeGlow, radius: 17, x: 0, y: 14)
                )
                .overlay(Capsule().strokeBorder(BedrockColor.capsuleBorder, lineWidth: 1))
                .overlay(Capsule().strokeBorder(LinearGradient(colors: [BedrockColor.capsuleInset, .clear],
                                                               startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.14)), lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(PressOpacityStyle())
        .accessibilityHint(accessibilityHint)
    }
}
