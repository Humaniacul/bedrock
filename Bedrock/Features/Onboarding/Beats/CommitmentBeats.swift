import SwiftUI

// MARK: - Beat 25: The oath (press-and-hold)

struct OathStoneView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void

    @State private var progress: Double = 0
    @State private var done = false
    @State private var rampTask: Task<Void, Never>?

    private let holdDuration: Double = 1.4

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            if done {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                    .riseIn(0, reduceMotion: reduceMotion)
                Text("Carved into bedrock.")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .riseIn(0.1, reduceMotion: reduceMotion)
                Text("This is your line. We'll hold it with you.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .riseIn(0.2, reduceMotion: reduceMotion)
                Spacer()
                Button("Continue") { onNext() }
                    .buttonStyle(.bedrockPrimary)
                    .riseIn(0.3, reduceMotion: reduceMotion)
            } else {
                Text("Set the first stone.")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Press and hold to make it real.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                holdControl
                Spacer()
            }
        }
        .padding(Theme.Spacing.xl)
        .onDisappear { rampTask?.cancel() }
    }

    private var holdControl: some View {
        ZStack {
            Circle().stroke(BedrockColor.slate, lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 34))
                .foregroundStyle(progress > 0 ? Theme.accent : Theme.textSecondary)
        }
        .frame(width: 168, height: 168)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 60) {
            complete()
        } onPressingChanged: { pressing in
            if pressing { beginHold() } else if !done { cancelHold() }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Set the first stone")
        .accessibilityHint("Activates your commitment")
        .accessibilityAction { complete() } // VoiceOver / motor-accessibility fallback
    }

    private func beginHold() {
        withAnimation(.linear(duration: holdDuration)) { progress = 1 }
        rampTask?.cancel()
        rampTask = Task {
            while !Task.isCancelled {
                BedrockHaptics.selection()
                try? await Task.sleep(for: .milliseconds(260))
            }
        }
    }

    private func cancelHold() {
        rampTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
    }

    private func complete() {
        guard !done else { return }
        rampTask?.cancel()
        BedrockHaptics.milestone()
        withAnimation(Theme.Motion.reduced(.smooth, when: reduceMotion)) {
            progress = 1
            done = true
        }
    }
}

// MARK: - Beat 26: Carve your why

struct CarveWhyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @FocusState private var focused: Bool

    private let starters = [
        "For the people I love.",
        "To respect myself again.",
        "To get my focus back.",
        "Because I'm done hiding.",
        "For who I'm becoming.",
    ]

    private var hasWhy: Bool { !model.why.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer(minLength: Theme.Spacing.sm)
            Text("Carve your reason into the stone.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("At 1am, you won't feel this clarity. Write it now — in your own words — so future-you can read it back at your weakest moment.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)

            TextEditor(text: $model.why)
                .focused($focused)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(Theme.Spacing.sm)
                .frame(minHeight: 140)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.basalt))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .strokeBorder(focused ? Theme.accent.opacity(0.6) : Theme.hairline))
                .overlay(alignment: .topLeading) {
                    if model.why.isEmpty {
                        Text("I'm doing this because…")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.textSecondary.opacity(0.6))
                            .padding(Theme.Spacing.md)
                            .allowsHitTesting(false)
                    }
                }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(starters, id: \.self) { starter in
                        BedrockChip(text: starter, isOn: false) { append(starter) }
                    }
                }
            }

            Spacer(minLength: 0)
            Button(hasWhy ? "Carve it in" : "Skip for now") {
                focused = false
                onNext()
            }
            .buttonStyle(.bedrockPrimary)
        }
        .padding(Theme.Spacing.xl)
    }

    private func append(_ phrase: String) {
        BedrockHaptics.selection()
        if model.why.isEmpty { model.why = phrase }
        else if !model.why.hasSuffix(" ") { model.why += " " + phrase }
        else { model.why += phrase }
    }
}

// MARK: - Beat 27: The 90-day projection

struct ProjectionChartView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: OnboardingModel
    var onNext: () -> Void

    @State private var draw: CGFloat = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Text("Your foundation, projected")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            ZStack {
                CurveShape(points: model.projectionPoints)
                    .trim(from: 0, to: draw)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 180)
            .padding(.horizontal, Theme.Spacing.sm)
            .accessibilityElement()
            .accessibilityLabel("A rising 90-day recovery curve from your current foundation toward fully rebuilt.")

            HStack {
                milestone("Day 7", "fog lifts")
                Spacer()
                milestone("Day 30", "reset begins")
                Spacer()
                milestone("Day 90", "rewired")
            }
            .padding(.horizontal, Theme.Spacing.sm)

            Text("This is what we build together.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
        }
        .padding(Theme.Spacing.xl)
        .task {
            if reduceMotion { draw = 1 }
            else { withAnimation(.easeInOut(duration: 1.6)) { draw = 1 } }
        }
    }

    private func milestone(_ day: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(day).font(Theme.Typography.monoCaption).foregroundStyle(Theme.accent)
            Text(label).font(Theme.Typography.caption).foregroundStyle(Theme.textSecondary)
        }
    }
}

private struct CurveShape: Shape {
    let points: [Double]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let stepX = rect.width / CGFloat(points.count - 1)
        for (i, value) in points.enumerated() {
            let point = CGPoint(x: CGFloat(i) * stepX, y: rect.height * (1 - CGFloat(value)))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - Beat 30: Stand guard (local-notification opt-in)

struct StandGuardView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void
    @State private var working = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 46))
                .foregroundStyle(Theme.accent)
                .riseIn(0, reduceMotion: reduceMotion)
            Text("We'll stand guard at your hardest hour.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .riseIn(0.1, reduceMotion: reduceMotion)
            Text("As Bedrock learns your danger windows, it can send a quiet, on-device check-in just before them — scheduled on your phone, never on a server.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .riseIn(0.2, reduceMotion: reduceMotion)
            Spacer()
            Button(working ? "Just a moment…" : "Stand guard") { enable() }
                .buttonStyle(.bedrockPrimary)
                .disabled(working)
            Button("Not now") { onNext() }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.Spacing.xl)
    }

    private func enable() {
        guard !working else { return }
        working = true
        Task {
            _ = await services.nudges.setEnabled(true, windows: [])
            onNext()
        }
    }
}
