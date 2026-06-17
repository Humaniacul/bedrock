import SwiftUI

struct StoneParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    let birth: TimeInterval
    let lifetime: Double
    let size: CGFloat
}

/// A lightweight, GPU-friendly particle burst layer (Canvas + TimelineView).
/// Bump `trigger` to emit a burst at `origin` (or a random point in bounds).
/// Renders nothing under Reduce Motion; capped and self-pruning for performance.
struct StoneParticles: View {
    var trigger: Int
    var origin: CGPoint? = nil
    var color: Color = BedrockColor.ash
    var burst: Int = 4
    var gravity: CGFloat = 360
    /// `true` = embers drift upward; `false` = dust falls.
    var rise: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [StoneParticle] = []
    @State private var lastTrigger = 0

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: particles.isEmpty)) { timeline in
                Canvas { ctx, _ in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for p in particles {
                        let age = now - p.birth
                        guard age >= 0, age < p.lifetime else { continue }
                        let t = CGFloat(age)
                        let g = rise ? -gravity : gravity
                        let x = p.position.x + p.velocity.dx * t
                        let y = p.position.y + p.velocity.dy * t + 0.5 * g * t * t
                        let opacity = 1 - age / p.lifetime
                        let rect = CGRect(x: x - p.size / 2, y: y - p.size / 2, width: p.size, height: p.size)
                        ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity)))
                    }
                }
                .onChange(of: timeline.date) { _, newDate in
                    prune(now: newDate.timeIntervalSinceReferenceDate)
                }
            }
            .onChange(of: trigger) { _, newValue in
                guard !reduceMotion, newValue != lastTrigger else { return }
                lastTrigger = newValue
                emit(in: geo.size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func emit(in size: CGSize) {
        guard size.width > 0 else { return }
        let now = Date.timeIntervalSinceReferenceDate
        let point = origin ?? CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height))
        for _ in 0..<burst {
            let angle = Double.random(in: (.pi * 0.15)...(.pi * 0.85)) // mostly sideways/up
            let speed = CGFloat.random(in: 26...80)
            let velocity = CGVector(dx: cos(angle) * speed * (Bool.random() ? 1 : -1),
                                    dy: -CGFloat(sin(angle)) * speed)
            particles.append(StoneParticle(
                position: point, velocity: velocity, birth: now,
                lifetime: Double.random(in: 0.5...0.95),
                size: CGFloat.random(in: 1.5...3.5)))
        }
        if particles.count > 140 { particles.removeFirst(particles.count - 140) }
    }

    private func prune(now: TimeInterval) {
        if particles.contains(where: { now - $0.birth > $0.lifetime }) {
            particles.removeAll { now - $0.birth > $0.lifetime }
        }
    }
}
