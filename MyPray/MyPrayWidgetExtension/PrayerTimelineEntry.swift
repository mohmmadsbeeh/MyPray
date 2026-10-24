import WidgetKit
import Foundation

public struct PrayerTimelineEntry: TimelineEntry, Sendable {
    public let date: Date
    public let nextPrayer: PrayerType
    public let nextPrayerTime: Date
    public let isTomorrow: Bool
    public let schedule: DailyPrayerSchedule
    public let hijriDateString: String
    public let streakCount: Int
    public let cityName: String
    public let isPeriodModeActive: Bool

    public init(
        date: Date,
        nextPrayer: PrayerType,
        nextPrayerTime: Date,
        isTomorrow: Bool = false,
        schedule: DailyPrayerSchedule,
        hijriDateString: String,
        streakCount: Int,
        cityName: String,
        isPeriodModeActive: Bool = false
    ) {
        self.date = date
        self.nextPrayer = nextPrayer
        self.nextPrayerTime = nextPrayerTime
        self.isTomorrow = isTomorrow
        self.schedule = schedule
        self.hijriDateString = hijriDateString
        self.streakCount = streakCount
        self.cityName = cityName
        self.isPeriodModeActive = isPeriodModeActive
    }

    public static var placeholder: PrayerTimelineEntry {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let mockSchedule = DailyPrayerSchedule(
            date: startOfDay,
            fajr: startOfDay.addingTimeInterval(5 * 3600 + 12 * 60),
            sunrise: startOfDay.addingTimeInterval(6 * 3600 + 35 * 60),
            dhuhr: startOfDay.addingTimeInterval(12 * 3600 + 20 * 60),
            asr: startOfDay.addingTimeInterval(15 * 3600 + 45 * 60),
            maghrib: startOfDay.addingTimeInterval(18 * 3600 + 10 * 60),
            isha: startOfDay.addingTimeInterval(19 * 3600 + 35 * 60)
        )

        return PrayerTimelineEntry(
            date: now,
            nextPrayer: .asr,
            nextPrayerTime: mockSchedule.asr,
            isTomorrow: false,
            schedule: mockSchedule,
            hijriDateString: "14 Rajab 1448 AH",
            streakCount: 7,
            cityName: "Makkah",
            isPeriodModeActive: false
        )
    }
}
