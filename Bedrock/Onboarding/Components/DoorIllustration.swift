import SwiftUI

/// S9 (COMPONENTS.md): a settings-style row in Bedrock's own style — not a copy
/// of iOS — with a switch, and a miniature of their wall. Plays twice: a touch
/// dot appears, the switch slides off, the wall dims to 30% and its top course
/// slips; then it rests off. No haptic: it's a warning, not an event.
/// Reduce Motion: two static panels side by side, on then off.
struct DoorIllustration: View {
    let rowTitle: String
    let rowApp: String
    var hasApps: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var on = true
    @State private var touch = false

    var body: some View {
        Group {
            if reduceMotion {
                HStack(spacing: Space.s3) {
                    panel(on: true)
                    panel(on: false)
                }
            } else {
                panel(on: on)
                    .task { await play() }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(OnbCopy.string("onb.s9.a11y_illustration"))
    }

    private func panel(on: Bool) -> some View {
        VStack(spacing: Space.s4) {
            HStack(spacing: Space.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rowTitle)
                        .font(BedrockFont.subhead)
                        .foregroundStyle(BedrockColor.inkPrimary)
                    Text(rowApp)
                        .font(BedrockFont.footnote)
                        .foregroundStyle(BedrockColor.inkTertiary)
                }
                Spacer(minLength: Space.s2)
                BedrockSwitch(isOn: on)
                    .overlay {
                        Circle()
                            .fill(BedrockColor.inkPrimary.opacity(0.35))
                            .frame(width: BedrockSize.touchDot, height: BedrockSize.touchDot)
                            .opacity(touch ? 1 : 0)
                    }
            }
            .padding(Space.s4)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))

            WallView(web: .landed, apps: hasApps ? .landed : nil, schedule: .landed,
                     scale: BedrockSize.doorWallScale, dimmed: !on)
                .offset(y: on ? 0 : BedrockSize.doorSlip)
        }
        .padding(Space.s5)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(BedrockColor.lineSubtle))
    }

    /// 600ms touch dot · 900ms switch slides off (220ms) · 4.0s reset, once more, then rest off.
    private func play() async {
        for _ in 0..<BedrockTiming.doorPlays {
            on = true
            touch = false
            try? await Task.sleep(for: .seconds(BedrockTiming.doorTouch))
            withAnimation(BedrockMotion.reducedFade) { touch = true }
            try? await Task.sleep(for: .seconds(BedrockTiming.doorSwitch - BedrockTiming.doorTouch))
            withAnimation(BedrockMotion.doorSwitch) { on = false }
            withAnimation(BedrockMotion.reducedFade.delay(BedrockTiming.doorTouchFade)) { touch = false }
            try? await Task.sleep(for: .seconds(BedrockTiming.doorReset - BedrockTiming.doorSwitch))
            if Task.isCancelled { return }
        }
    }
}

/// A switch drawn in Bedrock's style (S9 shows Settings without imitating it).
struct BedrockSwitch: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? BedrockColor.ember : BedrockColor.lineStrong)
            .frame(width: BedrockSize.switchSize.width, height: BedrockSize.switchSize.height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(BedrockColor.inkPrimary)
                    .padding(2)
            }
            .accessibilityHidden(true)
    }
}
