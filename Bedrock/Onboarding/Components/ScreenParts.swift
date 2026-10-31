import SwiftUI

// Small, repeated pieces of onboarding screens: the heading block, the privacy
// chip, the crisis link and sheet, the preview tag, the custom-word field.

// MARK: - Heading

/// Eyebrow, headline and body in the spec's type styles (most screens).
struct ScreenHeading: View {
    var eyebrow: String?
    let headline: String
    var headlineFont: Font = BedrockFont.title
    var line: LineSpec = BedrockLine.title
    var text: String?
    /// Carve the headline in (only where the spec asks: S1, “You're in.”, S13.6, Home, SP1).
    var carves = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let eyebrow {
                Text(eyebrow)
                    .bedrockEyebrow()
                    .padding(.bottom, Space.s3)
            }
            Group {
                if carves {
                    CarveText(headline, font: headlineFont)
                } else {
                    Text(headline).font(headlineFont)
                }
            }
            .tracking(line.tracking)
            .lineSpacing(line.lineSpacing)
            .foregroundStyle(BedrockColor.inkPrimary)
            .accessibilityAddTraits(.isHeader)
            if let text {
                Text(text)
                    .font(BedrockFont.body)
                    .lineSpacing(BedrockLine.body.lineSpacing)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .padding(.top, Space.s4)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Privacy chip

/// “Stays on this iPhone” under the S5–S7 grids.
struct PrivacyChip: View {
    let text: String
    var accessibilityText: String?

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "lock.fill")
        }
        .font(BedrockFont.footnote)
        .foregroundStyle(BedrockColor.inkTertiary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText ?? text)
    }
}

// MARK: - Crisis

/// The quiet link to support resources (S8, S12, S15 and elsewhere).
struct CrisisLink: View {
    let action: () -> Void

    var body: some View {
        LinkButton(title: OnbCopy.string("onb.s8.crisis_link"), action: action)
            .accessibilityLabel(OnbCopy.string("onb.s8.a11y_crisis_link"))
    }
}

/// Region-aware support resources (COMPONENTS.md › BedrockSheet). 988 only where
/// it works — the US (Suicide & Crisis Lifeline) and Canada (Suicide Crisis
/// Helpline). Elsewhere, “Find a helpline in your country” comes first. Always
/// ends with the emergency line.
struct CrisisSheetContent: View {
    let close: () -> Void

    @Environment(\.openURL) private var openURL

    /// onb.s8.crisis_sheet: title · body · 988 (US) · helpline · emergency · Close
    private var parts: [String] { OnbCopy.parts("onb.s8.crisis_sheet") }

    private var region: String? { Locale.current.region?.identifier }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            Text(part(1))
                .font(BedrockFont.body)
                .foregroundStyle(BedrockColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: Space.s2) {
                if let line = lifelineRow {
                    row(line, systemImage: "phone.fill") { openURL(URL(string: "tel:988")!) }
                }
                row(part(3), systemImage: "globe") { openURL(URL(string: "https://findahelpline.com")!) }
            }
            Text(part(4))
                .font(BedrockFont.subhead)
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
            TextButton(title: part(5), fullWidth: true, action: close)
        }
    }

    private var lifelineRow: String? {
        switch region {
        case "US": part(2)
        case "CA": OnbCopy.string("onb.s8.crisis_988_canada")
        default: nil
        }
    }

    private func part(_ index: Int) -> String {
        parts.indices.contains(index) ? parts[index] : ""
    }

    private func row(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Space.s3) {
                Image(systemName: systemImage)
                    .foregroundStyle(BedrockColor.emberGlow)
                    .accessibilityHidden(true)
                Text(title)
                    .font(BedrockFont.subhead.weight(.medium))
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(BedrockFont.footnote.weight(.semibold))
                    .foregroundStyle(BedrockColor.inkTertiary)
                    .accessibilityHidden(true)
            }
            .padding(Space.s4)
            .frame(minHeight: BedrockSize.textButtonHeight)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
        }
        .buttonStyle(PressOpacityStyle())
    }

    static var title: String { OnbCopy.parts("onb.s8.crisis_sheet").first ?? "" }
}

// MARK: - Preview tag

/// B9: “Preview” pinned under the Dynamic Island for the rest of the flow.
struct PreviewTag: View {
    var body: some View {
        Text(OnbCopy.string("onb.b9.tag"))
            .bedrockEyebrow(color: BedrockColor.emberGlow)
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s1)
            .background(Capsule().fill(BedrockColor.bgBase))
            .background(Capsule().fill(BedrockColor.emberWash))
            .overlay(Capsule().strokeBorder(BedrockColor.emberDeep))
            .accessibilityLabel(OnbCopy.string("onb.b9.a11y_tag"))
    }
}

// MARK: - Custom word field

/// S7's “My own word”: one word, letters only (any script), 14 characters,
/// trimmed and lower-cased for display. Pasting a phrase keeps the first word
/// and shows the error until it's one word.
struct CustomWordField: View {
    @Binding var text: String
    let placeholder: String
    let helper: String
    let error: String
    var focused: FocusState<Bool>.Binding

    var isValid: Bool { Self.validate(text) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            TextField(placeholder, text: $text)
                .focused(focused)
                .font(BedrockFont.body)
                .foregroundStyle(BedrockColor.inkPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.horizontal, Space.s4)
                .frame(minHeight: BedrockSize.chipMinHeight)
                .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
                .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(focused.wrappedValue ? BedrockColor.ember : BedrockColor.lineStrong, lineWidth: 1))
                .accessibilityLabel(OnbCopy.string("onb.s7.a11y_field"))
                .onChange(of: text) { _, new in
                    if new.count > BedrockSize.wordMaxLength { text = String(new.prefix(BedrockSize.wordMaxLength)) }
                }
            if showsError {
                Text(error)
                    .font(BedrockFont.footnote)
                    .foregroundStyle(BedrockColor.emberGlow)
            }
            Text(helper)
                .font(BedrockFont.footnote)
                .foregroundStyle(BedrockColor.inkTertiary)
        }
    }

    private var showsError: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty && !isValid
    }

    /// The word to keep, or nil if it isn't one word of letters.
    static func validate(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= BedrockSize.wordMaxLength,
              trimmed.unicodeScalars.allSatisfy({ CharacterSet.letters.contains($0) })
        else { return nil }
        return trimmed.lowercased()
    }
}
