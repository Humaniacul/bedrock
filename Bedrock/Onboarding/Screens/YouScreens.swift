import SwiftUI

// You · Hard hours, what's underneath, the word, the stone (SPEC.md S5–S8).
// Answers are stored by stable IDs; the chips show catalog strings in the same
// order, so a language change can't break them.

// MARK: - S5 · Hard hours

struct HardHoursScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @State private var selection: Set<String> = []

    private let options = OnbCopy.parts("onb.s5.chips")

    var body: some View {
        OnboardingScaffold(.s5, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s7) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s5.eyebrow"),
                              headline: OnbCopy.string("onb.s5.headline"),
                              text: OnbCopy.string("onb.s5.body"))
                VStack(alignment: .leading, spacing: Space.s4) {
                    ChoiceChipGrid(options: options, selection: $selection,
                                   exclusive: Set(options.suffix(1)))
                    PrivacyChip(text: OnbCopy.string("onb.s5.privacy"),
                                accessibilityText: OnbCopy.string("onb.common.a11y_privacy"))
                }
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s5.primary"), isEnabled: !selection.isEmpty,
                          disabledHint: OnbCopy.string("onb.common.pick_at_least_one")) {
                let hours = flow.state.hours
                flow.track(.hoursSubmitted(count: hours.filter { $0 != .noPattern }.count,
                                           noPattern: hours.contains(.noPattern)))
                flow.go(.s6)
            }
        }
        .onAppear {
            selection = Set(flow.state.hours.compactMap { Answers.label(for: $0, in: options) })
        }
        .onChange(of: selection) { _, new in
            let picked = Set(new.compactMap { Answers.value(for: $0, in: options, as: HourBand.self) })
            flow.update { $0.hours = Answers.keepingPickOrder($0.hours, picked) }
        }
    }
}

// MARK: - S6 · Underneath

struct UnderneathScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @State private var selection: Set<String> = []

    private let options = OnbCopy.parts("onb.s6.chips")

    var body: some View {
        OnboardingScaffold(.s6, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s7) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s6.eyebrow"),
                              headline: OnbCopy.string("onb.s6.headline"),
                              text: OnbCopy.string("onb.s6.body"))
                VStack(alignment: .leading, spacing: Space.s4) {
                    ChoiceChipGrid(options: options, selection: $selection,
                                   exclusive: Set(options.suffix(1)))
                    PrivacyChip(text: OnbCopy.string("onb.s6.privacy"),
                                accessibilityText: OnbCopy.string("onb.common.a11y_privacy"))
                }
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s6.primary"), isEnabled: !selection.isEmpty,
                          disabledHint: OnbCopy.string("onb.common.pick_at_least_one")) {
                let feelings = flow.state.feelings
                flow.track(.underneathSubmitted(count: feelings.filter { $0 != .notSure }.count,
                                                notSure: feelings.contains(.notSure)))
                flow.go(.s7)
            }
        }
        .onAppear {
            selection = Set(flow.state.feelings.compactMap { Answers.label(for: $0, in: options) })
        }
        .onChange(of: selection) { _, new in
            let picked = Set(new.compactMap { Answers.value(for: $0, in: options, as: Feeling.self) })
            flow.update { $0.feelings = Answers.keepingPickOrder($0.feelings, picked) }
        }
    }
}

/// Maps chip labels to stored answers by position in the catalog list.
enum Answers {
    static func label<T: CaseIterable & Equatable>(for value: T, in options: [String]) -> String? {
        guard let index = Array(T.allCases).firstIndex(of: value), options.indices.contains(index) else { return nil }
        return options[index]
    }

    static func value<T: CaseIterable>(for label: String, in options: [String], as type: T.Type) -> T? {
        guard let index = options.firstIndex(of: label) else { return nil }
        let all = Array(T.allCases)
        return all.indices.contains(index) ? all[index] : nil
    }

    /// The new selection, in the order it was picked (S8 reads the first ones).
    static func keepingPickOrder<T: CaseIterable & Hashable>(_ old: [T], _ picked: Set<T>) -> [T] {
        let kept = old.filter(picked.contains)
        let added = Array(T.allCases).filter { picked.contains($0) && !kept.contains($0) }
        return kept + added
    }
}

