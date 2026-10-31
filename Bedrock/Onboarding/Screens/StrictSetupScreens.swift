import SwiftUI
import UIKit

// Begin · Strict Mode setup (SPEC.md S13.1–S13.7B, S13.2P). Phase 7 model: in
// both cases Bedrock holds a code typed blind into Screen Time; with a partner,
// the partner approves any release (and an unanswered request opens after 3
// days, server-side).

// MARK: - S13.1 · Write the letter

struct LetterScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var text = ""
    @State private var selection: TextSelection?
    @State private var folded = false
    @FocusState private var focused: Bool

    private static let minimum = 40
    private var canSave: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).count >= Self.minimum }

    var body: some View {
        OnboardingScaffold(.s13_1, flow: flow, back: flow.mode != .firstRun) {
            VStack(alignment: .leading, spacing: Space.s6) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s13_1.eyebrow"),
                              headline: OnbCopy.string("onb.s13_1.headline"),
                              text: OnbCopy.string("onb.s13_1.body"))
                starters
                editor
                    .scaleEffect(folded ? 0.2 : 1, anchor: .center)
                    .opacity(folded ? 0 : 1)
                    .overlay {
                        if folded {
                            Image(systemName: "envelope.fill")
                                .font(BedrockFont.title)
                                .foregroundStyle(BedrockColor.emberGlow)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                PrivacyChip(text: OnbCopy.string("onb.s13_1.privacy"))
            }
        } footer: {
            VStack(spacing: Space.s2) {
                PrimaryButton(title: OnbCopy.string("onb.s13_1.primary"), isEnabled: canSave,
                              disabledHint: OnbCopy.string("onb.s13_1.helper")) { save(text, defaultUsed: false) }
                TextButton(title: OnbCopy.string("onb.s13_1.secondary"), fullWidth: true) {
                    let letter = OnbCopy.string("onb.s13_1.default_letter")
                        .replacingOccurrences(of: "{word}", with: flow.state.word ?? "")
                    save(letter, defaultUsed: true)
                }
            }
        }
        .onAppear {
            text = flow.state.letterDraft
            if flow.state.history.last != ScreenID.s13_1.rawValue {
                flow.track(.strictSetupStarted((flow.state.keyHolder ?? .bedrock).analytics))
            }
        }
        .onChange(of: text) { _, new in flow.update { $0.letterDraft = new } }
        .environment(\.onboardingScrollAnchor, focused ? .bottom : nil)
    }

    private var starters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.s2) {
                ForEach(OnbCopy.parts("onb.s13_1.starters"), id: \.self) { starter in
                    Button { insert(starter) } label: {
                        Text(starter)
                            .font(BedrockFont.footnote.weight(.medium))
                            .foregroundStyle(BedrockColor.inkPrimary)
                            .padding(.horizontal, Space.s3)
                            .frame(minHeight: BedrockSize.textButtonHeight)
                            .background(Capsule().fill(BedrockColor.bgSurface))
                            .overlay(Capsule().strokeBorder(BedrockColor.lineStrong))
                    }
                    .buttonStyle(PressOpacityStyle())
                    .accessibilityLabel(OnbCopy.string("onb.s13_1.a11y_starter").replacingOccurrences(of: "{text}", with: starter))
                }
            }
        }
        .scrollClipDisabled()
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(OnbCopy.string("onb.s13_1.placeholder"))
                        .font(BedrockFont.body)
                        .foregroundStyle(BedrockColor.inkTertiary)
                        .padding(.horizontal, Space.s4 + 5)
                        .padding(.vertical, Space.s4 + 8)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $text, selection: $selection)
                    .focused($focused)
                    .font(BedrockFont.body)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(Space.s3)
                    .frame(minHeight: BedrockSize.letterMinHeight)
                    .accessibilityLabel(OnbCopy.string("onb.s13_1.a11y_letter"))
            }
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
            .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(focused ? BedrockColor.ember : BedrockColor.lineStrong, lineWidth: 1))
            Text(OnbCopy.string("onb.s13_1.helper"))
                .font(BedrockFont.footnote)
                .foregroundStyle(canSave ? BedrockColor.inkTertiary : BedrockColor.inkSecondary)
        }
    }

    /// Starter chips insert their text at the cursor.
    private func insert(_ starter: String) {
        BedrockHaptics.select()
        if case .selection(let range)? = selection?.indices,
           range.lowerBound >= text.startIndex, range.upperBound <= text.endIndex {
            let before = text[..<range.lowerBound]
            let spacer = before.isEmpty || before.hasSuffix(" ") || before.hasSuffix("\n") ? "" : " "
            text.replaceSubrange(range, with: spacer + starter + " ")
        } else {
            let spacer = text.isEmpty || text.hasSuffix(" ") || text.hasSuffix("\n") ? "" : " "
            text += spacer + starter + " "
        }
        focused = true
    }

    private func save(_ letter: String, defaultUsed: Bool) {
        focused = false
        BedrockHaptics.check()
        services.commitment.letter = letter
        flow.update {
            $0.letterSaved = true
            $0.letterDraft = letter
        }
        flow.track(.letterSaved(length: LengthBucket(characters: letter.count), defaultUsed: defaultUsed))
        let next: ScreenID = flow.state.keyHolder == .partner ? .s13_2p : .s13_2b
        if reduceMotion {
            flow.go(next)
            return
        }
        withAnimation(.easeIn(duration: BedrockTiming.letterFold)) { folded = true }
        Task {
            try? await Task.sleep(for: .seconds(BedrockTiming.letterFold + 0.15))
            flow.go(next)
        }
    }
}

