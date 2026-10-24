import Foundation

public enum PrayerStatus: String, CaseIterable, Codable, Sendable {
    case pending = "pending"
    case completedOnTime = "completedOnTime"
    case completedLate = "completedLate"
    case missed = "missed"
    case excused = "excused"

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .completedOnTime: return "Completed On Time"
        case .completedLate: return "Completed Late"
        case .missed: return "Missed"
        case .excused: return "Excused"
        }
    }

    public var isLogged: Bool {
        self != .pending
    }

    public var countsTowardStreak: Bool {
        self == .completedOnTime || self == .excused
    }
}
