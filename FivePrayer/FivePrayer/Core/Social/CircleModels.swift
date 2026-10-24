import Foundation

// MARK: - Circle Member Model

public struct CircleMember: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let avatarSystemImage: String
    public var streakCount: Int
    public var todayPrayersStatus: [PrayerType: PrayerStatus]
    public var isCurrentUser: Bool
    public var lastActive: Date

    public init(
        id: String,
        displayName: String,
        avatarSystemImage: String = "person.crop.circle.fill",
        streakCount: Int = 0,
        todayPrayersStatus: [PrayerType: PrayerStatus] = [:],
        isCurrentUser: Bool = false,
        lastActive: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarSystemImage = avatarSystemImage
        self.streakCount = streakCount
        self.todayPrayersStatus = todayPrayersStatus
        self.isCurrentUser = isCurrentUser
        self.lastActive = lastActive
    }

    public var completedPrayersCount: Int {
        todayPrayersStatus.values.filter { $0.countsTowardStreak }.count
    }

    public var nextPendingPrayer: PrayerType? {
        PrayerType.allCases.first { todayPrayersStatus[$0] == nil || todayPrayersStatus[$0] == .pending }
    }
}

// MARK: - Prayer Circle Model

public struct PrayerCircle: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public let inviteCode: String
    public let creatorId: String
    public let createdAt: Date
    public var members: [CircleMember]

    public init(
        id: String = UUID().uuidString,
        name: String,
        inviteCode: String,
        creatorId: String,
        createdAt: Date = Date(),
        members: [CircleMember] = []
    ) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.creatorId = creatorId
        self.createdAt = createdAt
        self.members = members
    }

    public var totalMembers: Int {
        members.count
    }

    public static func generateInviteCode() -> String {
        let allowedChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excludes ambiguous 0, O, 1, I
        return String((0..<6).compactMap { _ in allowedChars.randomElement() })
    }
}

// MARK: - Nudge Payload

public struct NudgePayload: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let circleId: String
    public let fromMemberId: String
    public let fromMemberName: String
    public let toMemberId: String
    public let prayer: PrayerType
    public let message: String
    public let sentAt: Date

    public init(
        id: String = UUID().uuidString,
        circleId: String,
        fromMemberId: String,
        fromMemberName: String,
        toMemberId: String,
        prayer: PrayerType,
        message: String,
        sentAt: Date = Date()
    ) {
        self.id = id
        self.circleId = circleId
        self.fromMemberId = fromMemberId
        self.fromMemberName = fromMemberName
        self.toMemberId = toMemberId
        self.prayer = prayer
        self.message = message
        self.sentAt = sentAt
    }
}
