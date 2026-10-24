import SwiftUI

public struct StreakBadgeView: View {
    public let streakCount: Int
    public let isFrozen: Bool
    public var size: CGFloat = 40

    @State private var isPulsing: Bool = false

    public init(streakCount: Int, isFrozen: Bool = false, size: CGFloat = 40) {
        self.streakCount = streakCount
        self.isFrozen = isFrozen
        self.size = size
    }

    public var body: some View {
        HStack(spacing: 6) {
            ZStack {
                if isFrozen {
                    // Frost / Snowflake badge for Period Mode
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.8), Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)

                    Image(systemName: "snowflake")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    // Fire flame badge
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: streakCount > 0 ? [Color.orange, Color.red] : [Color.gray.opacity(0.5), Color.gray],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .scaleEffect(isPulsing && streakCount > 0 ? 1.05 : 1.0)
                        .animation(
                            streakCount > 0
                                ? Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                                : .default,
                            value: isPulsing
                        )

                    Image(systemName: "flame.fill")
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(streakCount > 0 ? Color.yellow : Color.white)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text("\(streakCount)")
                        .font(.system(size: size * 0.45, weight: .bold, design: .rounded))

                    if isFrozen {
                        Text("FROZEN")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.cyan.opacity(0.2))
                            .foregroundStyle(Color.cyan)
                            .clipShape(Capsule())
                    }
                }

                Text(streakCount == 1 ? "Day Streak" : "Days Streak")
                    .font(.system(size: size * 0.28, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .onAppear {
            if streakCount > 0 {
                isPulsing = true
            }
        }
    }
}
