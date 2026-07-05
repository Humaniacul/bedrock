import SwiftUI
import FamilyControls

// ACT IV — THE COVENANT (spec S19–S25): commitment → a configured, personal
// foundation. The ladder: oath → name → guardrails → friction tier → rhythm →
// the built wall → the why. Each step is one more stone the user set himself.

// MARK: - S19 · Future Self

struct FutureSelfBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            CarveSequence(lines: [
                .init(text: "Picture yourself\nninety days from now."),
                .init(text: "You wake and reach for the day,\nnot the screen."),
                .init(text: "You feel \(model.bestSelfWord) — like yourself.", ember: true),
                .init(text: "That person isn't a fantasy.\nHe's you, without the noise.",
                      font: .system(.title3, design: .serif, weight: .medium)),
            ], interlinePause: 0.9) { finished = true }
            .breath(finished, reduceMotion: reduceMotion)
            Spacer()
            TapToContinue(visible: finished)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .padding(Theme.Spacing.xl)
        .contentShape(Rectangle())
        .onTapGesture { if finished { onNext() } }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to continue")
    }
}

// MARK: - S20 · The Cornerstone (the commitment ceremony)

struct CornerstoneBeat: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var introDone = false
    @FocusState private var nameFocused: Bool

    private var nameEntered: Bool {
        !model.commitmentName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            OnboardingEyebrow(text: "THE CORNERSTONE")
                .padding(.top, Theme.Spacing.md)
            Spacer(minLength: 0)
            CarveSequence(lines: [
                .init(text: "From here, two paths. One asks nothing\nand just… continues.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "The other starts with one solid decision.",
                      font: .system(.title3, design: .serif, weight: .semibold)),
                .init(text: "Make it real.", ember: true),
            ], spacing: Theme.Spacing.md, interlinePause: 0.5) {
                withAnimation(.smooth(duration: 0.5)) { introDone = true }
            }

            if introDone {
                contract
                    .settleIn(reduceMotion: reduceMotion)
                Spacer(minLength: 0)
                OathStone(enabled: nameEntered) {
                    model.hasSealedOath = true
                    model.oathSealedAt = Date()
                    onNext()
                }
                .settleIn(0.15, reduceMotion: reduceMotion)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.xl)
    }

    /// The contract line, with their name written into the stone.
    private var contract: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: 6) {
                Text("I,")
                    .font(.system(.body, design: .serif, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                TextField("your name", text: $model.commitmentName)
                    .focused($nameFocused)
                    .font(.system(.body, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .frame(maxWidth: 160)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(nameFocused ? Theme.accent : Theme.hairline)
                            .frame(height: 1)
                            .offset(y: 3)
                    }
                Spacer(minLength: 0)
            }
            Text("am done letting this run my life. Starting now, I build on solid ground.")
                .font(.system(.body, design: .serif, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.lg)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md)
            .fill(LinearGradient(colors: [BedrockColor.slate, BedrockColor.basalt],
                                 startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
            .strokeBorder(Theme.accent.opacity(nameEntered ? 0.5 : 0.2)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("The contract. I, your name, am done letting this run my life. Starting now, I build on solid ground.")
    }
}

// MARK: - S21 · Build Your Guardrails (FamilyControls, in-context)

struct GuardrailsBeat: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @State private var authorizing = false
    @State private var showPicker = false
    @State private var pickerWasShown = false

    private var blocking: BlockingService { services.blocking }
    private var selectionBinding: Binding<FamilyActivitySelection> {
        Binding(get: { blocking.selection }, set: { blocking.selection = $0 })
    }
    private var needsPicker: Bool {
        model.guardrails.contains(.pullApps) || model.guardrails.contains(.namedTriggers)
            || model.guardrails.contains(.recommended)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer(minLength: 0)
            Text("Now we lay the foundation.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .settleIn(reduceMotion: reduceMotion)
            Text("What should Bedrock hold the line on?")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .settleIn(0.08, reduceMotion: reduceMotion)

            // The wall builds in real time — one stone per choice.
            FoundationWall(blocks: model.guardrails.count)
                .frame(maxWidth: .infinity)
                .settleIn(0.12, reduceMotion: reduceMotion)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(OnboardingModel.Guardrail.allCases.enumerated()), id: \.element) { index, rail in
                    OnboardingOptionCard(
                        label: rail.label,
                        icon: rail.icon,
                        isSelected: model.guardrails.contains(rail)
                    ) {
                        if model.guardrails.contains(rail) {
                            model.guardrails.remove(rail)
                        } else {
                            model.guardrails.insert(rail)
                        }
                    }
                    .strata(index, base: 0.2, reduceMotion: reduceMotion)
                }
            }

            Spacer(minLength: 0)
            actions
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            // Pre-check late-night from Step 10 (their own pattern).
            if model.guardrails.isEmpty, model.triggers.contains("Late at night") {
                model.guardrails.insert(.lateNight)
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: selectionBinding)
        .onChange(of: showPicker) { _, isShown in
            if isShown { pickerWasShown = true }
            // Picker dismissed → raise the wall with whatever they chose.
            if !isShown && pickerWasShown { raiseWallAndAdvance() }
        }
    }

    @ViewBuilder private var actions: some View {
        switch blocking.authState {
        case .unavailable:
            Text("Screen Time runs on a real iPhone — Bedrock will finish raising this wall there. Your choices are saved.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            OnboardingPrimaryButton(title: "Continue") { applySafariLayer(); onNext() }
        case .denied:
            Text("Screen Time access is off. You can enable it later in Settings → Screen Time — your choices are saved.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            OnboardingPrimaryButton(title: "Continue") { applySafariLayer(); onNext() }
        case .notDetermined, .approved:
            OnboardingPrimaryButton(
                title: authorizing ? "One moment…" : "Lay the foundation",
                subtitle: "iOS will ask permission — that's Bedrock taking its post.") {
                layFoundation()
            }
            .disabled(model.guardrails.isEmpty || authorizing)
            .opacity(model.guardrails.isEmpty ? 0.45 : 1)
        }
    }

    private func layFoundation() {
        guard !authorizing else { return }
        authorizing = true
        Task { @MainActor in
            if blocking.authState == .notDetermined {
                try? await blocking.requestAuthorization()
            }
            authorizing = false
            guard blocking.authState == .approved else {
                // Denied in the moment — respect it, keep moving. Choices persist.
                applySafariLayer()
                onNext()
                return
            }
            applySafariLayer()
            if needsPicker {
                showPicker = true // dismissal continues the flow
            } else {
                raiseWallAndAdvance()
            }
        }
    }

    private func applySafariLayer() {
        if model.guardrails.contains(.adultContent) || model.guardrails.contains(.recommended) {
            blocking.safariFilterEnabled = true
        }
    }

    private func raiseWallAndAdvance() {
        if blocking.authState == .approved,
           blocking.blockedItemCount > 0 || blocking.safariFilterEnabled {
            blocking.applyProtection()
            BedrockHaptics.stoneSet()
        }
        onNext()
    }
}

// MARK: - S22 · Make It Unbeatable

struct UnbeatableBeat: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer(minLength: 0)
            Text("Make it unbeatable.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .settleIn(reduceMotion: reduceMotion)
            Text("The old blockers failed because you could undo them in a weak moment. Choose how unbeatable this is.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .settleIn(0.08, reduceMotion: reduceMotion)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(OnboardingModel.FrictionTier.allCases.enumerated()), id: \.element) { index, tier in
                    OnboardingOptionCard(
                        label: tier.label,
                        icon: tier.icon,
                        detail: tier.detail,
                        isSelected: model.frictionTier == tier
                    ) { model.frictionTier = tier }
                    .strata(index, base: 0.15, reduceMotion: reduceMotion)
                }
            }

            if model.frictionTier != .reflectionDelay {
                Text(model.frictionTier == .partner
                     ? "You'll pick your person once you're inside — no pressure now."
                     : "You'll set the lock's terms once you're inside — deliberately, not in a rush.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .settleIn(reduceMotion: reduceMotion)
            }

            Spacer(minLength: 0)
            OnboardingPrimaryButton(title: "Continue") { onNext() }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - S23 · Your Rhythm

struct RhythmBeat: View {
    @Environment(AppServices.self) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @State private var working = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer(minLength: 0)
            Text("When should we stand guard?")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .settleIn(reduceMotion: reduceMotion)
            Text("We'll reach you at your hardest hour — not the app's.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .settleIn(0.08, reduceMotion: reduceMotion)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(OnboardingModel.TimeSlot.allCases.enumerated()), id: \.element) { index, slot in
                    OnboardingOptionCard(
                        label: slot.label,
                        isSelected: model.preferredTimes.contains(slot)
                    ) {
                        if model.preferredTimes.contains(slot) {
                            model.preferredTimes.remove(slot)
                        } else {
                            model.preferredTimes.insert(slot)
                        }
                    }
                    .strata(index, base: 0.15, reduceMotion: reduceMotion)
                }
            }

            Text("One quiet nudge at the right time. Off anytime. No spam — ever.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .settleIn(0.2, reduceMotion: reduceMotion)

            Spacer(minLength: 0)
            OnboardingPrimaryButton(title: working ? "One moment…" : "Continue") { enable() }
                .disabled(working)
            Button("Not now") { onNext() }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity)
        }
        .padding(Theme.Spacing.xl)
        .onAppear { precheck() }
    }

    /// Defaults from their Step-10 pattern — the app already listened.
    private func precheck() {
        guard model.preferredTimes.isEmpty else { return }
        if model.triggers.contains("Late at night") { model.preferredTimes.insert(.lateNight) }
        if model.triggers.contains("First thing in the morning") { model.preferredTimes.insert(.morning) }
        if model.triggers.contains("Stressed or low") { model.preferredTimes.insert(.evening) }
    }

    private func enable() {
        guard !working else { return }
        guard !model.preferredTimes.isEmpty else { onNext(); return }
        working = true
        Task { @MainActor in
            // Requests notification permission in-context; advances either way.
            _ = await services.nudges.setEnabled(true, windows: [])
            working = false
            onNext()
        }
    }
}

// MARK: - S24 · Your Foundation Is Ready (Peak 2)

struct FoundationReadyBeat: View {
    let model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wallBlocks = 0
    @State private var showCapstone = false
    @State private var finished = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ChiselText(
                text: "It's built.",
                font: .system(.largeTitle, design: .serif, weight: .semibold)) {
                Task { await buildWall() }
            }

            FoundationWall(blocks: wallBlocks, capstone: showCapstone ? model.bestSelfWord : nil)
                .breath(finished, reduceMotion: reduceMotion)

            if finished {
                Text(model.foundationSummary)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .settleIn(reduceMotion: reduceMotion)
                HStack(spacing: 6) {
                    Text("On solid ground, with one destination:")
                        .font(.system(.body, design: .serif, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    EmberPhrase(text: model.bestSelfWord,
                                font: .system(.body, design: .serif, weight: .semibold),
                                delay: 0.5)
                }
                .settleIn(0.1, reduceMotion: reduceMotion)
            }
            Spacer()
            TapToContinue(visible: finished)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .padding(Theme.Spacing.xl)
        .contentShape(Rectangle())
        .onTapGesture { if finished { onNext() } }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to continue")
    }

    /// Stones land one by one, then the capstone — engineered to crest here.
    private func buildWall() async {
        let pause = reduceMotion ? 60 : 280
        for i in 1...5 {
            try? await Task.sleep(for: .milliseconds(pause))
            wallBlocks = i
            if !reduceMotion { BedrockHaptics.set() }
        }
        try? await Task.sleep(for: .milliseconds(pause + 120))
        showCapstone = true
        BedrockHaptics.stoneSet()
        withAnimation { finished = true }
    }
}

// MARK: - S25 · Name Your Why (the crown jewel)

struct NameWhyBeat: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: Bool
    @State private var carveTick = 0

    private var hasWhy: Bool {
        !model.whyLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer(minLength: Theme.Spacing.sm)
            Text("One last thing.")
                .font(.system(.title, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .settleIn(reduceMotion: reduceMotion)
            Text("In your own words — why does this matter?")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.textSecondary)
                .settleIn(0.08, reduceMotion: reduceMotion)

            TextField("When it's hard, I'll see this.", text: $model.whyLine, axis: .vertical)
                .focused($focused)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(3...6)
                .padding(Theme.Spacing.md)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(BedrockColor.basalt))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .strokeBorder(focused ? Theme.accent.opacity(0.6) : Theme.hairline))
                .settleIn(0.15, reduceMotion: reduceMotion)
                .onChange(of: model.whyLine) { old, new in
                    // Their words carve into the stone as they type (.soft, rationed).
                    if new.count > old.count {
                        carveTick += 1
                        if carveTick.isMultiple(of: 3) { BedrockHaptics.calm() }
                    }
                }

            if hasWhy {
                CornerstoneView(line: model.whyLine.trimmingCharacters(in: .whitespacesAndNewlines),
                                sub: model.commitmentName.isEmpty ? nil : "— \(model.commitmentName)")
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            Text("When the urge hits, these words meet it. That's a promise.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
                .settleIn(0.25, reduceMotion: reduceMotion)

            Spacer(minLength: 0)
            OnboardingPrimaryButton(title: hasWhy ? "Set it in the stone" : "Skip for now") {
                focused = false
                onNext()
            }
        }
        .padding(Theme.Spacing.xl)
        .animation(Theme.Motion.reduced(.smooth(duration: 0.4), when: reduceMotion), value: hasWhy)
    }
}