// MARK: - S13.2B · How blind entry works

struct BlindEntryIntroScreen: View {
    @Environment(FirstLightFlow.self) private var flow

    var body: some View {
        OnboardingScaffold(.s13_2b, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s7) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s13_2b.eyebrow"),
                              headline: OnbCopy.string("onb.s13_2b.headline"))
                NumberedSteps(keys: (1...3).map { "onb.s13_2b.step_\($0)" }, staggered: true)
                Text(OnbCopy.string("onb.s13_2b.note"))
                    .font(BedrockFont.subhead)
                    .lineSpacing(3)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Space.s4)
                    .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(BedrockColor.lineStrong))
            }
        } footer: {
            VStack(spacing: Space.s2) {
                PrimaryButton(title: OnbCopy.string("onb.s13_2b.primary")) {
                    flow.track(.action(.practiceStarted))
                    flow.go(.s13_3b)
                }
                TextButton(title: OnbCopy.string("onb.s13_2b.secondary"), fullWidth: true) {
                    flow.track(.action(.practiceSkipped))
                    flow.go(.s13_4b)
                }
            }
        }
    }
}

/// A numbered list (S13.2B, S13.4B). iOS labels the person has to find are bold.
struct NumberedSteps: View {
    let keys: [String]
    var staggered = false
    /// Phrases to set in bold (the iOS labels on S13.4B).
    var bold: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                HStack(alignment: .firstTextBaseline, spacing: Space.s3) {
                    Text("\(index + 1)")
                        .font(BedrockFont.digits)
                        .foregroundStyle(BedrockColor.emberGlow)
                        .frame(width: BedrockSize.stepBadge, height: BedrockSize.stepBadge)
                        .background(Circle().fill(BedrockColor.emberWash))
                        .overlay(Circle().strokeBorder(BedrockColor.emberDeep))
                        .accessibilityHidden(true)
                    Text(emphasised(OnbCopy.string(key)))
                        .font(BedrockFont.body)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .modifier(StaggerIn(index: index, enabled: staggered))
            }
        }
    }

    private func emphasised(_ string: String) -> AttributedString {
        var attributed = AttributedString(string)
        for phrase in bold.sorted(by: { $0.count > $1.count }) {
            var searchRange = attributed.startIndex..<attributed.endIndex
            while let range = attributed[searchRange].range(of: phrase) {
                if attributed[range].inlinePresentationIntent == nil {
                    attributed[range].inlinePresentationIntent = .stronglyEmphasized
                    attributed[range].foregroundColor = BedrockColor.inkPrimary
                }
                searchRange = range.upperBound..<attributed.endIndex
            }
        }
        return attributed
    }
}

