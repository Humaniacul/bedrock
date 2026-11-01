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

    @State private var text = ""
    @State private var selection: TextSelection?
    @FocusState private var focused: Bool

    private static let minimum = 40
    private var canSave: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).count >= Self.minimum }

    var body: some View {
        OnboardingScaffold(.s13_1, flow: flow, back: flow.mode != .firstRun, bottom: ProtoLayout.bottomTight) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: OnbCopy.string("onb.s13_1.eyebrow"))
                    .padding(.bottom, Space.s3)
                ScreenHeading(headline: OnbCopy.string("onb.s13_1.headline"), headlineType: .titleM,
                              headlineGap: Space.s3,
                              text: OnbCopy.string("onb.s13_1.body"), textType: .bodyM)
                    .padding(.bottom, Space.s4)
                starters
                    .padding(.bottom, 10)
                editor
                HStack(alignment: .top) {
                    Text(OnbCopy.string("onb.s13_1.helper"))
                    Spacer(minLength: Space.s3)
                    Text(OnbCopy.string("onb.s13_1.privacy"))
                        .multilineTextAlignment(.trailing)
                }
                .ptype(.footnotePlain)
                .foregroundStyle(BedrockColor.inkTertiary)
                .padding(.top, Space.s2)
                .padding(.bottom, 14 - Space.s2)
            }
        } footer: {
            VStack(spacing: ProtoLayout.buttonGap) {
                PrimaryButton(title: OnbCopy.string("onb.s13_1.primary"), isEnabled: canSave,
                              disabledHint: OnbCopy.string("onb.s13_1.helper")) { save(text, defaultUsed: false) }
                TextButton(title: OnbCopy.string("onb.s13_1.secondary")) {
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

    /// Three starters that wrap: 34pt Basalt pills, 13pt Chalk.
    private var starters: some View {
        FlowLayout(spacing: Space.s2) {
            ForEach(OnbCopy.parts("onb.s13_1.starters"), id: \.self) { starter in
                Button { insert(starter) } label: {
                    Text(starter)
                        .ptype(.footnotePlain)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, Space.s3)
                        .padding(.vertical, Space.s1)
                        .frame(minHeight: 34)
                        .background(RoundedRectangle(cornerRadius: 17, style: .continuous).fill(BedrockColor.bgSurface))
                        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
                        .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .buttonStyle(PressOpacityStyle())
                .accessibilityLabel(OnbCopy.string("onb.s13_1.a11y_starter").replacingOccurrences(of: "{text}", with: starter))
            }
        }
    }

    /// The letter: Slate, radius 14, a Fault edge, serif 20/27; it takes the
    /// height that's left (at least 150pt).
    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(OnbCopy.string("onb.s13_1.placeholder"))
                    .ptype(.letter)
                    .foregroundStyle(BedrockColor.inkTertiary)
                    .padding(.horizontal, Space.s4)
                    .padding(.vertical, 14)
                    .accessibilityHidden(true)
            }
            TextEditor(text: $text, selection: $selection)
                .focused($focused)
                .ptype(.letter)
                .foregroundStyle(BedrockColor.inkPrimary)
                .scrollContentBackground(.hidden)
                .contentMargins(.horizontal, Space.s4 - 5, for: .scrollContent)
                .contentMargins(.vertical, 14 - 8, for: .scrollContent)
                .accessibilityLabel(OnbCopy.string("onb.s13_1.a11y_letter"))
        }
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgRaised))
        .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            .strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
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
        flow.go(flow.state.keyHolder == .partner ? .s13_2p : .s13_2b)
    }
}

// MARK: - S13.2B · How blind entry works

struct BlindEntryIntroScreen: View {
    @Environment(FirstLightFlow.self) private var flow

