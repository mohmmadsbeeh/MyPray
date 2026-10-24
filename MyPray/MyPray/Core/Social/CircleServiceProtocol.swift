import Foundation

public enum CircleError: LocalizedError, Sendable {
    case circleNotFound
    case invalidInviteCode
    case alreadyMember
    case networkError(String)
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .circleNotFound:
            return "The prayer circle could not be found."
        case .invalidInviteCode:
            return "Invalid 6-character invite code. Please check and try again."
        case .alreadyMember:
            return "You are already a member of this prayer circle."
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "You do not have permission to perform this action."
        }
    }
}

public protocol CircleServiceProtocol: Sendable {
    func fetchUserCircles() async throws -> [PrayerCircle]
    func createCircle(name: String, creatorName: String) async throws -> PrayerCircle
    func joinCircle(inviteCode: String, memberName: String) async throws -> PrayerCircle
    func leaveCircle(circleId: String, memberId: String) async throws
    func syncPrayerStatus(circleId: String, memberId: String, prayer: PrayerType, status: PrayerStatus) async throws
    func sendNudge(to memberId: String, in circleId: String, for prayer: PrayerType, fromName: String) async throws -> NudgePayload
    func observeCircleUpdates(circleId: String) -> AsyncStream<PrayerCircle>
}