private struct StaggerIn: ViewModifier {
    let index: Int
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.bedrockAppear(.strata(index: index))
        } else {
            content
        }
    }
}

// MARK: - S13.3B · Practice run

struct PracticeScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var code: [Character] = Array(String(format: "%04d", Int.random(in: 0...9999)))
    @State private var step = 0          // 0–7: four digits, then the same four again
    @State private var progress: Double = 0
    @State private var digitVisible = true
    @State private var errors = 0
    @State private var wrongShown = false
    @State private var shake: CGFloat = 0
    @State private var done = false
    @State private var slowed = false

    private var perDigit: Double { flow.state.slowDigits ? BedrockTiming.digitDurationSlow : BedrockTiming.digitDuration }

    private var windowState: DigitWindowState {
        guard !done else { return .done }
        let index = step % code.count
        return digitVisible ? .digit(code[index], index: index, confirming: step >= code.count) : .between
    }

    var body: some View {
        OnboardingScaffold(.s13_3b, flow: flow) {
            VStack(spacing: Space.s5) {
                Group {
                    if done {
                        VStack(spacing: Space.s4) {
                            Image(systemName: "lock.fill")
                                .font(BedrockFont.title)
                                .foregroundStyle(BedrockColor.emberGlow)
                                .bedrockAppear(.settle)
                            Text(OnbCopy.string("onb.s13_3b.done_headline"))
                                .font(BedrockFont.title)
                                .foregroundStyle(BedrockColor.inkPrimary)
                                .accessibilityAddTraits(.isHeader)
                        }
                    } else {
                        Text(OnbCopy.string("onb.s13_3b.headline"))
                            .font(BedrockFont.title)
                            .lineSpacing(BedrockLine.title.lineSpacing)
                            .foregroundStyle(BedrockColor.inkPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                .frame(maxWidth: .infinity)

                if !done {
                    DigitWindowFace(state: windowState, progress: progress, practice: true, reduceMotion: reduceMotion)
                        .offset(x: shake)
                        .accessibilityHidden(true)
                    Text(OnbCopy.string("onb.s13_3b.wrong"))
                        .font(BedrockFont.subhead)
                        .foregroundStyle(BedrockColor.emberGlow)
                        .opacity(wrongShown ? 1 : 0)
                        .accessibilityHidden(!wrongShown)
                    PracticeKeypad { typed($0) }
                }
            }
        } footer: {
            if done {
                VStack(spacing: Space.s2) {
                    PrimaryButton(title: OnbCopy.string("onb.s13_3b.primary")) { flow.go(.s13_4b) }
                    if errors >= 3 && !flow.state.slowDigits {
                        TextButton(title: OnbCopy.string("onb.s13_3b.slow"), fullWidth: true) {
                            flow.update { $0.slowDigits = true }
                            flow.toast = OnbCopy.string("onb.s13_3b.slow_toast")
                        }
                    }
                }
                .bedrockAppear(.settle)
            }
        }
        .task(id: step) { await showDigit() }
    }

    /// Each digit shows for 3 seconds (5 when slowed) or until typed. Missed:
    /// counts as an error and shows again.
    private func showDigit() async {
        guard !done else { return }
        if step == 0 && errors == 0 && progress == 0 {
            // A beat to read the screen before the first digit's clock starts.
            digitVisible = false
            try? await Task.sleep(for: .seconds(BedrockTiming.practiceLeadIn))
            guard !Task.isCancelled else { return }
        }
        digitVisible = true
        progress = 0
        let index = step % code.count
        AccessibilityNotification.Announcement(
            BlindEntrySession.spoken(code[index], index: index, confirming: step >= code.count, practice: true)).post()
        let started = Date.now
        while !Task.isCancelled {
            let elapsed = Date.now.timeIntervalSince(started)
            progress = min(elapsed / perDigit, 1)
            if elapsed >= perDigit { break }
            try? await Task.sleep(for: .milliseconds(50))
        }
        guard !Task.isCancelled else { return }
        // Not typed in time: it counts toward slowing the real run, and the
        // same digit shows again. No error copy: nothing was typed wrong.
        errors += 1
        progress = 0
        // Show the same digit again.
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }
        await showDigit()
    }

    private func typed(_ digit: Character) {
        guard !done else { return }
        let expected = code[step % code.count]
        guard digit == expected else {
            miss()
            return
        }
        wrongShown = false
        if !reduceMotion {
            withAnimation(BedrockMotion.digitSlide) { digitVisible = false }
        }
        if step + 1 >= code.count * 2 {
            finish()
        } else {
            step += 1
        }
    }

    private func miss() {
        errors += 1
        BedrockHaptics.wrongDigit()
        wrongShown = true
        AccessibilityNotification.Announcement(OnbCopy.string("onb.s13_3b.wrong")).post()
        guard !reduceMotion else { return }
        withAnimation(BedrockMotion.shake) { shake = 0 }
        Task {
            for offset in [-10.0, 10, -6, 6, 0] {
                withAnimation(.linear(duration: 0.06)) { shake = offset }
                try? await Task.sleep(for: .milliseconds(60))
            }
        }
    }

    private func finish() {
        done = true
        BedrockHaptics.purchased()
        flow.update { $0.practiceDone = true }
        flow.track(.practiceCompleted(errors: errors))
    }
}

// MARK: - S13.4B · The real run

struct RealRunScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var runner: BlindEntryRunner?

    var body: some View {
        OnboardingScaffold(.s13_4b, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s6) {
                ScreenHeading(headline: OnbCopy.string("onb.s13_4b.headline"),
                              text: OnbCopy.string(runner?.style == .appSwitching
                                                   ? "onb.s13_4b.fallback_body" : "onb.s13_4b.body"))
                if let runner { DigitWindowStage(runner: runner, reduceMotion: reduceMotion, start: begin) }
                NumberedSteps(keys: (1...7).map { "onb.s13_4b.step_\($0)" }, bold: iOSLabels)
                Text(OnbCopy.string("onb.s13_4b.note"))
                    .font(BedrockFont.footnote)
                    .foregroundStyle(BedrockColor.inkTertiary)
            }
        } footer: {
            if let runner { BlindEntryFooter(runner: runner, primary: OnbCopy.string("onb.s13_4b.primary"), begin: begin) }
        }
        .onAppear(perform: prepare)
        .onDisappear { runner?.tearDown() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, let runner else { return }
            if runner.returned() { finished() }
        }
        .onChange(of: runner?.session.isDone) { _, done in
            // App switching and preview finish inside Bedrock.
            guard done == true, let runner, runner.style != .pictureInPicture else { return }
            runner.markFinished()
            finished()
        }
    }

    /// The code is written to the Keychain before the first digit shows and is
    /// never replaced until S13.5A passes or fails; a fresh one only on S13.7B.
    private func prepare() {
        guard runner == nil else { return }
        let code: String
        if flow.state.realRunStarted, let stored = services.passcode.storedCode() {
            code = stored
        } else {
            code = services.passcode.generateCode()
        }
        let runner = BlindEntryRunner(code: code, slow: flow.state.slowDigits, passes: 2,
                                      preview: flow.state.previewMode)
        runner.session.onStep = { step in flow.track(.blindEntryWindow(step)) }
        runner.onPaused = { reason in flow.track(.blindEntryPaused(reason)) }
        self.runner = runner
    }

    private func begin() {
        guard let runner else { return }
        if !flow.state.realRunStarted {
            flow.update { $0.realRunStarted = true }
            flow.track(.blindEntryStarted)
        }
        runner.open()
    }

    private func finished() {
        flow.track(.blindEntryReturned)
        flow.go(.s13_5a)
    }

    private var iOSLabels: [String] { OnbCopy.parts("onb.s13_4b.ios_labels") }
}

