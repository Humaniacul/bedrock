import SwiftUI

/// On-device insights (§5, §7, §10.6). Surfaces the user's danger windows,
/// trigger mix, and recent urge log — all computed locally from the
/// `TriggerEngine`, never uploaded.
struct InsightsView: View {
    @Environment(AppServices.self) private var services

    private var triggers: TriggerEngine { services.triggers }
    private var hasData: Bool { !triggers.events.isEmpty }

    @State private var nudgesOn = false

    var body: some View {
        NavigationStack {
            ZStack {
                StoneBackground()
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        summary
                        if hasData {
                            heatmapCard
                            if !triggers.dangerWindows().isEmpty { dangerWindowsCard }
                            nudgeCard
                            if !triggers.triggerCounts().isEmpty { triggerBreakdownCard }
                            recentLogCard
                        } else {
                            emptyState
                        }
                        privacyFooter
                        #if DEBUG
                        Button("Seed sample data") { triggers.debugSeedSamples() }
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                        #endif
                    }
                    .padding(Theme.Spacing.xl)
                }
            }
            .navigationTitle("Insights")
            .onAppear { nudgesOn = services.nudges.isEnabled }
        }
    }

    // MARK: - Summary

    private var summary: some View {
        GlassCard {
            HStack(spacing: Theme.Spacing.lg) {
                stat("\(services.streak.foundationDays)", "Foundation")
                divider
                stat("\(services.streak.currentCleanStreak)", "Clean streak")
                divider
                stat("\(services.streak.longestCleanStreak)", "Longest")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Theme.hairline).frame(width: 1, height: 36)
    }

    // MARK: - Heatmap

    private var heatmapCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                cardTitle("When urges hit", "Darker = a tougher stretch for you.")
                DangerHeatmap(grid: triggers.heatmap())
                    .accessibilityElement()
                    .accessibilityLabel("Heatmap of when urges hit, by weekday and time of day. Your toughest windows are listed below.")
            }
        }
    }

    // MARK: - Danger windows

    private var dangerWindowsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                cardTitle("Your danger windows", "The recurring times worth getting ahead of.")
                ForEach(triggers.dangerWindows()) { window in
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(Theme.accent)
                        Text(window.label)
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        RiskMeter(value: window.score)
                    }
                }
            }
        }
    }

    // MARK: - Proactive nudge opt-in

    private var nudgeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Toggle(isOn: $nudgesOn) {
                    Text("Heads-up before tough times")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.textPrimary)
                }
                .tint(Theme.accent)
                Text("A gentle on-device reminder around your danger windows — scheduled locally, never sent to a server.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .onChange(of: nudgesOn) { _, on in
                Task {
                    let result = await services.nudges.setEnabled(on, windows: triggers.dangerWindows())
                    if result != on { nudgesOn = result } // reflect a declined permission prompt
                }
            }
        }
    }

    // MARK: - Trigger breakdown

    private var triggerBreakdownCard: some View {
        let counts = triggers.triggerCounts()
        let maxCount = counts.map(\.count).max() ?? 1
        return GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                cardTitle("What's underneath", "The feelings you name most.")
                ForEach(counts.prefix(6), id: \.trigger) { item in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Text(item.trigger)
                                .font(Theme.Typography.callout)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(item.count)")
                                .font(Theme.Typography.monoCaption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        GeometryReader { geo in
                            Capsule()
                                .fill(Theme.accent)
                                .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount))
                        }
                        .frame(height: 6)
                        .background(Capsule().fill(BedrockColor.basalt))
                    }
                }
            }
        }
    }

    // MARK: - Recent log

    private var recentLogCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                cardTitle("Recent moments", nil)
                ForEach(triggers.recent) { event in
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: event.outcome.logIcon)
                            .foregroundStyle(event.outcome.logTint)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.trigger ?? "Urge")
                                .font(Theme.Typography.callout)
                                .foregroundStyle(Theme.textPrimary)
                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        if let urge = event.urgeIntensity {
                            Text("\(urge)/10")
                                .font(Theme.Typography.monoCaption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty + footer

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.textSecondary)
                Text("Your patterns will appear here")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("Each time you ride out an urge from the SOS button, Bedrock learns your tough times — privately, on this device.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private var privacyFooter: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.fill").foregroundStyle(Theme.textSecondary)
            Text("Computed on your device. Nothing here ever leaves your phone.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func cardTitle(_ title: String, _ subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Heatmap grid

/// 7×8 grid: weekday rows (Sun…Sat) × 3-hour blocks. Opacity tracks risk.
private struct DangerHeatmap: View {
    let grid: [[Double]]

    private let columnTicks = [0, 2, 4, 6] // 00:00, 06:00, 12:00, 18:00

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: 4) {
                    Text(TriggerEngine.weekdayName(row + 1))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, alignment: .leading)
                    ForEach(0..<8, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.accent.opacity(0.12 + 0.88 * cellValue(row, col)))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Theme.hairline.opacity(0.5)))
                    }
                }
            }
            HStack(spacing: 4) {
                Spacer().frame(width: 30)
                ForEach(0..<8, id: \.self) { col in
                    Text(columnTicks.contains(col) ? String(format: "%02d", col * 3) : "")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func cellValue(_ row: Int, _ col: Int) -> Double {
        guard row < grid.count, col < grid[row].count else { return 0 }
        return grid[row][col]
    }
}

/// A small horizontal risk bar, 0…1.
private struct RiskMeter: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(BedrockColor.basalt)
                Capsule().fill(Theme.accent).frame(width: geo.size.width * value)
            }
        }
        .frame(width: 56, height: 6)
    }
}

private extension TriggerEngine.Outcome {
    var logIcon: String {
        switch self {
        case .surfed: "checkmark.circle.fill"
        case .called: "phone.circle.fill"
        case .slipped: "bandage.fill"
        }
    }
    var logTint: Color {
        switch self {
        case .surfed: Theme.accent
        case .called: BedrockColor.mineral
        case .slipped: Theme.textSecondary
        }
    }
}

#Preview {
    InsightsView().environment(AppServices.makeStub())
}
