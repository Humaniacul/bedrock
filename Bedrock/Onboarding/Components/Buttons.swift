import SwiftUI

// Buttons, as the prototype draws them: the ember primary, the plain secondary
// under it, quiet and underlined links, pills, the sheets' closing button, and
// the glass controls (back, close, Finish later). No haptics on routine taps.

// MARK: - PrimaryButton

/// The one ember action on a screen: a 56pt capsule with a 1pt warm edge, an
/// inset top highlight and a baked ember shadow. Disabled buttons still say why.
struct PrimaryButton: View {
    let title: String
    var isEnabled = true
    /// A small spinner beside the label; the label stays (S2 while iOS answers).
    var isLoading = false
    /// Read by VoiceOver when disabled, e.g. `onb.common.pick_at_least_one`.
    var disabledHint: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s3) {
                if isLoading { spinner.hidden() }
                Text(title)
                    .ptype(.primary)
                    .multilineTextAlignment(.center)
                if isLoading { spinner }
            }
        }
        .buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
        .disabled(!isEnabled)
        .allowsHitTesting(!isLoading)
        .accessibilityHint(isEnabled ? "" : (disabledHint ?? ""))
    }

    private var spinner: some View {
        ProgressView()
            .controlSize(.small)
            .tint(BedrockColor.onEmber)
            .accessibilityHidden(true)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? BedrockColor.onEmber : BedrockColor.inkDisabled)
            .padding(.horizontal, Space.s6)
            .frame(maxWidth: .infinity, minHeight: BedrockSize.primaryHeight)
            .background { PrimaryFill(isEnabled: isEnabled) }
            .contentShape(Capsule())
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(BedrockMotion.press, value: configuration.isPressed)
    }
}

/// The primary's fill: drawn once, never animated (its shadow is baked in).
struct PrimaryFill: View {
    var isEnabled = true

    var body: some View {
        if isEnabled {
            Capsule()
                .fill(BedrockColor.primaryFill)
                .shadow(color: BedrockColor.primaryDrop, radius: 13, x: 0, y: 10)
                .overlay(Capsule().strokeBorder(
                    LinearGradient(colors: [BedrockColor.primaryInset, .clear],
                                   startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.14)),
                    lineWidth: 1.5))
                .overlay(Capsule().strokeBorder(BedrockColor.primaryBorder, lineWidth: 1))
        } else {
            Capsule()
                .fill(BedrockColor.primaryDisabledFill)
                .overlay(Capsule().strokeBorder(BedrockColor.lineSubtle, lineWidth: 1))
        }
    }
}

// MARK: - Secondary actions

/// Under the primary, 6pt down: “Skip”, “Not now”, “Keep going”. 44pt, 16pt Chalk.
/// The free path is never styled weaker than this.
struct TextButton: View {
    let title: String
    var fullWidth = true
    var type: PType = .callout
    var height: CGFloat = BedrockSize.textButtonHeight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .ptype(type)
                .foregroundStyle(BedrockColor.inkPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressOpacityStyle())
    }
}

/// S1's “I'm here to support someone”: 15pt Limestone, no underline.
struct QuietLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .ptype(.subheadPlain)
                .foregroundStyle(BedrockColor.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: BedrockSize.textButtonHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressOpacityStyle())
    }
}

/// Underlined links: the crisis link, “What it can't stop”, “Other plans”,
/// “I got stuck”. Underline offset 3pt.
struct LinkButton: View {
    enum Tone { case tertiary, secondary, ember }

    let title: String
    var tone: Tone = .tertiary
    var type: PType = .notePlain
    var height: CGFloat = BedrockSize.linkHitHeight
    let action: () -> Void

    private var color: Color {
        switch tone {
        case .tertiary: BedrockColor.inkTertiary
        case .secondary: BedrockColor.inkSecondary
        case .ember: BedrockColor.emberGlow
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .ptype(type)
                .underline(pattern: .solid, color: color)
                .baselineOffset(0)
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .frame(minHeight: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressOpacityStyle())
    }
}

/// A small raised pill: S3's “Add”, S8's “Set it”, S12's “Remind me tomorrow”.
struct PillButton: View {
    let title: String
    var height: CGFloat = 36
    var padding: CGFloat = 14
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .ptype(.subheadPlain)
                .foregroundStyle(BedrockColor.inkPrimary)
                .padding(.horizontal, padding)
                .frame(minHeight: height)
                .background(Capsule().fill(BedrockColor.bgRaised))
                .overlay(Capsule().strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(PressOpacityStyle())
    }
}

/// A sheet's closing button: 52pt, raised, 17pt medium (“Close”, “Got it”).
struct SheetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .ptype(PType(face: .sans, size: 17, line: nil, weight: .medium, relativeTo: .headline))
                .foregroundStyle(BedrockColor.inkPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Capsule().fill(BedrockColor.bgRaised))
                .overlay(Capsule().strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(PressOpacityStyle())
    }
}

// MARK: - Glass controls (scaffold chrome)

/// The prototype's control glass: a faint white fill, a 1pt edge and a top
/// highlight. Solid `bgRaised` under Reduce Transparency.
struct ControlGlass<S: InsettableShape>: ViewModifier {
    let shape: S
    var soft = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(shape.fill(reduceTransparency ? BedrockColor.bgRaised
                                                      : (soft ? BedrockColor.glassFillSoft : BedrockColor.glassFill)))
            .overlay(shape.strokeBorder(soft ? BedrockColor.glassEdgeSoft : BedrockColor.glassEdge, lineWidth: 1))
            .overlay(shape.strokeBorder(
                LinearGradient(colors: [BedrockColor.glassHighlight, .clear],
                               startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.12)),
                lineWidth: 1.5))
    }
}

extension View {
    func controlGlass<S: InsettableShape>(_ shape: S, soft: Bool = false) -> some View {
        modifier(ControlGlass(shape: shape, soft: soft))
    }
}

/// Back (chevron) and close (×): a 44pt glass circle, labelled with what it does.
struct GlassCircleButton: View {
    enum Kind { case back, close }

    let kind: Kind
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                switch kind {
                case .back:
                    ProtoIcon.chevronLeft
                        .stroke(BedrockColor.inkPrimary, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 12, height: 20)
                case .close:
                    ProtoIcon.close
                        .stroke(BedrockColor.inkPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 14, height: 14)
                }
            }
            .frame(width: BedrockSize.circleButton, height: BedrockSize.circleButton)
            .controlGlass(Circle())
            .contentShape(Circle())
        }
        .buttonStyle(PressOpacityStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// “Finish later”: a 44pt glass capsule, 15pt. Shown S4–S11.
struct FinishLaterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(OnbCopy.string("onb.s4.top_right"))
                .ptype(.subheadPlain)
                .foregroundStyle(BedrockColor.inkPrimary)
                .lineLimit(1)
                .padding(.horizontal, Space.s4)
                .frame(height: BedrockSize.finishLaterHeight)
                .controlGlass(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(PressOpacityStyle())
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityLabel(OnbCopy.string("onb.common.finish_later_a11y"))
    }
}

/// Press feedback for the quiet buttons: a dip in opacity, no movement.
struct PressOpacityStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? BedrockMotion.pressedOpacity : 1)
            .animation(BedrockMotion.press, value: configuration.isPressed)
    }
}