/// The digit window inside Bedrock: the PiP source on S13.4B/S13.5A (“Tap to
/// start” until it floats), or the digits themselves when switching apps.
private struct DigitWindowStage: View {
    let runner: BlindEntryRunner
    let reduceMotion: Bool
    let start: () -> Void

    var body: some View {
        ZStack {
            if let pip = runner.pictureInPicture {
                // PiP needs its source layer on screen; it shows the same face.
                PictureInPictureHost(pip: pip)
                    .frame(width: BedrockSize.digitWindow.width, height: BedrockSize.digitWindow.height)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
            DigitWindowFace(state: runner.session.state, progress: runner.session.progress,
                            reduceMotion: reduceMotion)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        // “Tap to start” in Bedrock does what the button does.
        .onTapGesture { if runner.phase == .ready && !runner.session.hasStarted { start() } }
        .accessibilityHidden(true)
    }
}

/// S13.4B / S13.5A footer: start, or (app switching) “Switch to Settings”.
private struct BlindEntryFooter: View {
    let runner: BlindEntryRunner
    let primary: String
    /// S13.5A already has its ember action (“iOS accepted it”): this one is quiet.
    var secondary = false
    let begin: () -> Void

    private var busy: Bool {
        runner.phase == .starting || (runner.session.isRunning && runner.style != .pictureInPicture)
    }

    var body: some View {
        if runner.style == .appSwitching && runner.session.state == .between {
            button(OnbCopy.string("onb.s13_4b.fallback_switch")) { runner.switchToSettings() }
        } else {
            button(primary) { begin() }
                .disabled(busy)
                .opacity(busy && secondary ? BedrockMotion.pressedOpacity : 1)
        }
    }

    @ViewBuilder private func button(_ title: String, action: @escaping () -> Void) -> some View {
        if secondary {
            TextButton(title: title, fullWidth: true, action: action)
                .overlay(Capsule().strokeBorder(BedrockColor.lineStrong))
        } else {
            PrimaryButton(title: title, isLoading: busy, action: action)
        }
    }
}

// MARK: - S13.5A · Check the code

struct CodeCheckScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var runner: BlindEntryRunner?

    var body: some View {
        OnboardingScaffold(.s13_5a, flow: flow, back: flow.mode != .firstRun) {
            VStack(alignment: .leading, spacing: Space.s6) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s13_5a.eyebrow"),
                              headline: OnbCopy.string("onb.s13_5a.headline"),
                              text: OnbCopy.string("onb.s13_5a.body"))
                if let runner {
                    DigitWindowStage(runner: runner, reduceMotion: reduceMotion) { runner.open() }
                    BlindEntryFooter(runner: runner, primary: OnbCopy.string("onb.s13_4b.show_digits"),
                                     secondary: true) { runner.open() }
                }
            }
        } footer: {
            VStack(spacing: Space.s2) {
                PrimaryButton(title: OnbCopy.string("onb.s13_5a.primary")) {
                    BedrockHaptics.check()
                    flow.track(.codeCheck(.passed))
                    flow.go(.s13_5b)
                }
                .accessibilityHint(OnbCopy.string("onb.s13_5a.a11y_primary"))
                TextButton(title: OnbCopy.string("onb.s13_5a.secondary"), fullWidth: true) {
                    flow.track(.codeCheck(.failed))
                    flow.update { $0.codeMismatches += 1 }
                    flow.track(.codeMismatch(attempt: flow.state.codeMismatches))
                    flow.go(.s13_7a)
                }
            }
        }
        .onAppear(perform: prepare)
        .onDisappear { runner?.tearDown() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            runner?.returned()
        }
        .onChange(of: runner?.session.isDone) { _, done in
            if done == true, runner?.style != .pictureInPicture { runner?.markFinished() }
        }
    }

    private func prepare() {
        guard runner == nil else { return }
        let code = services.passcode.storedCode() ?? services.passcode.generateCode()
        runner = BlindEntryRunner(code: code, slow: flow.state.slowDigits, passes: 1,
                                  preview: flow.state.previewMode)
    }
}

