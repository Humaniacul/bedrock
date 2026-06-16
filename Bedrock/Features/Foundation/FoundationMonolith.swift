import SwiftUI

/// The signature element (§6.4): a monolith of strata rising from deep bedrock
/// toward the lit top — one layer per day clean. Milestone layers carry a bronze
/// seam; the current (top) stratum shows a fracture when cracked, which the
/// recovery flow repairs. The carved count is the source of truth; the drawing
/// shows the most recent `maxVisible` strata with the depth below implied.
struct FoundationMonolith: View {
    let foundationDays: Int
    var hasCrack: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let maxVisible = 16
    private var visible: Int { min(max(foundationDays, 1), maxVisible) }
    /// Day numbers drawn, top (current) first.
    private var dayNumbers: [Int] { (0..<visible).map { foundationDays - $0 } }
    private var hasDepthBelow: Bool { foundationDays > maxVisible }
    private var milestoneDays: Set<Int> { Set(Milestone.ladder.map(\.day)) }

    var body: some View {
        VStack(spacing: 3) {
            ForEach(dayNumbers, id: \.self) { day in
                stratum(day: day, isTop: day == foundationDays)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            if hasDepthBelow {
                depthFade
            }
        }
        .frame(width: 154)
        .shadow(color: BedrockColor.ember.opacity(0.22), radius: 26, y: 10)
        .animation(Theme.Motion.reduced(Theme.Motion.stoneSet, when: reduceMotion), value: foundationDays)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your foundation")
        .accessibilityValue(accessibilityValue)
    }

    private func stratum(day: Int, isTop: Bool) -> some View {
        let warmth = 1 - Double(visible - position(of: day) - 1) / Double(max(visible - 1, 1))
        let isMilestone = milestoneDays.contains(day)
        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(BedrockColor.basalt.mix(with: BedrockColor.bronze, by: warmth * 0.55))
            .frame(height: 24)
            .overlay(alignment: .leading) {
                if isMilestone {
                    // Milestone seam — a thin bronze band running the layer.
                    Rectangle()
                        .fill(BedrockColor.bronze)
                        .frame(height: 2)
                        .shadow(color: BedrockColor.ember.opacity(0.6), radius: 4)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Theme.textPrimary.opacity(0.05), lineWidth: 1)
            }
            .overlay {
                if isTop && hasCrack {
                    fracture
                }
            }
    }

    private var fracture: some View {
        // A repairable fracture, not a demolition (§6.4).
        Capsule()
            .fill(BedrockColor.ember.opacity(0.8))
            .frame(width: 3, height: 18)
            .rotationEffect(.degrees(16))
            .shadow(color: BedrockColor.ember.opacity(0.7), radius: 5)
    }

    private var depthFade: some View {
        // Implies the foundation continuing down into bedrock.
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [BedrockColor.basalt, BedrockColor.obsidian],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(height: 18)
            .opacity(0.8)
    }

    private func position(of day: Int) -> Int { foundationDays - day }

    private var accessibilityValue: String {
        var value = "\(foundationDays) \(foundationDays == 1 ? "stratum" : "strata") high"
        if let milestone = Milestone.ladder.last(where: { $0.day <= foundationDays }) {
            value += ", current layer \(milestone.name)"
        }
        if hasCrack { value += ", one cracked layer to repair" }
        return value
    }
}

#Preview("Rising") {
    ZStack {
        StoneBackground(emberGlow: 0.18)
        HStack(spacing: 44) {
            FoundationMonolith(foundationDays: 7)
            FoundationMonolith(foundationDays: 31, hasCrack: true)
        }
    }
}
