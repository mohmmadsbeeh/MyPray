import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
public final class SwiftDataStore: ObservableObject {
    public static let shared = SwiftDataStore(container: SharedContainer.sharedModelContainer)

    public let container: ModelContainer
    public var context: ModelContext {
        container.mainContext
    }

    public init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - User Settings Operations

    public func fetchSettings() -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let settings = try? context.fetch(descriptor).first {
            return settings
        }
        let defaultSettings = UserSettings()
        context.insert(defaultSettings)
        try? context.save()
        return defaultSettings
    }

    public func updateSettings(_ mutator: (UserSettings) -> Void) {
        let settings = fetchSettings()
        mutator(settings)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func togglePeriodMode(isActive: Bool) {
        let settings = fetchSettings()
        settings.isPeriodModeActive = isActive
        settings.periodModeStartedAt = isActive ? Date() : nil

        if isActive {
            // When period mode starts, mark today's pending/future prayers as excused
            let todayLogs = fetchLogs(for: Date())
            for log in todayLogs where log.status == .pending {
                log.markExcused()
            }
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Prayer Log Operations

    public func fetchLogs(for date: Date) -> [PrayerLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dayKey = formatter.string(from: startOfDay)

        let predicate = #Predicate<PrayerLog> { log in
            log.dayKey == dayKey
        }
        var descriptor = FetchDescriptor<PrayerLog>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.scheduledTime, order: .forward)]

        return (try? context.fetch(descriptor)) ?? []
    }

    public func ensureLogs(
        for date: Date,
        hijriDateString: String,
        timings: [(prayer: PrayerType, time: Date)]
    ) -> [PrayerLog] {
        let existingLogs = fetchLogs(for: date)
        var logsMap: [PrayerType: PrayerLog] = [:]
        for log in existingLogs {
            logsMap[log.prayer] = log
        }

        let isPeriodActive = fetchSettings().isPeriodModeActive
        var resultLogs: [PrayerLog] = []

        for item in timings {
            if let existing = logsMap[item.prayer] {
                // Keep scheduled time fresh
                existing.scheduledTime = item.time
                existing.hijriDateString = hijriDateString
                resultLogs.append(existing)
            } else {
                let initialStatus: PrayerStatus = isPeriodActive ? .excused : .pending
                let newLog = PrayerLog(
                    date: date,
                    hijriDateString: hijriDateString,
                    prayer: item.prayer,
                    scheduledTime: item.time,
                    status: initialStatus
                )
                context.insert(newLog)
                resultLogs.append(newLog)
            }
        }

        try? context.save()
        return resultLogs.sorted { $0.prayer.sortOrder < $1.prayer.sortOrder }
    }

    public func updatePrayerStatus(
        prayer: PrayerType,
        on date: Date,
        status: PrayerStatus,
        completedAt: Date? = nil
    ) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dayKey = formatter.string(from: startOfDay)
        let targetId = "\(dayKey)_\(prayer.rawValue)"

        let predicate = #Predicate<PrayerLog> { log in
            log.id == targetId
        }
        let descriptor = FetchDescriptor<PrayerLog>(predicate: predicate)

        if let log = try? context.fetch(descriptor).first {
            log.status = status
            log.completedAt = completedAt ?? (status.isLogged ? Date() : nil)
            log.updatedAt = Date()
            try? context.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    public func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var currentCheckDate = calendar.startOfDay(for: Date())
        var streakCount = 0

        // If today is still underway, check if yesterday was completely completed/excused
        let todayLogs = fetchLogs(for: currentCheckDate)
        let todayAllDone = !todayLogs.isEmpty && todayLogs.allSatisfy { $0.status.countsTowardStreak }

        if todayAllDone {
            streakCount += 1
        }

        // Iterate backward day by day
        while true {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentCheckDate) else {
                break
            }
            currentCheckDate = previousDay
            let dayLogs = fetchLogs(for: currentCheckDate)

            // If day has no logs yet (e.g. before app installation), streak terminates
            if dayLogs.isEmpty {
                break
            }

            let allSatisfied = dayLogs.allSatisfy { $0.status.countsTowardStreak }
            if allSatisfied {
                streakCount += 1
            } else {
                break
            }
        }

        return streakCount
    }

    // MARK: - Blocked App Selection Operations

    public func fetchBlockedAppSelection() -> BlockedAppSelection {
        let descriptor = FetchDescriptor<BlockedAppSelection>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let newSelection = BlockedAppSelection()
        context.insert(newSelection)
        try? context.save()
        return newSelection
    }
}