// MARK: - S13.5B · Try to switch it off

struct SwitchOffScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.openURL) private var openURL
    @State private var stuckShown = false

    var body: some View {
        OnboardingScaffold(.s13_5b, flow: flow, back: false) {
            ScreenHeading(headline: OnbCopy.string("onb.s13_5b.headline"),
                          text: OnbCopy.string("onb.s13_5b.body"))
        } footer: {
            VStack(spacing: Space.s2) {
                PrimaryButton(title: OnbCopy.string("onb.s13_5b.primary")) { asked() }
                TextButton(title: OnbCopy.string("onb.s13_5b.secondary"), fullWidth: true) {
                    flow.track(.lockCheck(.switchedOff))
                    notSaved()
                }
            }
        } footerAccessory: {
            LinkButton(title: OnbCopy.string("onb.s13_5b.link")) {
                flow.track(.action(.stuckOpened))
                stuckShown = true
            }
        }
        .bedrockSheet(isPresented: $stuckShown, title: OnbCopy.string("onb.s13_5b.link")) {
            stuckSheet
        }
    }

    private var stuckSheet: some View {
        let parts = OnbCopy.parts("onb.s13_5b.stuck_sheet")
        return VStack(alignment: .leading, spacing: Space.s4) {
            ForEach(Array(parts.dropLast().enumerated()), id: \.offset) { _, row in
                Text(row)
                    .font(BedrockFont.body)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let url = Support.mailURL(subject: OnbCopy.string("onb.s13_5b.link")) {
                TextButton(title: Support.email, fullWidth: true) { openURL(url) }
            }
            PrimaryButton(title: parts.last ?? "") { stuckShown = false }
        }
    }

    private func asked() {
        // Backstop: if Screen Time access was revoked anyway, the lock didn't hold.
        services.blocking.refreshAuthState()
        if !flow.state.previewMode && services.blocking.authState != .approved {
            flow.track(.lockCheck(.switchedOff))
            notSaved()
            return
        }
        flow.track(.lockCheck(.asked))
        seal()
        flow.go(.s13_6)
    }

    private func notSaved() {
        flow.update { $0.lockFailures += 1 }
        flow.track(.lockNotSaved(attempt: flow.state.lockFailures))
        flow.go(.s13_7b)
    }

    /// Strict Mode on: the code is Bedrock's, the uninstall lock is set, the
    /// gauntlet is armed. With a partner, they approve any release.
    private func seal() {
        services.strictMode.enable(model: .appHeld)
        flow.update {
            $0.strictSealed = true
            $0.realRunStarted = false
        }
    }
}