    var body: some View {
        OnboardingScaffold(.s13_2b, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: OnbCopy.string("onb.s13_2b.eyebrow"))
                    .padding(.bottom, Space.s3)
                Text(OnbCopy.string("onb.s13_2b.headline"))
                    .ptype(.titleM)
                    .foregroundStyle(BedrockColor.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 20)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(1...3, id: \.self) { n in
                        HStack(alignment: .top, spacing: Space.s3) {
                            Text(verbatim: "\(n)")
                                .ptype(.stepNumeral)
                                .foregroundStyle(BedrockColor.ember)
                                .frame(width: 32, alignment: .leading)
                                .accessibilityHidden(true)
                            Text(OnbCopy.string("onb.s13_2b.step_\(n)"))
                                .ptype(.bodyM)
                                .foregroundStyle(BedrockColor.inkPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        .bedrockAppear(.strata(index: n - 1))
                    }
                }
                .padding(.bottom, 18)
                Text(OnbCopy.string("onb.s13_2b.note"))
                    .ptype(.note)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.s4)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.bgSurface))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(BedrockColor.lineSubtle, lineWidth: 1))
            }
        } footer: {
            VStack(spacing: ProtoLayout.buttonGap) {
                PrimaryButton(title: OnbCopy.string("onb.s13_2b.primary")) {
                    flow.track(.action(.practiceStarted))
                    flow.go(.s13_3b)
                }
                TextButton(title: OnbCopy.string("onb.s13_2b.secondary")) {
                    flow.track(.action(.practiceSkipped))
                    flow.go(.s13_4b)
                }
            }
        }
    }
}

// MARK: - S13.3B · Practice run

/// A practice code typed on a Bedrock keypad. Each digit waits until it's
/// typed; a wrong one shakes the dots. Then all four again.
struct PracticeScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var code: [Character] = Array(String(format: "%04d", Int.random(in: 0...9999)))
    @State private var step = 0          // 0–7: four digits, then the same four again
    @State private var errors = 0
    @State private var shake: CGFloat = 0
    @State private var done = false

    private var windowState: DigitWindowState {
        let index = step % code.count
        return .digit(code[index], index: index, confirming: step >= code.count)
    }

    var body: some View {
        OnboardingScaffold(.s13_3b, flow: flow, back: false, bottom: ProtoLayout.bottomTight) {
            if done {
                VStack(spacing: 18) {
                    Spacer(minLength: 0)
                    ProtoIcon.check
                        .stroke(BedrockColor.emberGlow, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 22, height: 22)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(BedrockColor.emberWash))
                        .overlay(Circle().strokeBorder(BedrockColor.ember, lineWidth: 1.5))
                        .bedrockAppear(.settle)
                        .accessibilityHidden(true)
                    Text(OnbCopy.string("onb.s13_3b.done_headline"))
                        .ptype(.doneTitle)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    Text(OnbCopy.string("onb.s13_3b.headline"))
                        .ptype(.practiceTitle)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.bottom, 18)
                    DigitWindowFace(state: windowState, style: .practice)
                        .accessibilityHidden(true)
                    HStack(spacing: 14) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index < step % code.count ? BedrockColor.inkPrimary : .clear)
                                .overlay(Circle().strokeBorder(BedrockColor.inkTertiary, lineWidth: 1.5))
                                .frame(width: 14, height: 14)
                        }
                    }
                    .offset(x: shake)
                    .padding(.top, 22)
                    .padding(.bottom, 18)
                    .accessibilityHidden(true)
                    PracticeKeypad { typed($0) }
                }
                .frame(maxWidth: .infinity)
            }
        } footer: {
            if done {
                PrimaryButton(title: OnbCopy.string("onb.s13_3b.primary")) { flow.go(.s13_4b) }
                    .bedrockAppear(.settle)
            }
        }
        .onChange(of: step, initial: true) { _, _ in announce() }
    }

    private func announce() {
        guard !done else { return }
        let index = step % code.count
        AccessibilityNotification.Announcement(
            BlindEntrySession.spoken(code[index], index: index, confirming: step >= code.count, practice: true)).post()
    }

    private func typed(_ digit: Character) {
        guard !done else { return }
        guard digit == code[step % code.count] else {
            miss()
            return
        }
        if step + 1 >= code.count * 2 {
            finish()
        } else {
            step += 1
        }
    }

    /// A wrong digit: the dots shake (no copy; it's practice).
    private func miss() {
        errors += 1
        BedrockHaptics.wrongDigit()
        AccessibilityNotification.Announcement(OnbCopy.string("onb.s13_3b.wrong")).post()
        guard !reduceMotion else { return }
        Task {
            for offset in [-8.0, 8, -6, 6, -3, 0] {
                withAnimation(.linear(duration: 0.05)) { shake = offset }
                try? await Task.sleep(for: .milliseconds(53))
            }
        }
    }

    private func finish() {
        withAnimation(BedrockMotion.reducedFade) { done = true }
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

    @State private var runner: BlindEntryRunner?

    var body: some View {
        OnboardingScaffold(.s13_4b, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(headline: OnbCopy.string("onb.s13_4b.headline"), headlineType: .titleM,
                              headlineGap: 10,
                              text: OnbCopy.string(runner?.style == .appSwitching
                                                   ? "onb.s13_4b.fallback_body" : "onb.s13_4b.body"),
                              textType: .bodyM)
                    .padding(.bottom, Space.s4)
                if let runner, runner.showsInBedrock, runner.session.hasStarted {
                    DigitWindowStage(runner: runner, start: begin)
                        .padding(.bottom, Space.s4)
                }
                IOSSteps(keys: (1...7).map { "onb.s13_4b.step_\($0)" }, bold: iOSLabels)
                Text(OnbCopy.string("onb.s13_4b.note"))
                    .ptype(.footnotePlain)
                    .foregroundStyle(BedrockColor.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.s3)
            }
        } footer: {
            if let runner { BlindEntryFooter(runner: runner, primary: OnbCopy.string("onb.s13_4b.primary"), begin: begin) }
        }
        .background { if let runner { PictureInPictureSource(runner: runner) } }
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

/// S13.4B's steps: a mono Glow number in a 24pt column, 14.5/20 Chalk, the
/// iOS labels the person has to find in semibold; 9pt apart.
struct IOSSteps: View {
    let keys: [String]
    var bold: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                HStack(alignment: .firstTextBaseline, spacing: Space.s2) {
                    Text(verbatim: "\(index + 1)")
                        .ptype(.stepNumber)
                        .foregroundStyle(BedrockColor.emberGlow)
                        .frame(width: 24, alignment: .leading)
                        .accessibilityHidden(true)
                    Text(emphasised(OnbCopy.string(key)))
                        .ptype(.step)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
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
                }
                searchRange = range.upperBound..<attributed.endIndex
            }
        }
        return attributed
    }
}

