import SwiftUI

// The individual gauntlet steps (§4). Each calls its completion when satisfied;
// the gauntlet runner advances. Kept as plain inputs + callbacks so they stay
// testable and reusable.

// MARK: - 1. Future-self letter (unskippable)

struct FutureSelfStep: View {
    let letter: String
    var dwellSeconds: Int = 8
    var onContinue: () -> Void

    @State private var secondsLeft = 8

    private var canContinue: Bool { secondsLeft <= 0 }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ScrollView {
                Text(letter)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button(canContinue ? "I've read it" : "Read it through… \(secondsLeft)s") {
                onContinue()
            }
            .buttonStyle(.bedrockPrimary)
            .disabled(!canContinue)
        }
        .padding(Theme.Spacing.xl)
        .task {
            secondsLeft = dwellSeconds
            while secondsLeft > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                secondsLeft -= 1
            }
        }
    }
}

// MARK: - 3. Hand-type the commitment passage (no paste, typos reset)

struct CommitmentTypingStep: View {
    let sentences: [String]
    var onComplete: () -> Void

    @State private var index = 0
    @State private var typed = ""
    @State private var shake = false
    @FocusState private var focused: Bool

    private var target: String { sentences[safe: index] ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Sentence \(index + 1) of \(sentences.count)")
                .font(Theme.Typography.monoCaption)
                .foregroundStyle(Theme.textSecondary)

            guideText
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.slate.opacity(0.4)))

            TextField("Type it exactly", text: $typed, axis: .vertical)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textPrimary)
                .focused($focused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(Theme.Spacing.lg)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.basalt))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.hairline))
                .offset(x: shake ? -8 : 0)
                .onChange(of: typed, handleChange)

            Text("No paste. A typo resets the sentence.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .onAppear { focused = true }
    }

    private var guideText: some View {
        // Completed prefix in warm ember, the rest in ash.
        let matched = target.hasPrefix(typed) ? typed.count : 0
        var done = AttributedString(String(target.prefix(matched)))
        done.foregroundColor = Theme.accent
        var rest = AttributedString(String(target.dropFirst(matched)))
        rest.foregroundColor = Theme.textSecondary
        return Text(done + rest).font(Theme.Typography.body)
    }

    private func handleChange(_ old: String, _ new: String) {
        // Block paste: more than one character added at once.
        if new.count > old.count + 1 {
            typed = old
            flashError()
            return
        }
        if new == target {
            advance()
            return
        }
        if !target.hasPrefix(new) {
            typed = "" // typo → reset the sentence (§4)
            flashError()
        }
    }

    private func advance() {
        BedrockHaptics.set()
        if index < sentences.count - 1 {
            index += 1
            typed = ""
        } else {
            onComplete()
        }
    }

    private func flashError() {
        BedrockHaptics.selection()
        withAnimation(.default) { shake = true }
        withAnimation(.default.delay(0.1)) { shake = false }
    }
}

// MARK: - 4. Write a "why" that sends to the partner

struct PartnerMessageStep: View {
    var onSend: (String) -> Void

    @State private var message = ""
    private var canSend: Bool { message.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20 }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Tell the person holding your line why you want to turn this off. They'll see it.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)

            TextEditor(text: $message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .padding(Theme.Spacing.md)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.basalt))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.hairline))

            Button("Send & continue") { onSend(message) }
                .buttonStyle(.bedrockPrimary)
                .disabled(!canSend)
            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - 5. Cooldown (resets on backgrounding)

struct CooldownStep: View {
    let cooldown: CooldownEngine
    let seconds: Int
    /// Optional server confirmation (§10.5). When set, the step won't complete
    /// until the server agrees enough real time has elapsed.
    var verify: (() async -> Bool)?
    var onComplete: () -> Void

    @State private var confirming = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()
            ZStack {
                Circle().stroke(BedrockColor.slate, lineWidth: 10).frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: cooldown.progress)
                    .stroke(BedrockColor.mineral, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                Text(timeString(cooldown.remaining))
                    .font(.system(size: 40, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
            }
            VStack(spacing: Theme.Spacing.xs) {
                Text(confirming ? "Confirming…" : "Sit with it.")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                Text("If you leave the app, the timer starts over.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            if !cooldown.isRunning && !cooldown.didComplete { cooldown.start(seconds: seconds) }
        }
        .onChange(of: cooldown.didComplete) { _, done in
            if done { Task { await finish() } }
        }
        .accessibilityElement()
        .accessibilityLabel("Cooldown, \(timeString(cooldown.remaining)) remaining")
    }

    private func finish() async {
        if let verify {
            confirming = true
            while !(await verify()) {
                try? await Task.sleep(for: .seconds(5))
                if Task.isCancelled { return }
            }
            confirming = false
        }
        onComplete()
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - 6. Partner approval

struct PartnerApprovalStep: View {
    var onApproved: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ProgressView().controlSize(.large).tint(Theme.accent)
            Text("Waiting for your partner to approve")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
            Text("They've been notified. This unlocks when they tap Approve.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            #if DEBUG
            Button("Simulate approval (debug)") { onApproved() }
                .buttonStyle(.bedrockGlass)
            #endif
        }
        .padding(Theme.Spacing.xl)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
