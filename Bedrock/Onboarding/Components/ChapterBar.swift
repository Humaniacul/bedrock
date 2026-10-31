import SwiftUI

/// Four segments — Wall, You, Lock, Begin — showing where the person is in the
/// flow (COMPONENTS.md). Earlier chapters are full, the current one fills with
/// `progress`, later ones are empty. One VoiceOver element: “Chapter 2 of 4, You.”
struct ChapterBar: View {
    let current: Chapter
    /// 0–1 within the current chapter.
    let progress: Double

    private var chapters: [Chapter] { Chapter.barChapters }

    var body: some View {
        HStack(alignment: .top, spacing: Space.s2) {
            ForEach(chapters, id: \.self) { chapter in
                ChapterSegment(label: label(for: chapter),
                               fill: fill(for: chapter),
                               isCurrent: chapter == current)
            }
        }
        // Chrome, like a tab bar: capped so four labels fit side by side, with the
        // large content viewer for anyone who needs them bigger. The segments read
        // their scaled size inside this cap.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .animation(BedrockMotion.chapterFill, value: progress)
        .animation(BedrockMotion.chapterFill, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityShowsLargeContentViewer {
            Text(label(for: current))
        }
    }

    private func fill(for chapter: Chapter) -> Double {
        guard let index = chapters.firstIndex(of: chapter),
              let currentIndex = chapters.firstIndex(of: current) else { return 0 }
        if index < currentIndex { return 1 }
        if index > currentIndex { return 0 }
        return min(max(progress, 0), 1)
    }

    private func label(for chapter: Chapter) -> String {
        chapter.barLabelKey.map(OnbCopy.string) ?? ""
    }

    private var accessibilityText: String {
        let number = (chapters.firstIndex(of: current) ?? 0) + 1
        return OnbCopy.format("onb.common.chapter_a11y", number, chapters.count, label(for: current))
    }
}

/// One track and its label: 3pt `lineSubtle` track, `ember` fill, SF Mono 9.5pt
/// uppercase at +1.6 tracking; the current label in `inkPrimary`, the rest `inkTertiary`.
private struct ChapterSegment: View {
    let label: String
    let fill: Double
    let isCurrent: Bool

    @ScaledMetric(relativeTo: .caption2) private var labelSize = BedrockSize.chapterLabel

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(BedrockColor.lineSubtle)
                    Capsule()
                        .fill(BedrockColor.ember)
                        .frame(width: proxy.size.width * fill)
                }
            }
            .frame(height: BedrockSize.chapterTrack)

            Text(label)
                .font(BedrockFont.chapterLabel(size: labelSize))
                .tracking(BedrockLine.chapterLabel.tracking)
                .textCase(.uppercase)
                .foregroundStyle(isCurrent ? BedrockColor.inkPrimary : BedrockColor.inkTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
struct ChapterBarPreview: View {
    var body: some View {
        PreviewPage(alignment: .top) {
            VStack(spacing: Space.s8) {
                ChapterBar(current: .wall, progress: 0.25)
                ChapterBar(current: .you, progress: 0.5)
                ChapterBar(current: .lock, progress: 1)
                ChapterBar(current: .begin, progress: 0.75)
            }
            .padding(.top, BedrockSize.chapterBarTop)
        }
    }
}

#Preview("ChapterBar · 402×874", traits: .fixedLayout(width: 402, height: 874)) { ChapterBarPreview().onboardingPreview(.standard) }
#Preview("ChapterBar · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ChapterBarPreview().onboardingPreview(.reduceMotion) }
#Preview("ChapterBar · AX5", traits: .fixedLayout(width: 402, height: 874)) { ChapterBarPreview().onboardingPreview(.ax5) }
#Preview("ChapterBar · AX5 · Reduce Motion", traits: .fixedLayout(width: 402, height: 874)) { ChapterBarPreview().onboardingPreview(.ax5ReduceMotion) }
#endif
