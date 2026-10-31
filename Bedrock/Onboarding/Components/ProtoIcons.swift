import SwiftUI

// The prototype's icons and stone shapes, from its SVG paths and clip-paths,
// drawn in their own viewBox and scaled to the frame they're given.

/// A path drawn in `viewBox` coordinates, scaled to fill the frame.
struct ViewBoxShape: Shape {
    let viewBox: CGSize
    let path: Path

    func path(in rect: CGRect) -> Path {
        let scale = CGAffineTransform(scaleX: rect.width / viewBox.width, y: rect.height / viewBox.height)
        return path.applying(scale).offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// A CSS `clip-path: polygon(…)`: points in unit coordinates.
struct UnitPolygon: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
        path.closeSubpath()
        return path
    }

    /// S1 and SP1's mark, the notification icon: polygon(14% 3%, 50% 0%, 86% 4%, 100% 100%, 0% 100%).
    static let mark = UnitPolygon(points: [
        CGPoint(x: 0.14, y: 0.03), CGPoint(x: 0.50, y: 0), CGPoint(x: 0.86, y: 0.04),
        CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1),
    ])
    /// The foundation stone: polygon(13% 2%, 50% 0%, 87% 3%, 100% 100%, 0% 100%).
    static let foundation = UnitPolygon(points: [
        CGPoint(x: 0.13, y: 0.02), CGPoint(x: 0.50, y: 0), CGPoint(x: 0.87, y: 0.03),
        CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1),
    ])
    /// The hold control's glyph: polygon(14% 4%, 86% 0%, 100% 100%, 0% 100%).
    static let holdGlyph = UnitPolygon(points: [
        CGPoint(x: 0.14, y: 0.04), CGPoint(x: 0.86, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1),
    ])
    /// S13.6's capstone: polygon(12% 0, 88% 0, 100% 100%, 0 100%).
    static let keystone = UnitPolygon(points: [
        CGPoint(x: 0.12, y: 0), CGPoint(x: 0.88, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1),
    ])
}

