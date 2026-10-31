#if DEBUG
import SwiftUI

/// Shows one component preview page full-screen in the Simulator, so the
/// previews can be captured with `xcrun simctl io … screenshot / recordVideo`
/// (Xcode's canvas can't be captured from the command line). DEBUG only.
///
///   SIMCTL_CHILD_BEDROCK_GALLERY=<page>   one of `ComponentGalleryPage`
///   SIMCTL_CHILD_BEDROCK_GALLERY_AX5=1    accessibility text size AX5
///   SIMCTL_CHILD_BEDROCK_GALLERY_RM=1     Reduce Motion on
enum ComponentGalleryPage: String, CaseIterable {
    case scaffold, scaffoldAccessory, chapterBar, primaryButton, textButton, linkButton
    case choiceChip, bedrockSheet, toast, privacyCover, motionReel
}

struct ComponentGallery: View {
    let page: ComponentGalleryPage
    let variant: OnboardingPreviewVariant

    /// The page requested by the launch environment, if any.
    static var requested: ComponentGallery? {
        let env = ProcessInfo.processInfo.environment
        guard let raw = env["BEDROCK_GALLERY"], let page = ComponentGalleryPage(rawValue: raw) else { return nil }
        let ax5 = env["BEDROCK_GALLERY_AX5"] == "1"
        let reduceMotion = env["BEDROCK_GALLERY_RM"] == "1"
        let variant: OnboardingPreviewVariant = switch (ax5, reduceMotion) {
        case (false, false): .standard
        case (false, true): .reduceMotion
        case (true, false): .ax5
        case (true, true): .ax5ReduceMotion
        }
        return ComponentGallery(page: page, variant: variant)
    }

    var body: some View {
        content.onboardingPreview(variant)
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .scaffold: ScaffoldPreview()
        case .scaffoldAccessory: ScaffoldAccessoryPreview()
        case .chapterBar: ChapterBarPreview()
        case .primaryButton: PrimaryButtonPreview()
        case .textButton: TextButtonPreview()
        case .linkButton: LinkButtonPreview()
        case .choiceChip: ChoiceChipPreview()
        case .bedrockSheet: BedrockSheetPreview()
        case .toast: ToastPreview()
        case .privacyCover: PrivacyCoverPreview()
        case .motionReel: MotionReel()
        }
    }
}

/// A looping reel of the motion that differs with Reduce Motion: chips Strata in
/// (fade only when on), the chapter bar fills, the primary enables and loads, and
/// a toast drops in (fades when on). For recording the two settings side by side.
private struct MotionReel: View {
    private let chips = OnbCopy.parts("onb.s5.chips")
    @State private var cycle = 0
    @State private var progress = 0.0
    @State private var selection: Set<String> = []
    @State private var loading = false
    @State private var toast: String?

    var body: some View {
        OnboardingScaffold(screen: .s5, chapter: .you, chapterProgress: progress,
                           onBack: {}, onFinishLater: {}) {
            VStack(alignment: .leading, spacing: Space.s7) {
                PreviewHeading(prefix: "onb.s5")
                ChoiceChipGrid(options: chips, selection: $selection, exclusive: Set(chips.suffix(1)))
                    .id(cycle)
            }
        } footer: {
            PrimaryButton(title: OnbCopy.string("onb.s5.primary"), isEnabled: !selection.isEmpty,
                          isLoading: loading,
                          disabledHint: OnbCopy.string("onb.common.pick_at_least_one")) {}
        }
        .bedrockToast($toast)
        .task {
            while !Task.isCancelled {
                selection = []
                loading = false
                progress = 0.25
                cycle += 1
                try? await Task.sleep(for: .seconds(1.2))
                selection = Set(chips.prefix(1))
                try? await Task.sleep(for: .seconds(0.6))
                selection = Set(chips.prefix(2))
                progress = 0.75
                try? await Task.sleep(for: .seconds(0.8))
                loading = true
                toast = OnbCopy.string("onb.resume.toast")
                try? await Task.sleep(for: .seconds(3.4))
            }
        }
    }
}
#endif
