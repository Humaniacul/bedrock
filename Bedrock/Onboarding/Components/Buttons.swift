import SwiftUI

// PrimaryButton, TextButton and LinkButton (COMPONENTS.md › Buttons), plus the
// glass controls the scaffold uses: GlassCircleButton (back, close) and
// FinishLaterButton. No haptics on routine taps.

// MARK: - PrimaryButton

/// The one ember action on a screen. 56pt capsule; disabled buttons still say why.
struct PrimaryButton: View {
    let title: String
    var isEnabled = true
    /// Shows a small spinner beside the label; the label stays (S2 while iOS answers).
    var isLoading = false
    /// Read by VoiceOver when disabled, e.g. `onb.common.pick_at_least_one`.
    var disabledHint: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s3) {
                // A hidden twin on the leading side keeps the label centred.
                if isLoading { spinner.hidden() }
                Text(title)
                    .font(BedrockFont.headline)
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
            .padding(.vertical, Space.s3)
            .frame(maxWidth: .infinity, minHeight: BedrockSize.primaryHeight)
            .background { background }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? BedrockMotion.pressedOpacity : 1)
            .animation(BedrockMotion.press, value: configuration.isPressed)
    }

    @ViewBuilder private var background: some View {
        ZStack {
            if isEnabled {
                // Baked shadow: a static blurred layer behind the fill, never a `.shadow`
                // on the animating button. (Not `.drawingGroup()`: that clips the blur
                // to the button's frame and leaves a hard rectangle.)
                Capsule()
                    .fill(BedrockColor.primaryShadow)
                    .blur(radius: BedrockSize.primaryShadowRadius)
                    .offset(y: BedrockSize.primaryShadowY)
                Capsule().fill(BedrockColor.primaryFill)
                Capsule()
                    .inset(by: 1)
                    .strokeBorder(
                        LinearGradient(colors: [BedrockColor.primaryHighlight, .clear],
                                       startPoint: .top, endPoint: .center),
                        lineWidth: 1)
                Capsule().strokeBorder(BedrockColor.primaryBorder, lineWidth: 1)
            } else {
                Capsule().fill(BedrockColor.primaryDisabledFill)
                Capsule().strokeBorder(BedrockColor.lineSubtle, lineWidth: 1)
            }
        }
    }
}

// MARK: - TextButton

/// Secondary actions: “Skip”, “Not now”, “Keep the free wall”. 44pt tall, never a
/// smaller target than the primary, and the free path is never styled weaker.
struct TextButton: View {
    let title: String
    var fullWidth = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BedrockFont.textButton)
                .foregroundStyle(BedrockColor.inkPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: BedrockSize.textButtonHeight)
                .padding(.horizontal, Space.s3)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressOpacityStyle())
    }
}

// MARK: - LinkButton

/// Underlined 14pt links: the crisis link, “What it can’t stop”, “Other plans”,
/// “I got stuck”. 40pt hit height.
struct LinkButton: View {
    enum Tone { case tertiary, secondary }

    let title: String
    var tone: Tone = .tertiary
    let action: () -> Void

    @ScaledMetric(relativeTo: .subheadline) private var size = BedrockSize.linkText

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BedrockFont.link(size: size))
                .underline()
                .foregroundStyle(tone == .tertiary ? BedrockColor.inkTertiary : BedrockColor.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: BedrockSize.linkHitHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressOpacityStyle())
    }
}

// MARK: - Glass controls (scaffold chrome)

/// Back (chevron) and close (×). 44 × 44pt Liquid Glass circle; solid under
/// Reduce Transparency. Labelled with what it does.
struct GlassCircleButton: View {
    enum Kind {
        case back, close

        var symbol: String { self == .back ? "chevron.left" : "xmark" }
    }

    let kind: Kind
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: kind.symbol)
                .font(BedrockFont.headline)
                .foregroundStyle(BedrockColor.inkPrimary)
                .frame(width: BedrockSize.circleButton, height: BedrockSize.circleButton)
                .bedrockGlass(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PressOpacityStyle())
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // fixed 44pt control
        .accessibilityLabel(accessibilityLabel)
        .accessibilityShowsLargeContentViewer()
    }
}

