import SwiftUI

public struct PrayerCheckboxRow: View {
    public let prayer: PrayerType
    public let scheduledTime: Date
    public let status: PrayerStatus
    public let isCurrentPrayerWindow: Bool
    public let onStatusChanged: (PrayerStatus) -> Void

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public init(
        prayer: PrayerType,
        scheduledTime: Date,
        status: PrayerStatus,
        isCurrentPrayerWindow: Bool = false,
        onStatusChanged: @escaping (PrayerStatus) -> Void
    ) {
        self.prayer = prayer
        self.scheduledTime = scheduledTime
        self.status = status
        self.isCurrentPrayerWindow = isCurrentPrayerWindow
        self.onStatusChanged = onStatusChanged
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Prayer Icon with highlight
            ZStack {
                Circle()
                    .fill(isCurrentPrayerWindow ? Color.green.opacity(0.18) : Color(uiColor: .tertiarySystemFill))
                    .frame(width: 44, height: 44)

                Image(systemName: prayer.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isCurrentPrayerWindow ? Color.green : Color.primary)
            }

            // Names & Scheduled Time
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(prayer.displayName)
                        .font(.headline)
                        .fontWeight(isCurrentPrayerWindow ? .bold : .semibold)

                    Text(prayer.arabicName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if isCurrentPrayerWindow {
                        Text("CURRENT")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

                Text(timeFormatter.string(from: scheduledTime))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Status Checkbox Button
            Button {
                triggerHapticFeedback()
                if status == .pending {
                    onStatusChanged(.completedOnTime)
                } else {
                    onStatusChanged(.pending)
                }
            } label: {
                statusBadgeView
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    onStatusChanged(.completedOnTime)
                } label: {
                    Label("Mark Completed On Time", systemImage: "checkmark.circle.fill")
                }

                Button {
                    onStatusChanged(.completedLate)
                } label: {
                    Label("Mark Completed Late", systemImage: "clock.badge.checkmark.fill")
                }

                Button {
                    onStatusChanged(.missed)
                } label: {
                    Label("Mark Missed", systemImage: "xmark.circle.fill")
                }

                Button {
                    onStatusChanged(.excused)
                } label: {
                    Label("Mark Excused (Period/Illness)", systemImage: "shield.slash.fill")
                }

                Divider()

                Button(role: .destructive) {
                    onStatusChanged(.pending)
                } label: {
                    Label("Reset to Pending", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isCurrentPrayerWindow ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        )
    }

    @ViewBuilder
    private var statusBadgeView: some View {
        switch status {
        case .pending:
            Circle()
                .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 2)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())

        case .completedOnTime:
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

        case .completedLate:
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

        case .missed:
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.85))
                    .frame(width: 32, height: 32)
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

        case .excused:
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.85))
                    .frame(width: 32, height: 32)
                Image(systemName: "shield.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