/// Picture in Picture needs its source layer in the window; it's kept behind
/// the screen, at the window's size, all but transparent.
private struct PictureInPictureSource: View {
    let runner: BlindEntryRunner

    var body: some View {
        if let pip = runner.pictureInPicture {
            PictureInPictureHost(pip: pip)
                .frame(width: 150, height: 116)
                .opacity(0.02)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// The digits inside Bedrock (app switching, preview): the 150 × 116 window.
private struct DigitWindowStage: View {
    let runner: BlindEntryRunner
    let start: () -> Void

    var body: some View {
        DigitWindowFace(state: runner.session.state)
            .shadow(color: .black.opacity(0.6), radius: 22, x: 0, y: 18)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            // “Tap to start” in Bedrock does what the button does.
            .onTapGesture { if runner.phase == .ready && !runner.session.hasStarted { start() } }
            .accessibilityHidden(true)
    }
}

/// S13.4B / S13.5A: start, or (app switching) “Switch to Settings”.
private struct BlindEntryFooter: View {
    let runner: BlindEntryRunner
    let primary: String
    let begin: () -> Void

    private var busy: Bool {
        runner.phase == .starting || (runner.session.isRunning && runner.style != .pictureInPicture)
    }

    var body: some View {
        if runner.style == .appSwitching && runner.session.state == .between {
            PrimaryButton(title: OnbCopy.string("onb.s13_4b.fallback_switch")) { runner.switchToSettings() }
        } else {
            PrimaryButton(title: primary, isLoading: busy) { begin() }
                .disabled(busy)
        }
    }
}

// MARK: - S13.5A · Check the code

struct CodeCheckScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase

    @State private var runner: BlindEntryRunner?

    var body: some View {
        OnboardingScaffold(.s13_5a, flow: flow, back: flow.mode != .firstRun) {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s13_5a.eyebrow"),
                              headline: OnbCopy.string("onb.s13_5a.headline"),
                              text: OnbCopy.string("onb.s13_5a.body"))
                if let runner {
                    if runner.showsInBedrock && runner.session.hasStarted && !runner.session.isDone {
                        DigitWindowStage(runner: runner) { runner.open() }
                            .padding(.top, Space.s6)
                    }
                    LinkButton(title: OnbCopy.string("onb.s13_4b.show_digits"), tone: .secondary) { runner.open() }
                        .disabled(runner.phase == .starting || (runner.session.isRunning && runner.showsInBedrock))
                        .padding(.top, Space.s3)
                }
            }
        } footer: {
            VStack(spacing: ProtoLayout.buttonGap) {
                PrimaryButton(title: OnbCopy.string("onb.s13_5a.primary")) {
                    BedrockHaptics.check()
                    flow.track(.codeCheck(.passed))
                    flow.go(.s13_5b)
                }
                .accessibilityHint(OnbCopy.string("onb.s13_5a.a11y_primary"))
                TextButton(title: OnbCopy.string("onb.s13_5a.secondary")) {
                    flow.track(.codeCheck(.failed))
                    flow.update { $0.codeMismatches += 1 }
                    flow.track(.codeMismatch(attempt: flow.state.codeMismatches))
                    flow.go(.s13_7a)
                }
            }
        }
        .background { if let runner { PictureInPictureSource(runner: runner) } }
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
    @State private var stuckShown = false

    var body: some View {
        OnboardingScaffold(.s13_5b, flow: flow, back: false) {
            ScreenHeading(eyebrow: OnbCopy.string("onb.s13_5a.eyebrow"),
                          headline: OnbCopy.string("onb.s13_5b.headline"),
                          text: OnbCopy.string("onb.s13_5b.body"))
        } footer: {
            VStack(spacing: 0) {
                PrimaryButton(title: OnbCopy.string("onb.s13_5b.primary")) { asked() }
                TextButton(title: OnbCopy.string("onb.s13_5b.secondary")) {
                    flow.track(.lockCheck(.switchedOff))
                    notSaved()
                }
                .padding(.top, ProtoLayout.buttonGap)
                LinkButton(title: OnbCopy.string("onb.s13_5b.link"), height: 36) {
                    flow.track(.action(.stuckOpened))
                    stuckShown = true
                }
            }
        }
        .bedrockSheet(isPresented: $stuckShown, title: nil) {
            StuckSheet { stuckShown = false }
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

/// “I got stuck”: four questions (serif 24/28) with their answers (16/22
/// Limestone), 18pt apart, then Close.
private struct StuckSheet: View {
    let close: () -> Void

    var body: some View {
        let parts = OnbCopy.parts("onb.s13_5b.stuck_sheet")
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(parts.dropLast().enumerated()), id: \.offset) { _, row in
                let split = Self.split(row)
                VStack(alignment: .leading, spacing: Space.s1) {
                    Text(split.question)
                        .ptype(.stuck)
                        .foregroundStyle(BedrockColor.inkPrimary)
                    Text(split.answer)
                        .ptype(.bodyM)
                        .foregroundStyle(BedrockColor.inkSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.bottom, Space.s6)
        SheetButton(title: parts.last ?? "", action: close)
    }

    /// “Lost your place? Run it again…” → the question and the answer.
    private static func split(_ row: String) -> (question: String, answer: String) {
        guard let mark = row.range(of: "? ") else { return (row, "") }
        return (String(row[..<mark.upperBound]).trimmingCharacters(in: .whitespaces), String(row[mark.upperBound...]))
    }
}

// MARK: - S13.6 · Sealed

struct SealedScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var keystoneIn = false
    @State private var wallDip: CGFloat = 0
    @State private var glow = false
    @State private var warm = false

    var body: some View {
        OnboardingScaffold(.s13_6, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: Space.s6)
                illustration
                    .frame(maxWidth: .infinity)
                Spacer(minLength: Space.s6)
                Eyebrow(text: OnbCopy.string("onb.s13_6.eyebrow"))
                    .padding(.bottom, Space.s3)
                CarveText(OnbCopy.string("onb.s13_6.headline"), delay: 0.9)
                    .ptype(.held)
                    .foregroundStyle(warm ? BedrockColor.emberGlow : BedrockColor.inkPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 14)
                Text(OnbCopy.string(flow.state.keyHolder == .partner ? "onb.s13_6.body_b" : "onb.s13_6.body_a"))
                    .ptype(.body)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .bedrockAppear(.rise, delay: 1.3)
                    .padding(.bottom, 28 - Space.s2)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s13_6.primary")) { flow.afterSealed() }
                .bedrockAppear(.settle, delay: 1.5)
        }
        .task {
            flow.track(.strictSealed((flow.state.keyHolder ?? .bedrock).analytics))
            if reduceMotion {
                keystoneIn = true
                glow = true
                warm = true
            } else {
                try? await Task.sleep(for: .seconds(0.3))
                withAnimation(BedrockMotion.settle) { keystoneIn = true }
                try? await Task.sleep(for: .seconds(0.6))
                BedrockHaptics.lock()
                withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.11)) { wallDip = BedrockSize.wallDip }
                withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.21).delay(0.11)) { wallDip = 0 }
                withAnimation(.easeOut(duration: 1.1)) { glow = true }
                try? await Task.sleep(for: .seconds(0.2))
                withAnimation(BedrockMotion.ember) { warm = true }
            }
            flow.dawnOverride = Dawn.level(for: .s15)
            AccessibilityNotification.Announcement(OnbCopy.string("onb.s13_6.a11y")).post()
        }
    }

    /// The capstone drops onto a two-course wall; an ember glow under it.
    private var illustration: some View {
        VStack(spacing: Space.s1 + 2) {
            ZStack(alignment: .top) {
                MiniWall.sealed
                    .offset(y: wallDip)
                    .padding(.top, 52)
                UnitPolygon.keystone
                    .fill(LinearGradient(colors: [BedrockColor.glyphHi, BedrockColor.brickMid], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1).padding(.horizontal, 8)
                    }
                    .frame(width: 64, height: 46)
                    .opacity(keystoneIn ? 1 : 0)
                    .offset(y: keystoneIn || reduceMotion ? wallDip : -BedrockSize.keystoneDrop)
            }
            EmberGlow(width: 280, height: 28)
                .padding(.top, -12)
                .opacity(glow ? 1 : 0)
                .scaleEffect(x: glow ? 1 : 0.5, y: 1)
        }
        .accessibilityHidden(true)
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
            VStack(spacing: ProtoLayout.buttonGap) {
                if helpFirst {
                    PrimaryButton(title: OnbCopy.string("onb.s13_7a.secondary")) { help() }
                    TextButton(title: OnbCopy.string("onb.s13_7a.primary")) { again() }
                } else {
                    PrimaryButton(title: OnbCopy.string("onb.s13_7a.primary")) { again() }
                    TextButton(title: OnbCopy.string("onb.s13_7a.secondary")) { help() }
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
        OnboardingScaffold(.s13_2p, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s13_2p.eyebrow"),
                              headline: OnbCopy.string("onb.s13_2p.headline"),
                              headlineGap: 14,
                              text: OnbCopy.string("onb.s13_2p.body"))
                    .padding(.bottom, 20)
                inviteCard
                Text(OnbCopy.string("onb.s13_2p.note"))
                    .ptype(.note)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, Space.s3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(BedrockColor.lineStrong, lineWidth: 1))
                    .padding(.top, 14)
            }
        } footer: {
            VStack(spacing: ProtoLayout.buttonGap) {
                if failed {
                    PrimaryButton(title: OnbCopy.parts("onb.s13_2p.offline").last ?? "", isLoading: loading) {
                        Task { await load() }
                    }
                } else {
                    PrimaryButton(title: OnbCopy.string("onb.s13_2p.primary"), isEnabled: link != nil, isLoading: loading) {
                        shareShown = true
                    }
                    TextButton(title: OnbCopy.string("onb.s13_2p.secondary")) { copy() }
                        .disabled(link == nil)
                }
                if failed {
                    // Until they accept, the steps work on their own: this never blocks setup.
                    TextButton(title: OnbCopy.string("onb.s13_2p.later")) { flow.go(.s13_2b) }
                }
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

    /// Basalt, radius 18, a Seam edge, 18pt in: the label (13pt Ash), the code
    /// (mono 28, +3, Glow), the link (14pt Limestone).
    private var inviteCard: some View {
        let label = OnbCopy.parts("onb.s13_2p.card").first ?? ""
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .ptype(.footnotePlain)
                .foregroundStyle(BedrockColor.inkTertiary)
            if let code {
                Text(code)
                    .ptype(.code)
                    .foregroundStyle(BedrockColor.emberGlow)
                    .textSelection(.enabled)
                    .accessibilityLabel(code.map { String($0) }.joined(separator: " "))
                if let link {
                    Text(link.replacingOccurrences(of: "https://", with: ""))
                        .ptype(.notePlain)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .textSelection(.enabled)
                }
            } else if failed {
                Text(OnbCopy.parts("onb.s13_2p.offline").first ?? "")
                    .ptype(.note)
                    .foregroundStyle(BedrockColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ProgressView()
                    .tint(BedrockColor.inkSecondary)
                    .frame(height: 34)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous).fill(BedrockColor.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: BedrockSize.planCardRadius, style: .continuous)
            .strokeBorder(BedrockColor.lineSubtle, lineWidth: 1))
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