// MARK: - S13.6 · Sealed

struct SealedScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var keystone: WallView.Keystone = .hovering
    @State private var warm = false
    @State private var headlineShown = false

    var body: some View {
        OnboardingScaffold(.s13_6, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s8) {
                Spacer(minLength: 0)
                WallView(web: .landed, apps: nil, schedule: .landed, keystone: keystone)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 0) {
                    Text(OnbCopy.string("onb.s13_6.eyebrow"))
                        .bedrockEyebrow()
                        .padding(.bottom, Space.s3)
                    if headlineShown {
                        CarveText(OnbCopy.string("onb.s13_6.headline"), font: BedrockFont.displayXL)
                            .foregroundStyle(warm ? BedrockColor.emberGlow : BedrockColor.inkPrimary)
                            .animation(BedrockMotion.ember, value: warm)
                            .accessibilityAddTraits(.isHeader)
                    } else {
                        Text(OnbCopy.string("onb.s13_6.headline"))
                            .font(BedrockFont.displayXL)
                            .hidden()
                    }
                    Text(OnbCopy.string(flow.state.keyHolder == .partner ? "onb.s13_6.body_b" : "onb.s13_6.body_a"))
                        .font(BedrockFont.body)
                        .lineSpacing(BedrockLine.body.lineSpacing)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Space.s4)
                }
                Spacer(minLength: 0)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s13_6.primary")) { flow.afterSealed() }
        }
        .environment(\.onboardingFillsHeight, true)
        .task {
            flow.track(.strictSealed((flow.state.keyHolder ?? .bedrock).analytics))
            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(reduceMotion ? nil : BedrockMotion.lock) { keystone = .set }
            BedrockHaptics.lock()
            try? await Task.sleep(for: .seconds(0.2))
            headlineShown = true
            flow.dawnOverride = Dawn.level(for: .s15)
            AccessibilityNotification.Announcement(OnbCopy.string("onb.s13_6.a11y")).post()
            try? await Task.sleep(for: .seconds(0.5))
            warm = true
        }
    }
}

