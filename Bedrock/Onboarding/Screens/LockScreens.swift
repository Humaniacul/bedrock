import SwiftUI

// Lock · The door, what 2am faces, who holds the key (SPEC.md S9–S11).

// MARK: - S9 · The door

struct DoorScreen: View {
    @Environment(FirstLightFlow.self) private var flow

    var body: some View {
        let row = OnbCopy.parts("onb.s9.row")
        OnboardingScaffold(.s9, flow: flow) {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s9.eyebrow"),
                              eyebrowColor: BedrockColor.emberGlow,
                              headline: OnbCopy.string("onb.s9.headline"),
                              text: OnbCopy.string("onb.s9.body"))
                Spacer(minLength: Space.s6)
                VStack(spacing: 10) {
                    DoorIllustration(rowTitle: row.first ?? "", rowApp: row.last ?? "")
                    Text(OnbCopy.string("onb.s9.caption"))
                        .ptype(.footnotePlain)
                        .foregroundStyle(BedrockColor.inkTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                Spacer(minLength: Space.s6)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s9.primary")) {
                flow.track(.action(.closeDoor))
                flow.go(.s10)
            }
            .accessibilityHint(OnbCopy.string("onb.s9.a11y_primary"))
        }
    }
}

// MARK: - S10 · What 2am you will face

struct PathScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var footerShown = false
    @State private var limitsShown = false
    @State private var warm = false
    /// Revisits (back from S11) show the path lit, with no replay.
    @State private var lit: Bool?

    private var steps: [(title: String, detail: String)] {
        (1...6).map { n in
            let parts = OnbCopy.parts("onb.s10.step_\(n)")
            return (parts.first ?? "", parts.dropFirst().joined(separator: " · "))
        }
    }

    /// “Not impossible to undo.” / “Just impossible to undo at 2am.”
    private var quote: String {
        OnbCopy.string("onb.s10.footer").replacingOccurrences(of: ". ", with: ".\n")
    }

    var body: some View {
        OnboardingScaffold(.s10, flow: flow) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: OnbCopy.string("onb.s10.eyebrow"))
                    .padding(.bottom, 10)
                VStack(alignment: .leading, spacing: 0) {
                    Text(OnbCopy.string("onb.s10.headline"))
                        .ptype(.titleM)
                        .foregroundStyle(BedrockColor.inkPrimary)
                    Text(OnbCopy.string("onb.s10.headline_2"))
                        .ptype(.titleItalicM)
                        .foregroundStyle(warm ? BedrockColor.emberGlow : BedrockColor.inkPrimary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 18)

                if let lit {
                    GauntletPath(steps: steps, lit: lit) { step in
                        flow.track(.gauntletStepOpened(step: step))
                    }
                }

                VStack(spacing: 6) {
                    Text(quote)
                        .ptype(.quote)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    LinkButton(title: OnbCopy.string("onb.s10.link"), tone: .ember) {
                        flow.track(.limitsOpened)
                        limitsShown = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .opacity(footerShown ? 1 : 0)
                .offset(y: footerShown || reduceMotion ? 0 : 8)
                Spacer(minLength: 12)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s10.primary")) { flow.go(.s11) }
                .bedrockAppear(.settle, delay: BedrockTiming.s10PrimaryAt)
        }
        .bedrockSheet(isPresented: $limitsShown, title: OnbCopy.parts("onb.s10.limits_sheet").first ?? "", titleGap: 18) {
            LimitsSheet { limitsShown = false }
        }
        .onAppear {
            guard lit == nil else { return }
            lit = flow.state.pathPlayed
        }
        .task {
            withAnimation(BedrockMotion.ember.delay(reduceMotion ? 0 : 0.35)) { warm = true }
            if lit == true || reduceMotion {
                footerShown = true
            } else {
                try? await Task.sleep(for: .seconds(BedrockTiming.pathFooter))
                withAnimation(.easeOut(duration: 0.5)) { footerShown = true }
            }
        }
        .onDisappear { flow.update { $0.pathPlayed = true } }
    }
}

