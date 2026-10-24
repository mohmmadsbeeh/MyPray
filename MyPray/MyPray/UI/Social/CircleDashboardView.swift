import SwiftUI
import SwiftData

public struct CircleDashboardView: View {
    @State private var circles: [PrayerCircle] = []
    @State private var activeCircle: PrayerCircle?
    @State private var isShowingCreateOrJoinSheet: Bool = false
    @State private var nudgeSuccessToast: String?
    @State private var isCopiedToast: Bool = false
    @State private var isRefreshing: Bool = false

    private let circleService: CircleServiceProtocol = MockCircleService.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let circle = activeCircle {
                        // MARK: - Circle Hero Card & Invite Code
                        circleHeroCard(for: circle)

                        // MARK: - Nudge Toast Banner (if sent)
                        if let toast = nudgeSuccessToast {
                            nudgeToastBanner(text: toast)
                        }

                        // MARK: - Status Dots Legend
                        statusLegendCard

                        // MARK: - Members Accountability Board
                        membersSection(for: circle)
                    } else {
                        emptyCirclesCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Prayer Circles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingCreateOrJoinSheet = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.green)
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateOrJoinSheet) {
                CreateOrJoinCircleView { newCircle in
                    self.activeCircle = newCircle
                    loadCircles()
                }
            }
            .task {
                loadCircles()
                syncCurrentUserStatus()
            }
        }
    }

    // MARK: - Subviews

    private func circleHeroCard(for circle: PrayerCircle) -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("\(circle.totalMembers) Members • Created \(circle.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Share Invite Code
                ShareLink(
                    item: "Join my MyPray accountability circle '\(circle.name)'! Use invite code: \(circle.inviteCode)",
                    subject: Text("Join My MyPray Circle"),
                    message: Text("Let's keep each other accountable to pray on time. Use code \(circle.inviteCode).")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
            }

            Divider()

            // 6-Character Invite Code Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("INVITE CODE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text(circle.inviteCode)
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(.green)
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = circle.inviteCode
                    triggerHaptic()
                    withAnimation { isCopiedToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { isCopiedToast = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopiedToast ? "checkmark" : "doc.on.doc.fill")
                            .font(.caption)
                        Text(isCopiedToast ? "Copied!" : "Copy Code")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(Color.green)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    private func nudgeToastBanner(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.15))
        )
        .transition(.slide.combined(with: .opacity))
    }

    private var statusLegendCard: some View {
        HStack(spacing: 12) {
            legendDot(color: .green, label: "On Time")
            legendDot(color: .orange, label: "Late")
            legendDot(color: .purple, label: "Excused")
            legendDot(color: .secondary.opacity(0.4), label: "Pending")
        }
        .font(.caption2)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    private func membersSection(for circle: PrayerCircle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Accountability Board")
                    .font(.headline)
                Spacer()
                Text("\(circle.members.count) Friends")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVStack(spacing: 12) {
                ForEach(circle.members) { member in
                    CircleMemberRowView(member: member) { pendingPrayer in
                        handleNudge(to: member, for: pendingPrayer, circle: circle)
                    }
                }
            }
        }
    }

    private var emptyCirclesCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            VStack(spacing: 6) {
                Text("No Prayer Circles Yet")
                    .font(.title3.bold())

                Text("Salah is best preserved together. Create a circle or enter an invite code to hold your friends accountable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                isShowingCreateOrJoinSheet = true
            } label: {
                Text("Join or Create Circle")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }

    // MARK: - Actions

    private func loadCircles() {
        Task {
            if let list = try? await circleService.fetchUserCircles() {
                await MainActor.run {
                    self.circles = list
                    if self.activeCircle == nil || !list.contains(where: { $0.id == self.activeCircle?.id }) {
                        self.activeCircle = list.first
                    }
                }
            }
        }
    }

    private func syncCurrentUserStatus() {
        Task { @MainActor in
            guard let circle = activeCircle else { return }
            let logs = SwiftDataStore.shared.fetchLogs(for: Date())
            let currentUserId = "current_user_device_id"

            for log in logs {
                try? await circleService.syncPrayerStatus(
                    circleId: circle.id,
                    memberId: currentUserId,
                    prayer: log.prayer,
                    status: log.status
                )
            }
            loadCircles()
        }
    }

    private func handleNudge(to member: CircleMember, for prayer: PrayerType, circle: PrayerCircle) {
        Task {
            do {
                let payload = try await circleService.sendNudge(
                    to: member.id,
                    in: circle.id,
                    for: prayer,
                    fromName: "You"
                )
                await MainActor.run {
                    withAnimation {
                        self.nudgeSuccessToast = "Nudge sent to \(member.displayName) for \(prayer.displayName)!"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation {
                            self.nudgeSuccessToast = nil
                        }
                    }
                }
            } catch {
                #if DEBUG
                print("Failed to send nudge: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