// MARK: - S13.7A · The code didn't match

struct CodeMismatchScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(\.openURL) private var openURL

    /// Still no match after two slow tries: Get help leads.
    private var helpFirst: Bool { flow.state.codeMismatches >= 3 }

    var body: some View {
        OnboardingScaffold(.s13_7a, flow: flow, back: false) {
            ScreenHeading(headline: OnbCopy.string("onb.s13_7a.headline"),
                          text: OnbCopy.string("onb.s13_7a.body"))
        } footer: {
            VStack(spacing: Space.s2) {
                if helpFirst {
                    PrimaryButton(title: OnbCopy.string("onb.s13_7a.secondary")) { help() }
                    TextButton(title: OnbCopy.string("onb.s13_7a.primary"), fullWidth: true) { again() }
                } else {
                    PrimaryButton(title: OnbCopy.string("onb.s13_7a.primary")) { again() }
                    TextButton(title: OnbCopy.string("onb.s13_7a.secondary"), fullWidth: true) { help() }
                }
            }
        }
    }

    private func again() {
        flow.update { $0.slowDigits = true }
        flow.go(.s13_5a)
    }

    private func help() {
        flow.track(.action(.help))
        let reference = String(UUID().uuidString.prefix(8))
        let subject = OnbCopy.string("onb.s13_7a.mail_subject").replacingOccurrences(of: "{ref}", with: reference)
        if let url = Support.mailURL(subject: subject) { openURL(url) }
    }
}

// MARK: - S13.7B · The lock didn't save

struct LockNotSavedScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @State private var working = false

    var body: some View {
        OnboardingScaffold(.s13_7b, flow: flow, back: false) {
            if RemoteConfig.strictModeSupported {
                ScreenHeading(headline: OnbCopy.string("onb.s13_7b.headline"),
                              text: OnbCopy.string("onb.s13_7b.body"))
            } else {
                // An unverified iOS that slipped through: say so instead.
                ScreenHeading(eyebrow: OnbCopy.string("onb.s12u.eyebrow"),
                              headline: OnbCopy.string("onb.s12u.headline"),
                              text: OnbCopy.string("onb.s12u.body"))
            }
        } footer: {
            if RemoteConfig.strictModeSupported {
                PrimaryButton(title: OnbCopy.string("onb.s13_7b.primary"), isLoading: working) {
                    Task { await runAgain() }
                }
            } else {
                PrimaryButton(title: OnbCopy.string("onb.s12u.secondary")) {
                    flow.update { $0.paywallOutcome = .waitingForUpdate }
                    flow.afterSealed()
                }
            }
        }
    }

    /// Re-grant Screen Time if it was revoked, make a fresh code, run it again.
    private func runAgain() async {
        working = true
        services.blocking.refreshAuthState()
        if !flow.state.previewMode && services.blocking.authState != .approved {
            try? await services.blocking.requestAuthorization()
        }
        services.passcode.generateCode()
        flow.update { $0.realRunStarted = true }
        working = false
        flow.go(.s13_4b)
    }
}