// MARK: - S7 · Your word

struct WordScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @State private var selection: Set<String> = []
    @State private var custom = ""
    @FocusState private var fieldFocused: Bool

    private let options = OnbCopy.parts("onb.s7.chips")
    private var ownWord: String { options.last ?? "" }
    private var choosingOwn: Bool { selection.contains(ownWord) }

    /// The word to keep: a preset (lower-cased) or a valid custom word.
    private var word: String? {
        if choosingOwn { return CustomWordField.validate(custom) }
        return selection.first?.lowercased()
    }

    var body: some View {
        OnboardingScaffold(.s7, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s7) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s7.eyebrow"),
                              headline: OnbCopy.string("onb.s7.headline"),
                              text: OnbCopy.string("onb.s7.body"))
                VStack(alignment: .leading, spacing: Space.s4) {
                    ChoiceChipGrid(options: options, selection: $selection, single: true)
                    if choosingOwn {
                        CustomWordField(text: $custom,
                                        placeholder: OnbCopy.string("onb.s7.field"),
                                        helper: OnbCopy.string("onb.s7.helper"),
                                        error: OnbCopy.string("onb.s7.error"),
                                        focused: $fieldFocused)
                            .transition(.scale(scale: 0.96, anchor: .top).combined(with: .opacity))
                            .onSubmit { if word != nil { save() } }
                    }
                    PrivacyChip(text: OnbCopy.string("onb.s7.privacy"),
                                accessibilityText: OnbCopy.string("onb.common.a11y_privacy"))
                }
                .animation(BedrockMotion.expand, value: choosingOwn)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s7.primary"), isEnabled: word != nil,
                          disabledHint: OnbCopy.string("onb.s7.error")) { save() }
        }
        .environment(\.onboardingScrollAnchor, choosingOwn ? .bottom : nil)
        .onAppear(perform: restore)
        .onChange(of: selection) { _, _ in fieldFocused = choosingOwn }
    }

    private func restore() {
        guard let saved = flow.state.word else { return }
        if flow.state.wordIsCustom {
            selection = [ownWord]
            custom = saved
        } else if let match = options.dropLast().first(where: { $0.lowercased() == saved }) {
            selection = [match]
        }
    }

    private func save() {
        guard let word else { return }
        fieldFocused = false
        flow.update {
            $0.word = word
            $0.wordIsCustom = choosingOwn
        }
        // The shield shows it in place of a lecture.
        AppGroup.defaults.set(word, forKey: AppGroup.Key.userWord)
        flow.track(.wordSubmitted(choosingOwn ? .custom : .preset))
        flow.go(.s8)
    }
}

// MARK: - S8 · Your stone

