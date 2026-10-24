import SwiftUI
import WidgetKit

// MARK: - Small Widget View (.systemSmall)

public struct SmallWidgetView: View {
    public let entry: PrayerTimelineEntry

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: City & Streak Flame
            HStack {
                Text(entry.cityName)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                if entry.isPeriodModeActive {
                    Image(systemName: "snowflake")
                        .font(.caption2.bold())
                        .foregroundStyle(.cyan)
                } else if entry.streakCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                        Text("\(entry.streakCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Next Prayer Name & Arabic
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT PRAYER")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.green)

                HStack(spacing: 4) {
                    Text(entry.nextPrayer.displayName)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text(entry.nextPrayer.arabicName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Scheduled Time & Live Countdown
            HStack(alignment: .lastTextBaseline) {
                Text(entry.nextPrayerTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                Spacer()

                Text(entry.nextPrayerTime, style: .relative)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - Medium Widget View (.systemMedium)

public struct MediumWidgetView: View {
    public let entry: PrayerTimelineEntry

    public var body: some View {
        HStack(spacing: 14) {
            // Left Column: Next Prayer Hero
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(entry.cityName)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Spacer()

                    if entry.streakCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text("\(entry.streakCount)d")
                                .font(.caption2.bold())
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer()

                Text("NEXT PRAYER")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.green)

                Text(entry.nextPrayer.displayName)
                    .font(.title2.bold())

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(entry.nextPrayerTime.formatted(date: .omitted, time: .shortened))
                        .font(.headline)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(entry.nextPrayerTime, style: .relative)
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Right Column: 5 Prayers Mini Timeline
            VStack(alignment: .leading, spacing: 5) {
                ForEach(entry.schedule.obligatoryPrayers, id: \.prayer) { item in
                    let isNext = (item.prayer == entry.nextPrayer)
                    HStack(spacing: 6) {
                        Image(systemName: item.prayer.iconName)
                            .font(.system(size: 11))
                            .foregroundStyle(isNext ? Color.green : Color.secondary)
                            .frame(width: 14)

                        Text(item.prayer.displayName)
                            .font(.system(size: 12, weight: isNext ? .bold : .regular))
                            .foregroundStyle(isNext ? Color.primary : Color.secondary)

                        Spacer()

                        Text(item.time.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11, weight: isNext ? .bold : .regular, design: .rounded))
                            .foregroundStyle(isNext ? Color.green : Color.secondary)
                    }
                    .padding(.vertical, 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// MARK: - Lock Screen Rectangular (.accessoryRectangular)

public struct LockScreenRectangularView: View {
    public let entry: PrayerTimelineEntry

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: entry.nextPrayer.iconName)
                    .font(.caption)
                Text(entry.nextPrayer.displayName)
                    .font(.headline)
                Spacer()
                Text(entry.nextPrayerTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
            }

            HStack {
                Text("Adhan in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(entry.nextPrayerTime, style: .relative)
                    .font(.caption.bold())
            }

            Text(entry.hijriDateString)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Lock Screen Circular (.accessoryCircular)

public struct LockScreenCircularView: View {
    public let entry: PrayerTimelineEntry

    public var body: some View {
        let progress = PrayerTimeService.shared.currentPrayerWindowProgress(
            at: entry.date,
            schedule: entry.schedule
        )

        Gauge(value: progress, in: 0.0...1.0) {
            Image(systemName: entry.nextPrayer.iconName)
                .font(.system(size: 10, weight: .bold))
        } currentValueLabel: {
            Text(entry.nextPrayer.displayName.prefix(1))
                .font(.system(size: 12, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Lock Screen Inline (.accessoryInline)

public struct LockScreenInlineView: View {
    public let entry: PrayerTimelineEntry

    public var body: some View {
        ViewThatFits {
            Text("\(entry.nextPrayer.displayName) \(entry.nextPrayerTime.formatted(date: .omitted, time: .shortened)) (\(entry.nextPrayerTime, style: .relative))")
            Text("\(entry.nextPrayer.displayName) in \(entry.nextPrayerTime, style: .relative)")
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