/// “What Strict Mode can't stop”: four honest limits behind a short ember dash,
/// a closing line in Glow, Got it.
private struct LimitsSheet: View {
    let close: () -> Void

    var body: some View {
        let parts = OnbCopy.parts("onb.s10.limits_sheet")
        let rows = Array(parts.dropFirst().prefix(4))
        VStack(alignment: .leading, spacing: 14) {
            ForEach(rows, id: \.self) { row in
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(BedrockColor.ember)
                        .frame(width: 10, height: 2)
                        .padding(.top, 10)
                        .frame(width: 18, alignment: .leading)
                        .accessibilityHidden(true)
                    Text(row)
                        .ptype(.bodyM)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        if parts.count > 5 {
            Text(parts[5])
                .ptype(.quote)
                .foregroundStyle(BedrockColor.emberGlow)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 22)
        }
        SheetButton(title: parts.last ?? "", action: close)
    }
}

// MARK: - S11 · Who holds the key

struct KeyHolderScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services
    @State private var holder: KeyHolder?
    @State private var sheetShown = false

    var body: some View {
        let a = OnbCopy.parts("onb.s11.option_a")
        let b = OnbCopy.parts("onb.s11.option_b")
        OnboardingScaffold(.s11, flow: flow) {
            VStack(alignment: .leading, spacing: 0) {
                if !RemoteConfig.strictModeSupported {
                    VersionBanner(text: OnbCopy.string("onb.s11.version_banner"))
                        .padding(.bottom, 14)
                }
                ScreenHeading(eyebrow: OnbCopy.string("onb.s11.eyebrow"),
                              headline: OnbCopy.string("onb.s11.headline"),
                              headlineGap: 14,
                              text: OnbCopy.string("onb.s11.body"))
                    .padding(.bottom, 20)
                VStack(spacing: Space.s3) {
                    OptionCard(title: item(a, 0), detail: item(a, 1), tag: item(a, 2),
                               isSelected: holder == .bedrock, position: (1, 2)) { choose(.bedrock) }
                        .bedrockAppear(.strata(index: 0))
                    OptionCard(title: item(b, 0), detail: item(b, 1), tag: item(b, 2),
                               isSelected: holder == .partner, position: (2, 2)) { choose(.partner) }
                        .bedrockAppear(.strata(index: 1))
                }
                LinkButton(title: OnbCopy.string("onb.s11.link"), tone: .secondary) {
                    flow.track(.existingPasscodeInfoOpened)
                    sheetShown = true
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s11.primary"), isEnabled: holder != nil,
                          disabledHint: OnbCopy.string("onb.common.pick_at_least_one")) { next() }
        }
        .bedrockSheet(isPresented: $sheetShown, title: OnbCopy.parts("onb.s11.sheet").first ?? "") {
            let parts = OnbCopy.parts("onb.s11.sheet")
            SheetBody(text: item(parts, 1))
            SheetButton(title: item(parts, 2)) { sheetShown = false }
        }
        .onAppear { holder = flow.state.keyHolder }
    }

    private func choose(_ choice: KeyHolder) {
        holder = choice
        flow.update { $0.keyHolder = choice }
        flow.track(.keyHolderSelected(choice.analytics))
    }

    private func next() {
        // Bought before (restore, R1): the key choice is still per phone, then setup.
        if services.paywall.isPremium && RemoteConfig.strictModeSupported {
            flow.update { $0.paywallOutcome = .purchased }
            flow.go(.s13_1)
        } else {
            flow.toPaywall()
        }
    }

    private func item(_ parts: [String], _ index: Int) -> String {
        parts.indices.contains(index) ? parts[index] : ""
    }
}

/// S11's banner when Strict Mode isn't verified on this iOS: Ember Wash, a Kiln
/// edge, radius 14, 14/20 Chalk. Read first.
struct VersionBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .ptype(.note)
            .foregroundStyle(BedrockColor.inkPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, Space.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.emberWash))
            .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(BedrockColor.emberDeep, lineWidth: 1))
            .accessibilitySortPriority(1)
    }
}
