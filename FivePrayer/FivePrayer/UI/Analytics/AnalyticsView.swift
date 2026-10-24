import SwiftUI
import Charts

public struct AnalyticsView: View {
    @State private var selectedTimeRange: Int = 30 // Days
    @State private var weeklyMetrics: [DailyConsistencyMetric] = []
    @State private var prayerBreakdown: [PrayerPerformanceMetric] = []
    @State private var summary: OverallAnalyticsSummary = OverallAnalyticsSummary(
        currentStreak: 0,
        bestStreak: 0,
        totalPrayersLogged: 0,
        onTimePercentage: 0.0,
        weakestPrayer: nil,
        strongestPrayer: nil
    )
    @State private var isPeriodModeActive: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Key KPIs Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    metricCard(
                        title: "Current Streak",
                        value: "\(summary.currentStreak) Days",
                        icon: "flame.fill",
                        tint: .orange
                    )

                    metricCard(
                        title: "Best Streak",
                        value: "\(summary.bestStreak) Days",
                        icon: "trophy.fill",
                        tint: .yellow
                    )

                    metricCard(
                        title: "On-Time Rate",
                        value: String(format: "%.1f%%", summary.onTimePercentage),
                        icon: "target",
                        tint: .green
                    )

                    metricCard(
                        title: "Prayers Logged",
                        value: "\(summary.totalPrayersLogged)",
                        icon: "checkmark.seal.fill",
                        tint: .blue
                    )
                }
                .padding(.horizontal)

                // MARK: - Weekly Consistency Stacked Chart
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("7-Day Consistency")
                                .font(.headline)
                            Text("Prayers completed on-time, late, or excused")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    Chart {
                        ForEach(weeklyMetrics) { metric in
                            BarMark(
                                x: .value("Day", metric.dayOfWeek),
                                y: .value("Count", metric.onTimeCount)
                            )
                            .foregroundStyle(Color.green)
                            .position(by: .value("Status", "On-Time"))

                            BarMark(
                                x: .value("Day", metric.dayOfWeek),
                                y: .value("Count", metric.lateCount)
                            )
                            .foregroundStyle(Color.orange)
                            .position(by: .value("Status", "Late"))

                            BarMark(
                                x: .value("Day", metric.dayOfWeek),
                                y: .value("Count", metric.excusedCount)
                            )
                            .foregroundStyle(Color.purple)
                            .position(by: .value("Status", "Excused"))

                            BarMark(
                                x: .value("Day", metric.dayOfWeek),
                                y: .value("Count", metric.missedCount)
                            )
                            .foregroundStyle(Color.red.opacity(0.7))
                            .position(by: .value("Status", "Missed"))
                        }
                    }
                    .chartYScale(domain: 0...5)
                    .frame(height: 200)

                    // Legend
                    HStack(spacing: 12) {
                        legendItem(title: "On-Time", color: .green)
                        legendItem(title: "Late", color: .orange)
                        legendItem(title: "Excused", color: .purple)
                        legendItem(title: "Missed", color: .red)
                    }
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
                .padding(.horizontal)

                // MARK: - Per-Prayer Consistency Breakdown
                VStack(alignment: .leading, spacing: 14) {
                    Text("Prayer-by-Prayer Breakdown")
                        .font(.headline)

                    ForEach(prayerBreakdown) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(item.prayer.displayName, systemImage: item.prayer.iconName)
                                    .font(.subheadline.bold())

                                Spacer()

                                Text(String(format: "%.0f%%", item.onTimePercentage))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(percentageColor(item.onTimePercentage))
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(uiColor: .tertiarySystemFill))
                                        .frame(height: 10)

                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(percentageColor(item.onTimePercentage))
                                        .frame(width: max(0, geo.size.width * CGFloat(item.onTimePercentage / 100.0)), height: 10)
                                }
                            }
                            .frame(height: 10)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
                .padding(.horizontal)

                // MARK: - Personalized Insight Card
                if let weakest = summary.weakestPrayer {
                    HStack(spacing: 14) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.yellow)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Khushu' Tip: Protect \(weakest.displayName)")
                                .font(.headline)

                            Text("\(weakest.displayName) has your lowest consistency score. Set your pre-prayer notification to 20 minutes prior to prepare early.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.yellow.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }

                // MARK: - Period Mode Controls
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $isPeriodModeActive) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Period / Excused Mode")
                                .font(.headline)
                            Text("Freezes streak decay, marks prayers as excused, and mutes notification alarms.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.purple)
                    .onChange(of: isPeriodModeActive) { _, newValue in
                        SwiftDataStore.shared.togglePeriodMode(isActive: newValue)
                        reloadMetrics()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Habit Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            reloadMetrics()
        }
    }

    private func reloadMetrics() {
        self.weeklyMetrics = StreakEngine.shared.fetchWeeklyMetrics()
        self.prayerBreakdown = StreakEngine.shared.fetchPrayerBreakdown(days: selectedTimeRange)
        self.summary = StreakEngine.shared.fetchOverallSummary(days: selectedTimeRange)
        self.isPeriodModeActive = SwiftDataStore.shared.fetchSettings().isPeriodModeActive
    }

    private func metricCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                Spacer()
            }

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundStyle(.secondary)
        }
    }

    private func percentageColor(_ pct: Double) -> Color {
        if pct >= 80 { return .green }
        if pct >= 60 { return .orange }
        return .red
    }
}
