import Foundation
import SwiftData

public struct DailyConsistencyMetric: Identifiable, Sendable {
    public let id: String
    public let date: Date
    public let dayOfWeek: String
    public let onTimeCount: Int
    public let lateCount: Int
    public let missedCount: Int
    public let excusedCount: Int
    public let totalPrayers: Int

    public var isPerfectDay: Bool {
        (onTimeCount + excusedCount) == 5
    }
}

public struct PrayerPerformanceMetric: Identifiable, Sendable {
    public let id: String
    public let prayer: PrayerType
    public let onTimeCount: Int
    public let lateCount: Int
    public let missedCount: Int
    public let excusedCount: Int
    public let totalLogged: Int

    public var onTimePercentage: Double {
        guard totalLogged > 0 else { return 0.0 }
        return (Double(onTimeCount + excusedCount) / Double(totalLogged)) * 100.0
    }
}

public struct OverallAnalyticsSummary: Sendable {
    public let currentStreak: Int
    public let bestStreak: Int
    public let totalPrayersLogged: Int
    public let onTimePercentage: Double
    public let weakestPrayer: PrayerType?
    public let strongestPrayer: PrayerType?
}

@MainActor
public final class StreakEngine {
    public static let shared = StreakEngine()

    private let store = SwiftDataStore.shared

    private init() {}

    // MARK: - Streak Computation Engine

    public func calculateStreakSummary() -> (current: Int, best: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let settings = store.fetchSettings()

        // Fetch all historical logs sorted ascending
        var descriptor = FetchDescriptor<PrayerLog>()
        descriptor.sortBy = [SortDescriptor(\.date, order: .forward), SortDescriptor(\.scheduledTime, order: .forward)]
        let allLogs = (try? store.context.fetch(descriptor)) ?? []

        guard !allLogs.isEmpty else {
            return (0, 0)
        }

        // Group logs by dayKey
        var dayMap: [String: [PrayerLog]] = [:]
        for log in allLogs {
            dayMap[log.dayKey, default: []].append(log)
        }

        let sortedDayKeys = dayMap.keys.sorted()
        var currentStreak = 0
        var bestStreak = 0
        var runningStreak = 0

        // Iterate historically to compute best streak
        for key in sortedDayKeys {
            guard let logs = dayMap[key], logs.count == 5 else {
                runningStreak = 0
                continue
            }

            let allSatisfied = logs.allSatisfy { $0.status.countsTowardStreak }
            if allSatisfied {
                runningStreak += 1
                if runningStreak > bestStreak {
                    bestStreak = runningStreak
                }
            } else {
                runningStreak = 0
            }
        }

        // Compute current streak walking backward from today / yesterday
        var checkDate = today
        let todayLogs = store.fetchLogs(for: checkDate)
        let todayCompleted = (todayLogs.count == 5 && todayLogs.allSatisfy { $0.status.countsTowardStreak })

        if todayCompleted {
            currentStreak += 1
        }

        // Walk backwards day by day
        while true {
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDay

            let dayLogs = store.fetchLogs(for: checkDate)
            if dayLogs.isEmpty {
                // If Period Mode was active during this gap, do not break streak
                if settings.isPeriodModeActive, let started = settings.periodModeStartedAt, checkDate >= started {
                    continue
                }
                break
            }

            let daySatisfied = (dayLogs.count == 5 && dayLogs.allSatisfy { $0.status.countsTowardStreak })
            if daySatisfied {
                currentStreak += 1
            } else {
                // If today is excused via Period Mode, preserve streak
                if settings.isPeriodModeActive {
                    let hasExcused = dayLogs.contains { $0.status == .excused }
                    if hasExcused {
                        currentStreak += 1
                        continue
                    }
                }
                break
            }
        }

        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }

        return (currentStreak, bestStreak)
    }

    // MARK: - Weekly Consistency Metrics (Past 7 Days)

    public func fetchWeeklyMetrics(endingAt date: Date = Date()) -> [DailyConsistencyMetric] {
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        var metrics: [DailyConsistencyMetric] = []

        for offset in (0..<7).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: date) else { continue }
            let logs = store.fetchLogs(for: targetDate)

            var onTime = 0
            var late = 0
            var missed = 0
            var excused = 0

            for log in logs {
                switch log.status {
                case .completedOnTime: onTime += 1
                case .completedLate: late += 1
                case .missed: missed += 1
                case .excused: excused += 1
                case .pending:
                    // If prayer was scheduled in past and still pending, treat as missed
                    if log.scheduledTime < Date() {
                        missed += 1
                    }
                }
            }

            let dayOfWeek = dayFormatter.string(from: targetDate)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dayKey = formatter.string(from: targetDate)

            metrics.append(DailyConsistencyMetric(
                id: dayKey,
                date: targetDate,
                dayOfWeek: dayOfWeek,
                onTimeCount: onTime,
                lateCount: late,
                missedCount: missed,
                excusedCount: excused,
                totalPrayers: 5
            ))
        }

        return metrics
    }

    // MARK: - Per-Prayer Breakdown (Past N Days)

    public func fetchPrayerBreakdown(days: Int = 30) -> [PrayerPerformanceMetric] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        var descriptor = FetchDescriptor<PrayerLog>()
        descriptor.predicate = #Predicate<PrayerLog> { log in
            log.date >= startDate
        }
        let logs = (try? store.context.fetch(descriptor)) ?? []

        var results: [PrayerPerformanceMetric] = []

        for prayer in PrayerType.allCases {
            let prayerLogs = logs.filter { $0.prayer == prayer }
            var onTime = 0
            var late = 0
            var missed = 0
            var excused = 0

            for log in prayerLogs {
                switch log.status {
                case .completedOnTime: onTime += 1
                case .completedLate: late += 1
                case .missed: missed += 1
                case .excused: excused += 1
                case .pending:
                    if log.scheduledTime < Date() { missed += 1 }
                }
            }

            let total = onTime + late + missed + excused
            results.append(PrayerPerformanceMetric(
                id: prayer.rawValue,
                prayer: prayer,
                onTimeCount: onTime,
                lateCount: late,
                missedCount: missed,
                excusedCount: excused,
                totalLogged: total
            ))
        }

        return results
    }

    // MARK: - Comprehensive Summary

    public func fetchOverallSummary(days: Int = 30) -> OverallAnalyticsSummary {
        let (current, best) = calculateStreakSummary()
        let breakdown = fetchPrayerBreakdown(days: days)

        let totalLogged = breakdown.reduce(0) { $0 + $1.totalLogged }
        let totalOnTimeOrExcused = breakdown.reduce(0) { $0 + ($1.onTimeCount + $1.excusedCount) }

        let onTimePct = totalLogged > 0 ? (Double(totalOnTimeOrExcused) / Double(totalLogged)) * 100.0 : 0.0

        let sortedByPct = breakdown.filter { $0.totalLogged > 0 }.sorted { $0.onTimePercentage < $1.onTimePercentage }
        let weakest = sortedByPct.first?.prayer
        let strongest = sortedByPct.last?.prayer

        return OverallAnalyticsSummary(
            currentStreak: current,
            bestStreak: best,
            totalPrayersLogged: totalLogged,
            onTimePercentage: onTimePct,
            weakestPrayer: weakest,
            strongestPrayer: strongest
        )
    }
}
