import SwiftUI

/// The Intercept Moment (§4, §6.5). Opened from SOS or a proactive nudge.
/// Slows the user down (breathe → name it → a concrete replacement action),
/// always leaves an honest, shame-free exit, and logs the moment to the
/// on-device `TriggerEngine`. Composes `UrgeSurfView` rather than bloating it.
struct InterceptView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private enum Step: Equatable { case breathe, name, act, done(TriggerEngine.Outcome) }

    @State private var step: Step = .breathe
    @State private var urge: Int?
    @State private var trigger: String?
    @State private var customTrigger = ""
    @State private var actionIndex = Int.random(in: 0..<InterceptView.actions.count)
    @State private var showingContactSheet = false

    var body: some View {
        ZStack {
            StoneBackground()
            content
                .padding(Theme.Spacing.xl)
        }
        .overlay(alignment: .topTrailing) {
            if !isDone {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(Theme.Spacing.md)
                }
                .accessibilityLabel("Close")
            }
        }
        .sheet(isPresented: $showingContactSheet) { SupportContactSheet() }
        .animation(.easeInOut, value: step)
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .breathe:
            UrgeSurfView(minCycles: 2, collectsRating: true) { rating in
                urge = rating
                step = .name
            }
        case .name:
            nameStep
        case .act:
            actStep
        case .done(let outcome):
            doneStep(outcome)
        }
    }

    // MARK: - Step: name it

    private var nameStep: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            stepHeader("What's underneath it?",
                       "Naming the feeling takes some of its power away. Pick what fits — or skip.")
            ChoiceChips(options: Self.triggers, selection: $trigger)
            customField
            Spacer()
            Button("Continue") { step = .act }
                .buttonStyle(.bedrockPrimary)
        }
    }

    private var customField: some View {
        TextField("Something else…", text: $customTrigger)
            .textFieldStyle(.plain)
            .padding(Theme.Spacing.md)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.basalt))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.hairline))
            .foregroundStyle(Theme.textPrimary)
            .onChange(of: customTrigger) { _, newValue in
                if !newValue.trimmingCharacters(in: .whitespaces).isEmpty { trigger = nil }
            }
    }

    // MARK: - Step: do this instead

    private var actStep: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            stepHeader("Do this instead", "A small physical action breaks the loop. Pick it up now.")
            GlassCard {
                VStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: Self.actions[actionIndex].icon)
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.accent)
                    Text(Self.actions[actionIndex].text)
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
            }
            Button {
                BedrockHaptics.selection()
                actionIndex = (actionIndex + 1) % Self.actions.count
            } label: {
                Label("Give me another", systemImage: "arrow.triangle.2.circlepath")
                    .font(Theme.Typography.callout)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textSecondary)
            Spacer()
            outcomeButtons
        }
    }

    private var outcomeButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button("I rode it out") { finish(.surfed) }
                .buttonStyle(.bedrockPrimary)
            Button {
                callPerson()
            } label: {
                Label("Call my person", systemImage: "phone.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bedrockGlass)
            Button("I slipped — log it honestly") { finish(.slipped) }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Step: aftermath

    private func doneStep(_ outcome: TriggerEngine.Outcome) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            Image(systemName: outcome.icon)
                .font(.system(size: 52))
                .foregroundStyle(Theme.accent)
            Text(outcome.title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(outcome.body)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Close") { dismiss() }
                .buttonStyle(.bedrockPrimary)
        }
    }

    // MARK: - Shared

    private func stepHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var isDone: Bool { if case .done = step { return true } else { return false } }

    // MARK: - Actions

    private func callPerson() {
        guard services.supportContact.hasContact, let url = services.supportContact.callURL else {
            showingContactSheet = true
            return
        }
        openURL(url)
        finish(.called)
    }

    private func finish(_ outcome: TriggerEngine.Outcome) {
        let custom = customTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = custom.isEmpty ? trigger : custom
        services.triggers.log(.init(date: .now, trigger: resolved, urgeIntensity: urge, outcome: outcome))
        if outcome == .slipped { services.streak.recordRelapse() }
        Task { await services.nudges.refreshIfEnabled(windows: services.triggers.dangerWindows()) }
        switch outcome {
        case .surfed: BedrockHaptics.set()
        case .called, .slipped: BedrockHaptics.selection()
        }
        step = .done(outcome)
    }

    // MARK: - Content

    private static let triggers = [
        "Bored", "Stressed", "Lonely", "Tired", "Anxious",
        "Lustful", "Procrastinating", "Angry", "On autopilot",
    ]

    private struct Action { let text: String; let icon: String }
    private static let actions: [Action] = [
        .init(text: "Drop and do 15 push-ups.", icon: "figure.strengthtraining.traditional"),
        .init(text: "Step outside for 60 seconds of cold air.", icon: "wind"),
        .init(text: "Splash cold water on your face.", icon: "drop.fill"),
        .init(text: "Text your person one honest sentence.", icon: "message.fill"),
        .init(text: "Put your shoes on and walk to the end of the street.", icon: "figure.walk"),
        .init(text: "Drink a full glass of water, slowly.", icon: "waterbottle.fill"),
        .init(text: "Write one line about why you started.", icon: "pencil.line"),
        .init(text: "Stand up and stretch tall for 30 seconds.", icon: "figure.flexibility"),
    ]
}

private extension TriggerEngine.Outcome {
    var icon: String {
        switch self {
        case .surfed: "checkmark.seal.fill"
        case .called: "phone.fill"
        case .slipped: "bandage.fill"
        }
    }
    var title: String {
        switch self {
        case .surfed: "You rode it out."
        case .called: "Reaching out is strength."
        case .slipped: "The foundation holds."
        }
    }
    var body: String {
        switch self {
        case .surfed: "That's the rep that builds the foundation. The urge passed — it always does."
        case .called: "Stay with them a minute. You don't have to do this alone."
        case .slipped: "Logging it honestly is how you learn the pattern. Tomorrow you build again."
        }
    }
}

#Preview {
    InterceptView().environment(AppServices.makeStub())
}
