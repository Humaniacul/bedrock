import SwiftUI

// Small, repeated pieces of onboarding screens, as the prototype draws them.

// MARK: - Heading

/// Eyebrow (12pt under it), headline (16pt under it), body. Most screens.
struct ScreenHeading: View {
    var eyebrow: String?
    var eyebrowColor: Color = BedrockColor.inkTertiary
    let headline: String
    var headlineType: PType = .title
    var headlineGap: CGFloat = Space.s4
    var text: String?
    var textType: PType = .body
    /// Carve the headline in (S1, “You're in.”, S13.6, Home, SP1).
    var carves = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let eyebrow {
                Eyebrow(text: eyebrow, color: eyebrowColor)
                    .padding(.bottom, Space.s3)
            }
            Group {
                if carves {
                    CarveText(headline, font: .body).ptype(headlineType)
                } else {
                    Text(headline).ptype(headlineType)
                }
            }
            .foregroundStyle(BedrockColor.inkPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            if let text {
                Text(text)
                    .ptype(textType)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, headlineGap)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Mono 11pt medium, +2, uppercase.
struct Eyebrow: View {
    let text: String
    var color: Color = BedrockColor.inkTertiary

    var body: some View {
        Text(text)
            .ptype(.eyebrow)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Privacy note

/// “Stays on this iPhone” with an outlined lock: 14pt Ash, 8pt gap.
struct PrivacyChip: View {
    let text: String
    var accessibilityText: String?

    var body: some View {
        HStack(spacing: Space.s2) {
            LockOutline()
            Text(text)
                .ptype(.notePlain)
                .foregroundStyle(BedrockColor.inkTertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText ?? text)
    }
}

// MARK: - Crisis

/// The quiet link to support resources (S8 after setting, S12, S15).
struct CrisisLink: View {
    var type: PType = .notePlain
    var height: CGFloat = BedrockSize.linkHitHeight
    let action: () -> Void

    var body: some View {
        LinkButton(title: OnbCopy.string("onb.s8.crisis_link"), tone: .tertiary, type: type, height: height, action: action)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(OnbCopy.string("onb.s8.a11y_crisis_link"))
    }
}

/// Region-aware support resources. 988 only where it works (US, Canada);
/// elsewhere “Find a helpline in your country” comes first. Rows in a raised
/// group, then the emergency line, then Close.
struct CrisisSheetContent: View {
    let close: () -> Void

    @Environment(\.openURL) private var openURL

    /// onb.s8.crisis_sheet: title · body · 988 (US) · helpline · emergency · Close
    private var parts: [String] { OnbCopy.parts("onb.s8.crisis_sheet") }
    private var region: String? { Locale.current.region?.identifier }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(part(1))
                .ptype(.body)
                .foregroundStyle(BedrockColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Space.s5)
            VStack(spacing: 0) {
                if let lifeline {
                    row(lifeline) { openURL(URL(string: "tel:988")!) }
                    Rectangle().fill(BedrockColor.lineStrong).frame(height: 1)
                }
                row(split(part(3))) { openURL(URL(string: "https://findahelpline.com")!) }
            }
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(BedrockColor.bgRaised))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(part(4))
                .ptype(PType(face: .sans, size: 15, line: 21, relativeTo: .subheadline))
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.s4)
                .padding(.bottom, 22)
            SheetButton(title: part(5), action: close)
        }
    }

    /// “Call or text 988 (Suicide & Crisis Lifeline, US)” → title and detail.
    private var lifeline: (String, String)? {
        switch region {
        case "US": split(part(2))
        case "CA": split(OnbCopy.string("onb.s8.crisis_988_canada"))
        default: nil
        }
    }

    private func split(_ line: String) -> (String, String) {
        guard let open = line.firstIndex(of: "("), let close = line.lastIndex(of: ")"), open < close else { return (line, "") }
        return (String(line[..<open]).trimmingCharacters(in: .whitespaces),
                String(line[line.index(after: open)..<close]))
    }

    private func part(_ index: Int) -> String {
        parts.indices.contains(index) ? parts[index] : ""
    }

    private func row(_ text: (String, String), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Space.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(text.0)
                        .ptype(.rowTitle)
                        .foregroundStyle(BedrockColor.inkPrimary)
                    if !text.1.isEmpty {
                        Text(text.1)
                            .ptype(.notePlain)
                            .foregroundStyle(BedrockColor.inkSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ProtoIcon.chevronRight
                    .stroke(BedrockColor.inkTertiary, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .frame(width: 8, height: 14)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Space.s4)
            .padding(.vertical, 10)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressOpacityStyle())
    }

    static var title: String { OnbCopy.parts("onb.s8.crisis_sheet").first ?? "" }
}

// MARK: - Preview tag

/// B9: “PREVIEW” under the Dynamic Island for the rest of the flow.
struct PreviewTag: View {
    var body: some View {
        Text(OnbCopy.string("onb.b9.tag"))
            .ptype(.previewTag)
            .textCase(.uppercase)
            .foregroundStyle(BedrockColor.inkPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(Capsule().fill(BedrockColor.emberDeep))
            .dynamicTypeSize(...DynamicTypeSize.large)
            .accessibilityLabel(OnbCopy.string("onb.b9.a11y_tag"))
    }
}

// MARK: - Custom word field

/// S7's “My own word”: 52pt, ember edge, raised fill, 17pt. One word, letters
/// only (any script), 14 characters, trimmed and lower-cased for display.
struct CustomWordField: View {
    @Binding var text: String
    let placeholder: String
    let helper: String
    let error: String
    var focused: FocusState<Bool>.Binding

    var isValid: Bool { Self.validate(text) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(BedrockColor.inkTertiary))
                .focused(focused)
                .ptype(PType(face: .sans, size: 17, line: nil))
                .foregroundStyle(BedrockColor.inkPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.horizontal, Space.s4)
                .frame(minHeight: BedrockSize.chipMinHeight)
                .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
                .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(BedrockColor.ember, lineWidth: 1.5))
                .accessibilityLabel(OnbCopy.string("onb.s7.a11y_field"))
                .onChange(of: text) { _, new in
                    if new.count > BedrockSize.wordMaxLength { text = String(new.prefix(BedrockSize.wordMaxLength)) }
                }
            if showsError {
                Text(error)
                    .ptype(.footnotePlain)
                    .foregroundStyle(BedrockColor.emberGlow)
            }
            Text(helper)
                .ptype(.footnotePlain)
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
