import Foundation

public final class CloudCircleService: CircleServiceProtocol, @unchecked Sendable {
    public static let shared = CloudCircleService()

    private let backendBaseURL: URL
    private let urlSession: URLSession

    public init(backendBaseURL: URL = URL(string: "https://api.fiveprayer.com/v1")!) {
        self.backendBaseURL = backendBaseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        self.urlSession = URLSession(configuration: config)
    }

    public func fetchUserCircles() async throws -> [PrayerCircle] {
        let endpoint = backendBaseURL.appendingPathComponent("circles")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CircleError.networkError("Failed to fetch circles from cloud server.")
        }

        return try JSONDecoder().decode([PrayerCircle].self, from: data)
    }

    public func createCircle(name: String, creatorName: String) async throws -> PrayerCircle {
        let endpoint = backendBaseURL.appendingPathComponent("circles")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "name": name,
            "creatorName": creatorName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) else {
            throw CircleError.networkError("Failed to create circle on cloud server.")
        }

        return try JSONDecoder().decode(PrayerCircle.self, from: data)
    }

    public func joinCircle(inviteCode: String, memberName: String) async throws -> PrayerCircle {
        let endpoint = backendBaseURL.appendingPathComponent("circles/join")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "inviteCode": inviteCode.uppercased(),
            "memberName": memberName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CircleError.networkError("Invalid server response.")
        }

        if httpResponse.statusCode == 404 {
            throw CircleError.invalidInviteCode
        } else if httpResponse.statusCode == 409 {
            throw CircleError.alreadyMember
        } else if httpResponse.statusCode != 200 {
            throw CircleError.networkError("Error joining circle (Status: \(httpResponse.statusCode)).")
        }

        return try JSONDecoder().decode(PrayerCircle.self, from: data)
    }

    public func leaveCircle(circleId: String, memberId: String) async throws {
        let endpoint = backendBaseURL.appendingPathComponent("circles/\(circleId)/members/\(memberId)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CircleError.networkError("Failed to leave circle.")
        }
    }

    public func syncPrayerStatus(
        circleId: String,
        memberId: String,
        prayer: PrayerType,
        status: PrayerStatus
    ) async throws {
        let endpoint = backendBaseURL.appendingPathComponent("circles/\(circleId)/status")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "memberId": memberId,
            "prayer": prayer.rawValue,
            "status": status.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CircleError.networkError("Failed to sync prayer status to cloud.")
        }
    }

    public func sendNudge(
        to memberId: String,
        in circleId: String,
        for prayer: PrayerType,
        fromName: String
    ) async throws -> NudgePayload {
        let endpoint = backendBaseURL.appendingPathComponent("nudges")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "circleId": circleId,
            "toMemberId": memberId,
            "prayer": prayer.rawValue,
            "fromName": fromName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) else {
            throw CircleError.networkError("Failed to deliver nudge push notification.")
        }

        return try JSONDecoder().decode(NudgePayload.self, from: data)
    }

    public func observeCircleUpdates(circleId: String) -> AsyncStream<PrayerCircle> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    do {
                        let endpoint = self.backendBaseURL.appendingPathComponent("circles/\(circleId)")
                        let (data, _) = try await self.urlSession.data(from: endpoint)
                        if let circle = try? JSONDecoder().decode(PrayerCircle.self, from: data) {
                            continuation.yield(circle)
                        }
                    } catch {
                        #if DEBUG
                        print("Polling circle error: \(error.localizedDescription)")
                        #endif
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // Poll every 5s if WebSocket is not active
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
