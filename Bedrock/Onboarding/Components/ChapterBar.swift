import SwiftUI

/// Four segments — Wall, You, Lock, Begin — 6pt apart: a 3pt track (`lineSubtle`)
/// filling with ember, its label 5pt under it in mono 9.5pt at +1.6, Chalk for
/// the current chapter and Ash for the rest. Earlier chapters are full. One
/// VoiceOver element: “Chapter 2 of 4, You.”
struct ChapterBar: View {
    let current: Chapter
    /// 0–1 within the current chapter.
    let progress: Double

    private var chapters: [Chapter] { Chapter.barChapters }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(chapters, id: \.self) { chapter in
                VStack(alignment: .leading, spacing: 5) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(BedrockColor.lineSubtle)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(BedrockColor.ember)
                                .frame(width: proxy.size.width * fill(for: chapter))
                        }
                    }
                    .frame(height: BedrockSize.chapterTrack)
                    Text(label(for: chapter))
                        .ptype(.chapter)
                        .textCase(.uppercase)
                        .foregroundStyle(chapter == current ? BedrockColor.inkPrimary : BedrockColor.inkTertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .animation(BedrockMotion.chapterFill, value: progress)
        .animation(BedrockMotion.chapterFill, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
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
