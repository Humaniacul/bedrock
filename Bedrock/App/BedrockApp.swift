import SwiftUI

@main
struct BedrockApp: App {
    @State private var services = AppServices.makeLive()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(services)
                .preferredColorScheme(.dark) // Bedrock is dark by design (§6)
                .tint(Theme.accent)
        }
    }
}
