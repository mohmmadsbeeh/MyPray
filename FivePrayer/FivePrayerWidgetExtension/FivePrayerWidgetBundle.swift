import WidgetKit
import SwiftUI

@main
struct FivePrayerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FivePrayerWidgets()
    }
}

public struct FivePrayerWidgets: Widget {
    public let kind: String = "FivePrayerWidgets"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            PrayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Schedule")
        .description("Track the next prayer countdown, daily timetable, and streak on your Home and Lock Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

public struct PrayerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    public let entry: PrayerTimelineEntry

    public var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
