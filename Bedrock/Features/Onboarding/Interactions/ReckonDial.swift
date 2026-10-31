import SwiftUI

/// Reckon (spec v2 S4): a vertical bar of dawn-light — one day. The user drags
/// upward and shadow eats the light in proportion to their own honest estimate.
/// No fabricated figure, ever: the number on this screen is theirs.
struct ReckonDial: View {
    /// Fraction of the day taken (0…1), owned by the model.
    @Binding var value: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastTickBucket = 0

    private let barWidth: CGFloat = 84
    private let barHeight: CGFloat = 300

    var body: some View {
        ZStack(alignment: .bottom) {
            // One day of light.
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(LinearGradient(
                    colors: [BedrockColor.emberGlow.opacity(0.85), Theme.accent.opacity(0.5), BedrockColor.bronze.opacity(0.35)],
                    startPoint: .top, endPoint: .bottom))
            // The shadow it takes — rises from the bottom under their thumb.
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Color.black.opacity(0.78))
                .frame(height: max(0, barHeight * value))
                .frame(maxWidth: .infinity)
            // The dial line at the boundary.
            Capsule()
                .fill(BedrockColor.quartz)
                .frame(width: barWidth + 22, height: 3)
                .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                .offset(y: -barHeight * value + 1.5)
        }
        .frame(width: barWidth, height: barHeight)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.hairline))
        .contentShape(Rectangle().inset(by: -24)) // easy to grab
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let fraction = 1 - (drag.location.y / barHeight)
                    setValue(min(1, max(0, fraction)))
                }
        )
        .accessibilityElement()
        .accessibilityLabel("How much of your day it takes")
        .accessibilityValue(accessibilityReading)
        .accessibilityHint("Swipe up or down to adjust your honest estimate")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: setValue(min(1, value + 0.1))
            case .decrement: setValue(max(0, value - 0.1))
            @unknown default: break
            }
        }
    }

    private var accessibilityReading: String {
        switch value {
        case ..<0.1:  "A sliver of the day"
        case ..<0.25: "An hour or two"
        case ..<0.45: "A few hours"
        case ..<0.7:  "Half the day"
        default:      "Most of the day"
        }
    }

    /// Haptic deepens as the shadow rises — soft ticks, heavier at landmarks.
    private func setValue(_ new: Double) {
        let old = value
        value = new
        guard !reduceMotion else { return }
        let bucket = Int(new * 10)
        if bucket != lastTickBucket {
            lastTickBucket = bucket
            if bucket == 2 || bucket == 5 || bucket == 7 {
                BedrockHaptics.set()
            } else if abs(new - old) > 0.001 {
                BedrockHaptics.selection()
            }
        }
    }
}
