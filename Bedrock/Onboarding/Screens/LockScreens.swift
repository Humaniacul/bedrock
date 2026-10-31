import SwiftUI

// Lock · The door, what 2am faces, who holds the key (SPEC.md S9–S11).

// MARK: - S9 · The door

struct DoorScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @Environment(AppServices.self) private var services

    var body: some View {
        let row = OnbCopy.parts("onb.s9.row")
        OnboardingScaffold(.s9, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s7) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s9.eyebrow"),
                              headline: OnbCopy.string("onb.s9.headline"),
                              text: OnbCopy.string("onb.s9.body"))
                VStack(spacing: Space.s3) {
                    DoorIllustration(rowTitle: row.first ?? "", rowApp: row.last ?? "",
                                     hasApps: !services.blocking.selection.applicationTokens.isEmpty)
                    Text(OnbCopy.string("onb.s9.caption"))
                        .font(BedrockFont.footnote)
                        .foregroundStyle(BedrockColor.inkTertiary)
                }
                .frame(maxWidth: .infinity)
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
    /// Revisits (back from S11) show the path lit, with no replay.
    @State private var lit: Bool?

    private var steps: [(title: String, detail: String)] {
        (1...6).map { n in
            let parts = OnbCopy.parts("onb.s10.step_\(n)")
            return (parts.first ?? "", parts.dropFirst().joined(separator: " · "))
        }
    }

    var body: some View {
        OnboardingScaffold(.s10, flow: flow) {
            VStack(alignment: .leading, spacing: Space.s7) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(OnbCopy.string("onb.s10.eyebrow"))
                        .bedrockEyebrow()
                        .padding(.bottom, Space.s3)
                    Text(OnbCopy.string("onb.s10.headline"))
                        .font(BedrockFont.title)
                        .lineSpacing(BedrockLine.title.lineSpacing)
                        .foregroundStyle(BedrockColor.inkPrimary)
                    Text(OnbCopy.string("onb.s10.headline_2"))
                        .font(BedrockFont.accentItalic)
                        .foregroundStyle(BedrockColor.emberGlow)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                if let lit {
                    GauntletPath(steps: steps, lit: lit) { step in
                        flow.track(.gauntletStepOpened(step: step))
                    }
                }

                VStack(alignment: .leading, spacing: Space.s2) {
                    Text(OnbCopy.string("onb.s10.footer"))
                        .font(BedrockFont.titleS)
                        .lineSpacing(BedrockLine.titleS.lineSpacing)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    LinkButton(title: OnbCopy.string("onb.s10.link"), tone: .secondary) {
                        flow.track(.limitsOpened)
                        limitsShown = true
                    }
                }
                .opacity(footerShown ? 1 : 0)
                .animation(BedrockMotion.reducedFade, value: footerShown)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s10.primary")) { flow.go(.s11) }
                .bedrockAppear(.settle, delay: BedrockTiming.s10PrimaryAt)
        }
        .bedrockSheet(isPresented: $limitsShown, title: OnbCopy.parts("onb.s10.limits_sheet").first ?? "") {
            LimitsSheet { limitsShown = false }
        }
        .onAppear {
            guard lit == nil else { return }
            lit = flow.state.pathPlayed
        }
        .task {
            if lit == true || reduceMotion {
                footerShown = true
            } else {
                try? await Task.sleep(for: .seconds(BedrockTiming.pathFooter))
                footerShown = true
            }
        }
        .onDisappear { flow.update { $0.pathPlayed = true } }
    }
}

/// “What Strict Mode can't stop”: four honest limits, a closing line, Got it.
private struct LimitsSheet: View {
    let close: () -> Void

    var body: some View {
        let parts = OnbCopy.parts("onb.s10.limits_sheet")
        let rows = Array(parts.dropFirst().prefix(4))
        VStack(alignment: .leading, spacing: Space.s3) {
            ForEach(rows, id: \.self) { row in
                HStack(alignment: .firstTextBaseline, spacing: Space.s3) {
                    Circle()
                        .fill(BedrockColor.emberGlow)
                        .frame(width: BedrockSize.statusDot, height: BedrockSize.statusDot)
                        .accessibilityHidden(true)
                    Text(row)
                        .font(BedrockFont.body)
                        .foregroundStyle(BedrockColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        if parts.count > 5 {
            Text(parts[5])
                .font(BedrockFont.titleS)
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.s2)
        }
        PrimaryButton(title: parts.last ?? "", action: close)
            .padding(.top, Space.s3)
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
            VStack(alignment: .leading, spacing: Space.s7) {
                if !RemoteConfig.strictModeSupported {
                    VersionBanner(text: OnbCopy.string("onb.s11.version_banner"))
                }
                ScreenHeading(eyebrow: OnbCopy.string("onb.s11.eyebrow"),
                              headline: OnbCopy.string("onb.s11.headline"),
                              text: OnbCopy.string("onb.s11.body"))
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
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s11.primary"), isEnabled: holder != nil,
                          disabledHint: OnbCopy.string("onb.common.pick_at_least_one")) { next() }
        }
        .bedrockSheet(isPresented: $sheetShown, title: OnbCopy.parts("onb.s11.sheet").first ?? "") {
            let parts = OnbCopy.parts("onb.s11.sheet")
            Text(item(parts, 1))
                .font(BedrockFont.body)
                .lineSpacing(BedrockLine.body.lineSpacing)
                .foregroundStyle(BedrockColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: item(parts, 2)) { sheetShown = false }
                .padding(.top, Space.s3)
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

/// S11's banner when Strict Mode isn't verified on this iOS. Read first.
struct VersionBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Space.s3) {
            Image(systemName: "info.circle")
                .foregroundStyle(BedrockColor.emberGlow)
                .accessibilityHidden(true)
            Text(text)
                .font(BedrockFont.subhead)
                .foregroundStyle(BedrockColor.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(BedrockColor.emberWash))
        .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(BedrockColor.emberDeep))
        .accessibilityElement(children: .combine)
        .accessibilitySortPriority(1)
    }
}