/// Glass capsule, 44pt, “Finish later”. Shown S4–S11; opens the Finish later sheet.
struct FinishLaterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(OnbCopy.string("onb.s4.top_right"))
                .font(BedrockFont.finishLater)
                .foregroundStyle(BedrockColor.inkPrimary)
                .lineLimit(1)
                .padding(.horizontal, Space.s4)
                .frame(height: BedrockSize.finishLaterHeight)
                .bedrockGlass(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(PressOpacityStyle())
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // fixed 44pt control
        .accessibilityLabel(OnbCopy.string("onb.common.finish_later_a11y"))
        .accessibilityShowsLargeContentViewer()
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

// MARK: - Previews

#if DEBUG
struct PrimaryButtonPreview: View {
    var body: some View {
        PreviewPage {
            VStack(spacing: Space.s8) {
                PrimaryButton(title: OnbCopy.string("onb.s1.primary")) {}
                PrimaryButton(title: OnbCopy.string("onb.s5.primary"), isEnabled: false,
                              disabledHint: OnbCopy.string("onb.common.pick_at_least_one")) {}
                PrimaryButton(title: OnbCopy.string("onb.s2.primary"), isLoading: true) {}
            }
        }
    }
}

struct TextButtonPreview: View {
    var body: some View {
        PreviewPage {
            VStack(spacing: Space.s6) {
                TextButton(title: OnbCopy.string("onb.s4.secondary")) {}
                TextButton(title: OnbCopy.string("onb.s12.free_path"), fullWidth: true) {}
                TextButton(title: OnbCopy.string("onb.fl.secondary")) {}
            }
        }
    }
}

struct LinkButtonPreview: View {
    var body: some View {
        PreviewPage {
            VStack(spacing: Space.s5) {
                LinkButton(title: OnbCopy.string("onb.s8.crisis_link")) {}
                LinkButton(title: OnbCopy.string("onb.s10.link"), tone: .secondary) {}
                LinkButton(title: OnbCopy.string("onb.s12.link"), tone: .secondary) {}
                LinkButton(title: OnbCopy.string("onb.s13_5b.link")) {}
            }
        }
    }
}

#Preview("PrimaryButton · 402×874", traits: .fixedLayout(width: 402, height: 874)) { PrimaryButtonPreview().onboardingPreview(.standard) }
#Preview("PrimaryButton · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { PrimaryButtonPreview().onboardingPreview(.reduceMotion) }
#Preview("PrimaryButton · AX5", traits: .fixedLayout(width: 402, height: 874)) { PrimaryButtonPreview().onboardingPreview(.ax5) }
#Preview("PrimaryButton · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { PrimaryButtonPreview().onboardingPreview(.ax5ReduceMotion) }

#Preview("TextButton · 402×874", traits: .fixedLayout(width: 402, height: 874)) { TextButtonPreview().onboardingPreview(.standard) }
#Preview("TextButton · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { TextButtonPreview().onboardingPreview(.reduceMotion) }
#Preview("TextButton · AX5", traits: .fixedLayout(width: 402, height: 874)) { TextButtonPreview().onboardingPreview(.ax5) }
#Preview("TextButton · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { TextButtonPreview().onboardingPreview(.ax5ReduceMotion) }

#Preview("LinkButton · 402×874", traits: .fixedLayout(width: 402, height: 874)) { LinkButtonPreview().onboardingPreview(.standard) }
#Preview("LinkButton · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { LinkButtonPreview().onboardingPreview(.reduceMotion) }
#Preview("LinkButton · AX5", traits: .fixedLayout(width: 402, height: 874)) { LinkButtonPreview().onboardingPreview(.ax5) }
#Preview("LinkButton · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { LinkButtonPreview().onboardingPreview(.ax5ReduceMotion) }
#endif
