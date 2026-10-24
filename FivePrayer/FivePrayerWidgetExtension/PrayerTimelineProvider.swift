import WidgetKit
import Foundation
import SwiftData

public struct PrayerTimelineProvider: TimelineProvider {
    public typealias Entry = PrayerTimelineEntry

    public init() {}

    public func placeholder(in context: Context) -> PrayerTimelineEntry {
        .placeholder
    }

    public func getSnapshot(in context: Context, completion: @escaping (PrayerTimelineEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        let entry = currentEntry(for: Date())
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerTimelineEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        var entries: [PrayerTimelineEntry] = []

        // Fetch settings from AppGroup shared storage
        let (settings, streak) = fetchSharedSettingsAndStreak()
        let lat = settings.lastKnownLatitude ?? 21.422487
        let lon = settings.lastKnownLongitude ?? 39.826206
        let city = settings.lastKnownCity ?? "Local"

        let todaySchedule = PrayerTimeService.shared.calculateSchedule(
            for: now,
            latitude: lat,
            longitude: lon,
            settings: settings
        )

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)
        let tomorrowSchedule = PrayerTimeService.shared.calculateSchedule(
            for: tomorrow,
            latitude: lat,
            longitude: lon,
            settings: settings
        )

        let hijriStr = HijriCalendarHelper.formattedHijriString(for: now)

        // 1. Current instantaneous entry
        let next = PrayerTimeService.shared.nextPrayer(at: now, schedule: todaySchedule, tomorrowSchedule: tomorrowSchedule)
        entries.append(PrayerTimelineEntry(
            date: now,
            nextPrayer: next.prayer,
            nextPrayerTime: next.time,
            isTomorrow: next.isTomorrow,
            schedule: todaySchedule,
            hijriDateString: hijriStr,
            streakCount: streak,
            cityName: city,
            isPeriodModeActive: settings.isPeriodModeActive
        ))

        // 2. Schedule timeline points at each subsequent prayer time & 30-min intervals
        var checkTime = now.addingTimeInterval(1800) // +30m
        let endOfWindow = now.addingTimeInterval(12 * 3600) // next 12 hours

        while checkTime <= endOfWindow {
            let stepNext = PrayerTimeService.shared.nextPrayer(at: checkTime, schedule: todaySchedule, tomorrowSchedule: tomorrowSchedule)
            entries.append(PrayerTimelineEntry(
                date: checkTime,
                nextPrayer: stepNext.prayer,
                nextPrayerTime: stepNext.time,
                isTomorrow: stepNext.isTomorrow,
                schedule: todaySchedule,
                hijriDateString: hijriStr,
                streakCount: streak,
                cityName: city,
                isPeriodModeActive: settings.isPeriodModeActive
            ))
            checkTime = checkTime.addingTimeInterval(1800)
        }

        // Reload policy: when the next prayer time arrives or after 2 hours
        let nextReloadDate = next.time.addingTimeInterval(60) // 1 min after adhan
        let timeline = Timeline(entries: entries, policy: .after(nextReloadDate))
        completion(timeline)
    }

    // MARK: - Private Data Helpers

    private func currentEntry(for date: Date) -> PrayerTimelineEntry {
        let (settings, streak) = fetchSharedSettingsAndStreak()
        let lat = settings.lastKnownLatitude ?? 21.422487
        let lon = settings.lastKnownLongitude ?? 39.826206
        let city = settings.lastKnownCity ?? "Local"

        let schedule = PrayerTimeService.shared.calculateSchedule(
            for: date,
            latitude: lat,
            longitude: lon,
            settings: settings
        )
        let next = PrayerTimeService.shared.nextPrayer(at: date, schedule: schedule)

        return PrayerTimelineEntry(
            date: date,
            nextPrayer: next.prayer,
            nextPrayerTime: next.time,
            isTomorrow: next.isTomorrow,
            schedule: schedule,
            hijriDateString: HijriCalendarHelper.formattedHijriString(for: date),
            streakCount: streak,
            cityName: city,
            isPeriodModeActive: settings.isPeriodModeActive
        )
    }

    private func fetchSharedSettingsAndStreak() -> (UserSettings, Int) {
        do {
            let container = try SharedContainer.makeContainer()
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<UserSettings>()
            let settings = (try? context.fetch(descriptor).first) ?? UserSettings()

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dayKey = formatter.string(from: today)

            let logPredicate = #Predicate<PrayerLog> { $0.dayKey == dayKey }
            let logDescriptor = FetchDescriptor<PrayerLog>(predicate: logPredicate)
            let todayLogs = (try? context.fetch(logDescriptor)) ?? []
            let streak = todayLogs.filter { $0.status.countsTowardStreak }.count

            return (settings, max(streak, 1))
        } catch {
            return (UserSettings(), 0)
        }
    }
}
