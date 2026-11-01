import SwiftUI

// Begin · Quiet heads-ups, press it once (SPEC.md S14, S15).

// MARK: - S14 · Quiet heads-ups

struct HeadsUpScreen: View {
    @Environment(FirstLightFlow.self) private var flow
    @State private var asking = false

    /// The first hard hour they picked that has a time.
    private var firstBand: HourBand? { flow.state.hours.first { $0.window != nil } }

    /// 15 minutes before that window, on the day it next comes round: the S5
    /// payoff, seen before iOS asks. No pattern: today, 9:41.
    private var preview: (date: String, time: String) {
        guard let firstBand, let next = Reminders.nextHeadsUp(for: [firstBand]) else {
            return (Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()), "9:41")
        }
        return (next.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                next.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute(.twoDigits)))
    }

    var body: some View {
        let parts = OnbCopy.parts("onb.s14.preview")
        let shown = preview
        OnboardingScaffold(.s14, flow: flow, back: false) {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s14.eyebrow"),
                              headline: OnbCopy.string("onb.s14.headline"),
                              headlineType: .titleM,
                              headlineGap: 14,
                              text: OnbCopy.string(firstBand != nil ? "onb.s14.body" : "onb.s14.body_no_pattern"))
                Spacer(minLength: Space.s4)
                NotificationPreview(date: shown.date, time: shown.time,
                                    appName: parts.first ?? "",
                                    now: parts.dropFirst().first ?? "",
                                    message: parts.last ?? "",
                                    accessibilityText: OnbCopy.string("onb.common.a11y_notification")
                                        .replacingOccurrences(of: "{message}", with: parts.last ?? ""))
                    .frame(maxWidth: .infinity)
                Spacer(minLength: Space.s4)
            }
        } footer: {
            Text(OnbCopy.string("onb.s14.caption"))
                .ptype(.subheadPlain)
                .foregroundStyle(BedrockColor.inkTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, Space.s3)
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
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeading(eyebrow: OnbCopy.string("onb.s15.eyebrow"),
                              headline: OnbCopy.string("onb.s15.headline"),
                              text: OnbCopy.string("onb.s15.body"))
                Spacer(minLength: Space.s6)
                ZStack {
                    switch phase {
                    case .waiting:
                        UrgeCircle(title: OnbCopy.string("onb.s15.button"),
                                   accessibilityHint: OnbCopy.string("onb.s15.a11y_button")) {
                            withAnimation(BedrockMotion.reducedFade) { phase = .breathing }
                        }
                        .transition(.opacity)
                    case .breathing, .done:
                        BreathRing(inLabel: breathe.first ?? "", outLabel: breathe.last ?? "") {
                            flow.track(.interceptRehearsed)
                            withAnimation(BedrockMotion.reducedFade) { phase = .done }
                        }
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer(minLength: Space.s6)
            }
        } footer: {
            if phase == .done {
                VStack(spacing: 0) {
                    Text(OnbCopy.string("onb.s15.closing"))
                        .ptype(.body)
                        .foregroundStyle(BedrockColor.inkPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 18)
                        .bedrockAppear(.rise)
                    PrimaryButton(title: OnbCopy.string("onb.s15.primary")) { flow.finish() }
                        .bedrockAppear(.settle, delay: 0.3)
                }
            } else {
                Color.clear.frame(height: 122)
            }
        }
    }
}
