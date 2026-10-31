import SwiftUI

// Begin · Quiet heads-ups, press it once (SPEC.md S14, S15).

// MARK: - S14 · Quiet heads-ups

struct HeadsUpScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @State private var asking = false

    private var hasPattern: Bool { flow.state.hours.contains { $0.window != nil } }

    /// A few minutes before their first S5 window: the S5 payoff, seen before iOS asks.
    private var previewTime: Date {
        Reminders.nextHeadsUp(for: flow.state.hours) ?? .now
    }

    var body: some View {
        let preview = OnbCopy.parts("onb.s14.preview")
        OnboardingScaffold(.s14, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s7) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s14.eyebrow"),
                              headline: OnbCopy.string("onb.s14.headline"),
                              text: OnbCopy.string(hasPattern ? "onb.s14.body" : "onb.s14.body_no_pattern"))
                VStack(spacing: Space.s3) {
                    NotificationPreview(time: previewTime,
                                        appName: preview.first ?? "",
                                        now: preview.dropFirst().first ?? "",
                                        message: preview.last ?? "")
                        .bedrockAppear(.settle, delay: 0.2)
                    Text(OnbCopy.string("onb.s14.caption"))
                        .font(BedrockFont.footnote)
                        .foregroundStyle(BedrockColor.inkTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s14.primary"), isLoading: asking) {
                Task { await ask() }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.45))
            BedrockHaptics.stoneLands()
        }
    }

    /// One button; iOS asks; either answer moves on.
    private func ask() async {
        flow.track(.notifPrompted)
        asking = true
        let granted = await NotificationPermission.request()
        asking = false
        flow.track(.notifResult(granted: granted))
        if granted { await Reminders.scheduleHeadsUps(for: flow.state.hours) }
        flow.go(.s15)
    }
}

// MARK: - S15 · Press it once

struct PressOnceScreen: View {
    @Environment(FirstLightFlow.self) private var flow

    enum Phase { case waiting, breathing, done }
    @State private var phase: Phase = .waiting

    var body: some View {
        let breathe = OnbCopy.parts("onb.s15.breathe")
        OnboardingScaffold(.s15, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: Space.s8) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s15.eyebrow"),
                              headline: OnbCopy.string("onb.s15.headline"),
                              text: OnbCopy.string("onb.s15.body"))
                ZStack {
                    switch phase {
                    case .waiting:
                        UrgeButton(title: OnbCopy.string("onb.s15.button"), style: .circle,
                                   accessibilityHint: OnbCopy.string("onb.s15.a11y_button")) {
                            withAnimation(BedrockMotion.expand) { phase = .breathing }
                        }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    case .breathing, .done:
                        BreathRing(inLabel: breathe.first ?? "", outLabel: breathe.last ?? "") {
                            flow.track(.interceptRehearsed)
                            withAnimation(BedrockMotion.reducedFade) { phase = .done }
                        }
                        .transition(.scale(scale: 1.1).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: BedrockSize.urgeCircle)

                if phase == .done {
                    Text(OnbCopy.string("onb.s15.closing"))
                        .font(BedrockFont.titleS)
                        .lineSpacing(BedrockLine.titleS.lineSpacing)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .bedrockAppear(.rise)
                }
            }
        } footer: {
            if phase == .done {
                PrimaryButton(title: OnbCopy.string("onb.s15.primary")) { flow.finish() }
                    .bedrockAppear(.settle, delay: 0.3)
            }
        }
    }
}