// MARK: - S13.2P · Invite your person

struct InviteScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services

    @State private var loading = false
    @State private var failed = false
    @State private var shareShown = false

    private var code: String? { flow.state.inviteCode }
    private var link: String? { flow.state.inviteURL }

    var body: some View {
        OnboardingScaffold(.s13_2p, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s6) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s13_2p.eyebrow"),
                              headline: OnbCopy.string("onb.s13_2p.headline"),
                              text: OnbCopy.string("onb.s13_2p.body"))
                inviteCard
                Text(OnbCopy.string("onb.s13_2p.note"))
                    .font(BedrockFont.subhead)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Space.s4)
                    .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(BedrockColor.lineStrong))
            }
        } footer: {
            VStack(spacing: Space.s2) {
                if failed {
                    PrimaryButton(title: OnbCopy.parts("onb.s13_2p.offline").last ?? "", isLoading: loading) {
                        Task { await load() }
                    }
                } else {
                    PrimaryButton(title: OnbCopy.string("onb.s13_2p.primary"), isEnabled: link != nil, isLoading: loading) {
                        shareShown = true
                    }
                    TextButton(title: OnbCopy.string("onb.s13_2p.secondary"), fullWidth: true) { copy() }
                        .disabled(link == nil)
                }
            }
        } footerAccessory: {
            if failed || link == nil {
                // Until they accept, the steps work on their own: this never blocks setup.
                TextButton(title: OnbCopy.string("onb.s13_2p.later")) { flow.go(.s13_2b) }
            }
        }
        .sheet(isPresented: $shareShown) {
            ActivityView(items: [shareMessage]) { completed in
                shareShown = false
                guard completed else { return }
                BedrockHaptics.check()
                flow.track(.partnerInvite(.shared))
                flow.update { $0.inviteSentAt = .now }
                flow.go(.s13_2b)
            }
            .presentationDetents([.medium, .large])
        }
        .task { if code == nil { await load() } }
    }

    private var inviteCard: some View {
        let parts = OnbCopy.parts("onb.s13_2p.card")
        return VStack(alignment: .leading, spacing: Space.s2) {
            Text(parts.first ?? "")
                .bedrockEyebrow()
            if let code {
                Text(code)
                    .font(BedrockFont.digitHero)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .textSelection(.enabled)
                    .accessibilityLabel(code.map { String($0) }.joined(separator: " "))
                if let link {
                    Text(link)
                        .font(BedrockFont.footnote)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .textSelection(.enabled)
                }
            } else if failed {
                Text(OnbCopy.parts("onb.s13_2p.offline").first ?? "")
                    .font(BedrockFont.subhead)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ProgressView().tint(BedrockColor.inkSecondary)
            }
        }
        .padding(Space.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(BedrockColor.bgRaised))
    }

    private var shareMessage: String {
        OnbCopy.string("onb.s13_2p.share_message").replacingOccurrences(of: "{link}", with: link ?? "")
    }

    private func load() async {
        loading = true
        failed = false
        if let invite = await services.accountability.createInvite() {
            flow.update {
                $0.inviteCode = invite.code
                $0.inviteURL = invite.url
            }
        } else {
            failed = true
        }
        loading = false
    }

    private func copy() {
        guard let link else { return }
        UIPasteboard.general.string = link
        flow.toast = OnbCopy.string("onb.s13_2p.toast")
        flow.track(.partnerInvite(.copied))
        flow.update { $0.inviteSentAt = .now }
    }
}

/// The share sheet, with a completion so S13.2P can move on after sending.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in onComplete(completed) }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
