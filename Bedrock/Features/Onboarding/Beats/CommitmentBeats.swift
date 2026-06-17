import SwiftUI

// MARK: - The oath (forging — press & hold)

struct OathStoneView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void

    @State private var progress: CGFloat = 0
    @State private var dust = 0
    @State private var done = false
    @State private var flash = false
    @State private var dustTask: Task<Void, Never>?

    private let holdDuration: Double = 2.5

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            if done {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 58)).foregroundStyle(Theme.accent)
                    .riseIn(0, reduceMotion: reduceMotion)
                Text("Carved into bedrock.")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary).multilineTextAlignment(.center)
                    .riseIn(0.1, reduceMotion: reduceMotion)
                Text("This is your line in the ground. We hold it with you.")
                    .font(Theme.Typography.body).foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .riseIn(0.2, reduceMotion: reduceMotion)
                Spacer()
                Button("Continue") { onNext() }
                    .buttonStyle(.bedrockPrimary)
                    .riseIn(0.3, reduceMotion: reduceMotion)
            } else {
                Text("Set your first stone.")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary).multilineTextAlignment(.center)
                Text("Press, and hold.")
                    .font(Theme.Typography.body).foregroundStyle(Theme.textSecondary)
                Spacer()
                forgeStone
                Spacer()
            }
        }
        .padding(Theme.Spacing.xl)
        .onDisappear { dustTask?.cancel() }
    }

    private var forgeStone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(BedrockColor.slate)
            // Sand/ember fills the stone from the base upward as it's forged.
            GeometryReader { geo in
                Rectangle()
                    .fill(LinearGradient(colors: [Theme.accent, BedrockColor.bronze],
                                         startPoint: .bottom, endPoint: .top))
                    .frame(height: geo.size.height * progress)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            Image(systemName: "hammer.fill")
                .font(.system(size: 30))
                .foregroundStyle(progress > 0.05 ? Theme.onAccent : Theme.textSecondary)
            StoneParticles(trigger: dust, color: BedrockColor.ash, burst: 4)
        }
        .frame(width: 188, height: 132)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.accent.opacity(0.3 + progress * 0.5)))
        .scaleEffect(flash ? 1.05 : 1)
        .shadow(color: BedrockColor.ember.opacity(progress * 0.6), radius: 10 + progress * 22, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 80) {
            complete()
        } onPressingChanged: { pressing in
            if pressing { beginHold() } else if !done { cancelHold() }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Set your first stone")
        .accessibilityHint("Activates your commitment")
        .accessibilityAction { complete() }
    }

    private func beginHold() {
        BedrockHaptics.oathRamp(duration: holdDuration)
        withAnimation(.linear(duration: holdDuration)) { progress = 1 }
        dustTask?.cancel()
        dustTask = Task {
            while !Task.isCancelled {
                dust += 1
                try? await Task.sleep(for: .milliseconds(130))
            }
        }
    }

    private func cancelHold() {
        BedrockHaptics.stopRamp()
        dustTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
    }

    private func complete() {
        guard !done else { return }
        dustTask?.cancel()
        BedrockHaptics.stopRamp()
        BedrockHaptics.stoneSet()
        withAnimation(.easeInOut(duration: 0.12)) { flash = true; progress = 1 }
        withAnimation(Theme.Motion.reduced(.smooth.delay(0.12), when: reduceMotion)) {
            flash = false
            done = true
        }
    }
}

// MARK: - Carve your why

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
            Text("At 1am, you won't feel this clarity. Write it now — in your own words — and we'll read it back to you when you need it most.")
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

// MARK: - The projection (the climb)

struct ProjectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: OnboardingModel
    var onNext: () -> Void

    @State private var draw: CGFloat = 0

    private var summit: String {
        let why = model.why.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = why.split(separator: "\n").first, !first.isEmpty { return String(first) }
        return "The man you're building"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Text("Your path, projected")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            ZStack(alignment: .topTrailing) {
                ClimbShape(points: model.projectionPoints)
                    .trim(from: 0, to: draw)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                if draw > 0.95 {
                    Text("“\(summit)”")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(BedrockColor.slate.opacity(0.8)))
                        .transition(.opacity)
                }
            }
            .frame(height: 180)
            .padding(.horizontal, Theme.Spacing.sm)
            .accessibilityElement()
            .accessibilityLabel("A rising 90-day path toward your goal: \(summit).")

            HStack(alignment: .top) {
                milestone("Day 7", "fog lifts")
                Spacer(); milestone("Day 14", "urges crest")
                Spacer(); milestone("Day 30", "reset begins")
                Spacer(); milestone("Day 90", "rewired")
            }
            .padding(.horizontal, Theme.Spacing.sm)

            Text("This is what we build together. Starting today.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Continue") { onNext() }
                .buttonStyle(.bedrockPrimary)
        }
        .padding(Theme.Spacing.xl)
        .task {
            if reduceMotion { draw = 1 }
            else { withAnimation(.easeInOut(duration: 1.8)) { draw = 1 } }
        }
    }

    private func milestone(_ day: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(day).font(.system(.caption2, design: .monospaced).weight(.semibold)).foregroundStyle(Theme.accent)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
    }
}

private struct ClimbShape: Shape {
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

// MARK: - Stand guard (local-notification opt-in)

struct StandGuardView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onNext: () -> Void
    @State private var working = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 46)).foregroundStyle(Theme.accent)
                .riseIn(0, reduceMotion: reduceMotion)
            Text("Let us stand guard at your hardest hour.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary).multilineTextAlignment(.center)
                .riseIn(0.1, reduceMotion: reduceMotion)
            Text("As Bedrock learns your danger windows, it can send a quiet check-in just before them — scheduled on your phone, never on a server.")
                .font(Theme.Typography.body).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .riseIn(0.2, reduceMotion: reduceMotion)
            Spacer()
            Button(working ? "Just a moment…" : "Stand guard") { enable() }
                .buttonStyle(.bedrockPrimary).disabled(working)
            Button("Not now") { onNext() }
                .font(Theme.Typography.callout).foregroundStyle(Theme.textSecondary)
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
