import Foundation
import SwiftUI

// The one place Liquid Glass is applied (§6.3, §10.7). Every glass surface in
// the app goes through `bedrockGlass(in:)`, which ships the MANDATORY Reduce
// Transparency fallback: a solid `surface` fill + hairline border instead of
// `.glassEffect`. Never call `.glassEffect` directly in a screen.

/// Lets us force the solid fallback in DEBUG (e.g. `BEDROCK_FORCE_SOLID=1`) to
/// verify the Reduce Transparency path without toggling an OS setting. Always
/// `false` in release.
enum GlassDebug {
    #if DEBUG
    static let forceSolid = ProcessInfo.processInfo.environment["BEDROCK_FORCE_SOLID"] == "1"
    #else
    static let forceSolid = false
    #endif
}

struct BedrockGlass<S: InsettableShape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: S
    var tint: Color?

    func body(content: Content) -> some View {
        if reduceTransparency || GlassDebug.forceSolid {
            content
                .background(shape.fill(Theme.surface))
                .overlay(shape.strokeBorder(Theme.hairline, lineWidth: 1))
        } else {
            content.glassEffect(glass, in: shape)
        }
    }

    private var glass: Glass {
        if let tint { return Glass.regular.tint(tint) }
        return .regular
    }
}

extension View {
    /// Applies Liquid Glass clipped to `shape`, with an automatic solid fallback
    /// under Reduce Transparency. The single entry point for glass in Bedrock.
    func bedrockGlass<S: InsettableShape>(in shape: S, tint: Color? = nil) -> some View {
        modifier(BedrockGlass(shape: shape, tint: tint))
    }
}
