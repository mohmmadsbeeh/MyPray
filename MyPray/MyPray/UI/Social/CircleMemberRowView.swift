import SwiftUI

public struct CircleMemberRowView: View {
    public let member: CircleMember
    public var onNudge: ((PrayerType) -> Void)?

    public init(member: CircleMember, onNudge: ((PrayerType) -> Void)? = nil) {
        self.member = member
        self.onNudge = onNudge
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Avatar with Streak
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(member.isCurrentUser ? Color.green.opacity(0.18) : Color(uiColor: .tertiarySystemFill))
                        .frame(width: 44, height: 44)

                    Image(systemName: member.avatarSystemImage)
                        .font(.system(size: 22))
                        .foregroundStyle(member.isCurrentUser ? Color.green : Color.primary)

                    if member.streakCount > 0 {
                        HStack(spacing: 1) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow)
                            Text("\(member.streakCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange)
                        .clipShape(Capsule())
                        .offset(x: 4, y: 4)
                    }
                }

                // Member Name & Completion Count
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(member.displayName)
                            .font(.headline)

                        if member.isCurrentUser {
                            Text("YOU")
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(member.completedPrayersCount) of 5 prayers completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Nudge Action Button (Visible for other members with pending prayers)
                if !member.isCurrentUser, let pendingPrayer = member.nextPendingPrayer {
                    Button {
                        triggerHaptic()
                        onNudge?(pendingPrayer)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 11))
                            Text("Nudge")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(Color.orange)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // 5-Prayer Status Dots Row
            HStack(spacing: 0) {
                ForEach(PrayerType.allCases) { prayer in
                    let status = member.todayPrayersStatus[prayer] ?? .pending
                    prayerDotView(prayer: prayer, status: status)
                    if prayer != .isha {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(member.isCurrentUser ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1.5)
                )
        )
    }

    private func prayerDotView(prayer: PrayerType, status: PrayerStatus) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(dotBackgroundColor(for: status))
                    .frame(width: 24, height: 24)

                switch status {
                case .completedOnTime, .completedLate:
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                case .excused:
                    Image(systemName: "shield.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                case .missed:
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                case .pending:
                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                }
            }

            Text(prayer.displayName.prefix(1))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func dotBackgroundColor(for status: PrayerStatus) -> Color {
        switch status {
        case .completedOnTime: return .green
        case .completedLate: return .orange
        case .excused: return .purple
        case .missed: return .red
        case .pending: return .clear
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
