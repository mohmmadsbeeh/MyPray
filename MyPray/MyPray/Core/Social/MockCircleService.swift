import Foundation
import UserNotifications

public final class MockCircleService: CircleServiceProtocol, @unchecked Sendable {
    public static let shared = MockCircleService()

    private let lock = NSLock()
    private var circles: [PrayerCircle] = []
    private var continuationMap: [String: [UUID: AsyncStream<PrayerCircle>.Continuation]] = [:]

    private init() {
        seedInitialCircles()
    }

    private func seedInitialCircles() {
        let currentUserId = "current_user_device_id"

        let member1 = CircleMember(
            id: currentUserId,
            displayName: "You",
            avatarSystemImage: "person.crop.circle.fill",
            streakCount: 7,
            todayPrayersStatus: [
                .fajr: .completedOnTime,
                .dhuhr: .completedOnTime,
                .asr: .pending,
                .maghrib: .pending,
                .isha: .pending
            ],
            isCurrentUser: true
        )

        let member2 = CircleMember(
            id: "user_hamza",
            displayName: "Hamza",
            avatarSystemImage: "person.circle.fill",
            streakCount: 14,
            todayPrayersStatus: [
                .fajr: .completedOnTime,
                .dhuhr: .completedOnTime,
                .asr: .pending,
                .maghrib: .pending,
                .isha: .pending
            ],
            isCurrentUser: false
        )

        let member3 = CircleMember(
            id: "user_maryam",
            displayName: "Maryam",
            avatarSystemImage: "person.crop.circle.fill.badge.checkmark",
            streakCount: 30,
            todayPrayersStatus: [
                .fajr: .completedOnTime,
                .dhuhr: .completedOnTime,
                .asr: .completedOnTime,
                .maghrib: .completedOnTime,
                .isha: .pending
            ],
            isCurrentUser: false
        )

        let member4 = CircleMember(
            id: "user_zaid",
            displayName: "Zaid",
            avatarSystemImage: "person.fill",
            streakCount: 3,
            todayPrayersStatus: [
                .fajr: .completedLate,
                .dhuhr: .pending,
                .asr: .pending,
                .maghrib: .pending,
                .isha: .pending
            ],
            isCurrentUser: false
        )

        let defaultCircle = PrayerCircle(
            id: "circle_fajr_champions",
            name: "Fajr Champions",
            inviteCode: "FAJR77",
            creatorId: currentUserId,
            createdAt: Date().addingTimeInterval(-86400 * 14),
            members: [member1, member2, member3, member4]
        )

        self.circles = [defaultCircle]
    }

    // MARK: - CircleServiceProtocol Implementation

    public func fetchUserCircles() async throws -> [PrayerCircle] {
        lock.lock()
        defer { lock.unlock() }
        return circles
    }

    public func createCircle(name: String, creatorName: String) async throws -> PrayerCircle {
        lock.lock()
        defer { lock.unlock() }

        let currentUserId = "current_user_device_id"
        let newMember = CircleMember(
            id: currentUserId,
            displayName: creatorName.isEmpty ? "You" : creatorName,
            avatarSystemImage: "person.crop.circle.fill",
            streakCount: 1,
            todayPrayersStatus: [:],
            isCurrentUser: true
        )

        let newCircle = PrayerCircle(
            id: UUID().uuidString,
            name: name,
            inviteCode: PrayerCircle.generateInviteCode(),
            creatorId: currentUserId,
            createdAt: Date(),
            members: [newMember]
        )

        circles.append(newCircle)
        notifyObservers(for: newCircle)
        return newCircle
    }

    public func joinCircle(inviteCode: String, memberName: String) async throws -> PrayerCircle {
        lock.lock()
        defer { lock.unlock() }

        let normalizedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard let index = circles.firstIndex(where: { $0.inviteCode == normalizedCode }) else {
            throw CircleError.invalidInviteCode
        }

        let currentUserId = "current_user_device_id"
        if circles[index].members.contains(where: { $0.id == currentUserId }) {
            throw CircleError.alreadyMember
        }

        let newMember = CircleMember(
            id: currentUserId,
            displayName: memberName.isEmpty ? "You" : memberName,
            avatarSystemImage: "person.crop.circle.fill",
            streakCount: 1,
            todayPrayersStatus: [:],
            isCurrentUser: true
        )

        circles[index].members.append(newMember)
        let updatedCircle = circles[index]
        notifyObservers(for: updatedCircle)
        return updatedCircle
    }

    public func leaveCircle(circleId: String, memberId: String) async throws {
        lock.lock()
        defer { lock.unlock() }

        guard let index = circles.firstIndex(where: { $0.id == circleId }) else {
            throw CircleError.circleNotFound
        }

        circles[index].members.removeAll { $0.id == memberId }
        let updatedCircle = circles[index]
        notifyObservers(for: updatedCircle)
    }

    public func syncPrayerStatus(
        circleId: String,
        memberId: String,
        prayer: PrayerType,
        status: PrayerStatus
    ) async throws {
        lock.lock()
        defer { lock.unlock() }

        guard let cIndex = circles.firstIndex(where: { $0.id == circleId }) else {
            return
        }

        if let mIndex = circles[cIndex].members.firstIndex(where: { $0.id == memberId }) {
            circles[cIndex].members[mIndex].todayPrayersStatus[prayer] = status
            circles[cIndex].members[mIndex].lastActive = Date()
            let updated = circles[cIndex]
            notifyObservers(for: updated)
        }
    }

    public func sendNudge(
        to memberId: String,
        in circleId: String,
        for prayer: PrayerType,
        fromName: String
    ) async throws -> NudgePayload {
        lock.lock()
        defer { lock.unlock() }

        guard let circle = circles.first(where: { $0.id == circleId }),
              let targetMember = circle.members.first(where: { $0.id == memberId }) else {
            throw CircleError.circleNotFound
        }

        let message = "\(fromName) nudged you to pray \(prayer.displayName) before the window closes!"
        let payload = NudgePayload(
            circleId: circleId,
            fromMemberId: "current_user_device_id",
            fromMemberName: fromName,
            toMemberId: memberId,
            prayer: prayer,
            message: message
        )

        // Post a local notification simulation to give immediate feedback
        Task {
            let content = UNMutableNotificationContent()
            content.title = "Nudge Sent to \(targetMember.displayName)"
            content.body = "Encouragement sent: \(message)"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(identifier: "nudge_\(UUID().uuidString)", content: content, trigger: trigger)
            try? await UNUserNotificationCenter.current().add(request)
        }

        return payload
    }

    public func observeCircleUpdates(circleId: String) -> AsyncStream<PrayerCircle> {
        AsyncStream { continuation in
            let token = UUID()
            lock.lock()
            if let circle = circles.first(where: { $0.id == circleId }) {
                continuation.yield(circle)
            }
            if continuationMap[circleId] == nil {
                continuationMap[circleId] = [:]
            }
            continuationMap[circleId]?[token] = continuation
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.lock.lock()
                self.continuationMap[circleId]?.removeValue(forKey: token)
                self.lock.unlock()
            }
        }
    }

    private func notifyObservers(for circle: PrayerCircle) {
        if let continuations = continuationMap[circle.id] {
            for c in continuations.values {
                c.yield(circle)
            }
        }
    }
}