struct StoneScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isSet = false
    @State private var carving = false
    @State private var afterShown = false

    private var word: String { flow.state.word ?? "" }

    var body: some View {
        OnboardingScaffold(.s8, flow: flow, back: !isSet) {
            VStack(alignment: .leading, spacing: Space.s6) {
                VStack(alignment: .leading, spacing: Space.s2) {
                    Text(OnbCopy.string("onb.s8.eyebrow"))
                        .bedrockEyebrow()
                        .padding(.bottom, Space.s1)
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(BedrockFont.titleS)
                            .lineSpacing(BedrockLine.titleS.lineSpacing)
                            .foregroundStyle(index == 2 ? BedrockColor.inkPrimary : BedrockColor.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .bedrockAppear(.rise, delay: Double(index) * BedrockTiming.reflectionStagger)
                    }
                }
                .accessibilityElement(children: .combine)

                VStack(spacing: Space.s3) {
                    StoneView(word: word, day: 1,
                              phase: isSet ? .set(carve: carving) : .hovering,
                              size: dynamicTypeSize.isAccessibilitySize ? BedrockSize.stoneHome : BedrockSize.stoneRegular)
                    Text(OnbCopy.string("onb.s8.caption"))
                        .font(BedrockFont.footnote)
                        .foregroundStyle(BedrockColor.inkTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        } footer: {
            Group {
                if afterShown {
                    VStack(spacing: Space.s4) {
                        Text(OnbCopy.string("onb.s8.after"))
                            .font(BedrockFont.subhead)
                            .foregroundStyle(BedrockColor.inkSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        PrimaryButton(title: OnbCopy.string("onb.s8.primary")) { flow.afterStone() }
                    }
                    .bedrockAppear(.settle)
                } else if !isSet {
                    HoldToSetControl(label: OnbCopy.string("onb.s8.hold_label"),
                                     tapHint: OnbCopy.string("onb.s8.tap_hint"),
                                     fallbackTitle: OnbCopy.string("onb.s8.fallback")) { method, attempts in
                        set(method: method, attempts: attempts)
                    }
                } else {
                    // The set sequence plays; the footer keeps its height.
                    Color.clear.frame(height: BedrockSize.holdControl)
                }
            }
        } footerAccessory: {
            CrisisLink { flow.showsCrisis = true }
        }
        .onAppear {
            if flow.state.stoneSetAt != nil {
                isSet = true
                afterShown = true
            }
        }
    }

    /// The three reflection lines, from S5, S6 and S7.
    private var lines: [String] {
        [Reflection.hours(flow.state.hours),
         Reflection.feelings(flow.state.feelings),
         OnbCopy.string("onb.s8.line_3").replacingOccurrences(of: "{word}", with: word)]
    }

    private func set(method: StoneMethod, attempts: Int) {
        flow.update { $0.stoneSetAt = .now }
        flow.track(.stoneSet(method: method, attempts: attempts))
        carving = true
        isSet = true
        AccessibilityNotification.Announcement(OnbCopy.string("onb.s8.a11y_set")).post()
        Task {
            try? await Task.sleep(for: .seconds(reduceMotion ? BedrockMotion.reducedFadeDuration : BedrockTiming.stoneTextDelay))
            afterShown = true
        }
    }
}

/// S8's reflection, built from the answers (SPEC.md S8 › Line 1, Line 2).
enum Reflection {
    static func hours(_ bands: [HourBand]) -> String {
        let singles = OnbCopy.parts("onb.s8.hours")
        let picked = bands.filter { $0 != .noPattern }
        let index: (HourBand) -> Int = { HourBand.allCases.firstIndex(of: $0) ?? 0 }
        guard let first = picked.first else { return singles.last ?? "" }
        switch picked.count {
        case 1:
            return item(singles, index(first))
        case 2:
            return OnbCopy.string("onb.s8.hours_two")
                .replacingOccurrences(of: "{a}", with: item(OnbCopy.parts("onb.s8.hours_lead"), index(first)))
                .replacingOccurrences(of: "{b}", with: item(OnbCopy.parts("onb.s8.hours_tail"), index(picked[1])))
        default:
            return OnbCopy.string("onb.s8.hours_many")
                .replacingOccurrences(of: "{a}", with: item(OnbCopy.parts("onb.s8.hours_lead"), index(first)))
        }
    }

    static func feelings(_ feelings: [Feeling]) -> String {
        let words = OnbCopy.parts("onb.s8.feelings")
        let picked = feelings.filter { $0 != .notSure }
        let word: (Feeling) -> String = { item(words, Feeling.allCases.firstIndex(of: $0) ?? 0) }
        switch picked.count {
        case 0:
            return OnbCopy.string("onb.s8.feelings_not_sure")
        case 1:
            return OnbCopy.string("onb.s8.feelings_one").replacingOccurrences(of: "{a}", with: word(picked[0]))
        case 2:
            return OnbCopy.string("onb.s8.feelings_two")
                .replacingOccurrences(of: "{a}", with: word(picked[0]))
                .replacingOccurrences(of: "{b}", with: word(picked[1]))
        default:
            return OnbCopy.string("onb.s8.feelings_many")
                .replacingOccurrences(of: "{a}", with: word(picked[0]))
                .replacingOccurrences(of: "{b}", with: word(picked[1]))
                .replacingOccurrences(of: "{c}", with: word(picked[2]))
        }
    }

    private static func item(_ list: [String], _ index: Int) -> String {
        list.indices.contains(index) ? list[index] : ""
    }
}