enum ProtoIcon {
    /// S2's shield (44 × 52).
    static let shield = ViewBoxShape(viewBox: CGSize(width: 44, height: 52), path: Path { p in
        p.move(to: CGPoint(x: 22, y: 3))
        p.addLine(to: CGPoint(x: 39, y: 9))
        p.addLine(to: CGPoint(x: 39, y: 24))
        p.addCurve(to: CGPoint(x: 22, y: 49), control1: CGPoint(x: 39, y: 36), control2: CGPoint(x: 31.5, y: 44.5))
        p.addCurve(to: CGPoint(x: 5, y: 24), control1: CGPoint(x: 12.5, y: 44.5), control2: CGPoint(x: 5, y: 36))
        p.addLine(to: CGPoint(x: 5, y: 9))
        p.closeSubpath()
    })
    /// The check inside S2's shield.
    static let shieldCheck = ViewBoxShape(viewBox: CGSize(width: 44, height: 52), path: Path { p in
        p.move(to: CGPoint(x: 14.5, y: 26.5))
        p.addLine(to: CGPoint(x: 20, y: 32))
        p.addLine(to: CGPoint(x: 29.5, y: 21))
    })
    /// A check mark (12 × 12): chips, rows, the practice “done”.
    static let check = ViewBoxShape(viewBox: CGSize(width: 12, height: 12), path: Path { p in
        p.move(to: CGPoint(x: 2.5, y: 6.2))
        p.addLine(to: CGPoint(x: 5, y: 8.6))
        p.addLine(to: CGPoint(x: 9.6, y: 3.6))
    })
    /// Back (12 × 20).
    static let chevronLeft = ViewBoxShape(viewBox: CGSize(width: 12, height: 20), path: Path { p in
        p.move(to: CGPoint(x: 10, y: 2))
        p.addLine(to: CGPoint(x: 2, y: 10))
        p.addLine(to: CGPoint(x: 10, y: 18))
    })
    /// Row chevron (8 × 14).
    static let chevronRight = ViewBoxShape(viewBox: CGSize(width: 8, height: 14), path: Path { p in
        p.move(to: CGPoint(x: 1.5, y: 1.5))
        p.addLine(to: CGPoint(x: 6.5, y: 7))
        p.addLine(to: CGPoint(x: 1.5, y: 12.5))
    })
    /// Close (14 × 14).
    static let close = ViewBoxShape(viewBox: CGSize(width: 14, height: 14), path: Path { p in
        p.move(to: CGPoint(x: 2, y: 2)); p.addLine(to: CGPoint(x: 12, y: 12))
        p.move(to: CGPoint(x: 12, y: 2)); p.addLine(to: CGPoint(x: 2, y: 12))
    })
    /// Lock body (14 × 18): the filled S3 row icon and the privacy note's outline.
    static let lockBody = ViewBoxShape(viewBox: CGSize(width: 14, height: 18),
                                       path: Path(roundedRect: CGRect(x: 1.5, y: 7.5, width: 11, height: 9), cornerRadius: 2))
    static let lockShackle = ViewBoxShape(viewBox: CGSize(width: 14, height: 18), path: Path { p in
        p.move(to: CGPoint(x: 4, y: 7.5))
        p.addLine(to: CGPoint(x: 4, y: 5))
        p.addArc(center: CGPoint(x: 7, y: 5), radius: 3, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: 10, y: 7.5))
    })
    /// S3 row 2 (18 × 18): four rounded squares.
    static let grid = ViewBoxShape(viewBox: CGSize(width: 18, height: 18), path: Path { p in
        for origin in [CGPoint(x: 1.5, y: 1.5), CGPoint(x: 10.5, y: 1.5), CGPoint(x: 1.5, y: 10.5), CGPoint(x: 10.5, y: 10.5)] {
            p.addRoundedRect(in: CGRect(origin: origin, size: CGSize(width: 6, height: 6)), cornerSize: CGSize(width: 1.6, height: 1.6))
        }
    })
    /// S3 row 3 (18 × 18): a clock.
    static let clock = ViewBoxShape(viewBox: CGSize(width: 18, height: 18), path: Path { p in
        p.addEllipse(in: CGRect(x: 1.8, y: 1.8, width: 14.4, height: 14.4))
        p.move(to: CGPoint(x: 9, y: 4.8))
        p.addLine(to: CGPoint(x: 9, y: 9))
        p.addLine(to: CGPoint(x: 12, y: 11))
    })
    /// The foundation's demo crack, in the stone's 176 × 266 box.
    static let crack = ViewBoxShape(viewBox: CGSize(width: 176, height: 266), path: Path { p in
        let points: [CGPoint] = [
            CGPoint(x: 18, y: 196), CGPoint(x: 46, y: 184), CGPoint(x: 58, y: 192), CGPoint(x: 84, y: 174),
            CGPoint(x: 97, y: 181), CGPoint(x: 121, y: 165), CGPoint(x: 135, y: 171), CGPoint(x: 162, y: 158),
        ]
        p.addLines(points)
    })

    // SP2 (26 × 18)
    static let spWallTop = ViewBoxShape(viewBox: CGSize(width: 26, height: 18), path: Path { p in
        p.addRoundedRect(in: CGRect(x: 1, y: 1, width: 11, height: 7), cornerSize: CGSize(width: 1.6, height: 1.6))
        p.addRoundedRect(in: CGRect(x: 14, y: 1, width: 11, height: 7), cornerSize: CGSize(width: 1.6, height: 1.6))
        p.addRoundedRect(in: CGRect(x: 8, y: 10, width: 11, height: 7), cornerSize: CGSize(width: 1.6, height: 1.6))
    })
    static let spWallHalves = ViewBoxShape(viewBox: CGSize(width: 26, height: 18), path: Path { p in
        p.addRoundedRect(in: CGRect(x: 1, y: 10, width: 5, height: 7), cornerSize: CGSize(width: 1.6, height: 1.6))
        p.addRoundedRect(in: CGRect(x: 21, y: 10, width: 4, height: 7), cornerSize: CGSize(width: 1.6, height: 1.6))
    })
    static let spKey = ViewBoxShape(viewBox: CGSize(width: 26, height: 18), path: Path { p in
        p.addEllipse(in: CGRect(x: 1.8, y: 3.8, width: 10.4, height: 10.4))
        p.move(to: CGPoint(x: 12.2, y: 9)); p.addLine(to: CGPoint(x: 24, y: 9))
        p.move(to: CGPoint(x: 20, y: 9)); p.addLine(to: CGPoint(x: 20, y: 13))
        p.move(to: CGPoint(x: 24, y: 9)); p.addLine(to: CGPoint(x: 24, y: 12))
    })
    static let spPulse = ViewBoxShape(viewBox: CGSize(width: 26, height: 18), path: Path { p in
        p.move(to: CGPoint(x: 1, y: 10)); p.addLine(to: CGPoint(x: 5, y: 10)); p.addLine(to: CGPoint(x: 7.5, y: 4))
        p.addLine(to: CGPoint(x: 11, y: 15)); p.addLine(to: CGPoint(x: 14, y: 8)); p.addLine(to: CGPoint(x: 16.5, y: 8))
    })
    static let spPulseTail = ViewBoxShape(viewBox: CGSize(width: 26, height: 18), path: Path { p in
        p.move(to: CGPoint(x: 19, y: 10)); p.addLine(to: CGPoint(x: 25, y: 10))
    })
    static let spEyeSlash = ViewBoxShape(viewBox: CGSize(width: 26, height: 18), path: Path { p in
        p.move(to: CGPoint(x: 2, y: 9))
        p.addCurve(to: CGPoint(x: 13, y: 2), control1: CGPoint(x: 5, y: 4), control2: CGPoint(x: 9, y: 2))
        p.addCurve(to: CGPoint(x: 24, y: 9), control1: CGPoint(x: 17, y: 2), control2: CGPoint(x: 21, y: 4))
        p.addCurve(to: CGPoint(x: 13, y: 16), control1: CGPoint(x: 21, y: 14), control2: CGPoint(x: 17, y: 16))
        p.addCurve(to: CGPoint(x: 2, y: 9), control1: CGPoint(x: 9, y: 16), control2: CGPoint(x: 5, y: 14))
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: 10, y: 6, width: 6, height: 6))
        p.move(to: CGPoint(x: 4, y: 16)); p.addLine(to: CGPoint(x: 22, y: 2))
    })
}

