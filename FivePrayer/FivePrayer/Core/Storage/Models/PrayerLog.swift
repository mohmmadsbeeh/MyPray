import Foundation
import SwiftData

@Model
public final class PrayerLog {
    @Attribute(.unique) public var id: String
    public var date: Date
    public var dayKey: String
    public var hijriDateString: String
    public var prayerRaw: String
    public var statusRaw: String
    public var scheduledTime: Date
    public var completedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public var prayer: PrayerType {
        get { PrayerType(rawValue: prayerRaw) ?? .fajr }
        set { prayerRaw = newValue.rawValue }
    }

    public var status: PrayerStatus {
        get { PrayerStatus(rawValue: statusRaw) ?? .pending }
        set {
            statusRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    public init(
        date: Date,
        hijriDateString: String,
        prayer: PrayerType,
        scheduledTime: Date,
        status: PrayerStatus = .pending,
        completedAt: Date? = nil
    ) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        let dayKey = formatter.string(from: startOfDay)

        self.id = "\(dayKey)_\(prayer.rawValue)"
        self.date = startOfDay
        self.dayKey = dayKey
        self.hijriDateString = hijriDateString
        self.prayerRaw = prayer.rawValue
        self.statusRaw = status.rawValue
        self.scheduledTime = scheduledTime
        self.completedAt = completedAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public func markCompleted(at timestamp: Date = Date(), windowEndTime: Date) {
        self.completedAt = timestamp
        if timestamp <= windowEndTime {
            self.status = .completedOnTime
        } else {
            self.status = .completedLate
        }
        self.updatedAt = Date()
    }

    public func markExcused() {
        self.completedAt = nil
        self.status = .excused
        self.updatedAt = Date()
    }

    public func markMissed() {
        self.status = .missed
        self.updatedAt = Date()
    }

    public func resetToPending() {
        self.completedAt = nil
        self.status = .pending
        self.updatedAt = Date()
    }
}