// MARK: - Small composed icons

/// A filled ember circle with a dark check (S3 rows, chips).
struct CheckDot: View {
    var size: CGFloat = 24
    var checkSize: CGFloat = 12
    var fill: Color = BedrockColor.ember
    var stroke: Color = BedrockColor.bgBase

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: size, height: size)
            .overlay {
                ProtoIcon.check
                    .stroke(stroke, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .frame(width: checkSize, height: checkSize)
            }
            .accessibilityHidden(true)
    }
}

/// The privacy note's lock, outlined (12 × 15).
struct LockOutline: View {
    var color: Color = BedrockColor.inkTertiary

    var body: some View {
        ZStack {
            ProtoIcon.lockBody.stroke(color, lineWidth: 1.6 * 12 / 14)
            ProtoIcon.lockShackle.stroke(color, lineWidth: 1.6 * 12 / 14)
        }
        .frame(width: 12, height: 15)
        .accessibilityHidden(true)
    }
}

/// The standing-stone mark (S1, SP1, the notification icon), gradient at 160°.
struct StoneMarkView: View {
    var top: Color = BedrockColor.markHi
    var bottom: Color = BedrockColor.markLo

    var body: some View {
        UnitPolygon.mark
            .fill(LinearGradient(colors: [top, bottom], startPoint: UnitPoint(x: 0.33, y: 0), endPoint: UnitPoint(x: 0.67, y: 1)))
            .accessibilityHidden(true)
    }
}
