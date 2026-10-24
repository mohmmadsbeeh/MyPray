import SwiftUI
import SwiftData

public struct HomeDashboardView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var todaySchedule: DailyPrayerSchedule?
    @State private var tomorrowSchedule: DailyPrayerSchedule?
    @State private var todayLogs: [PrayerLog] = []
    @State private var streakCount: Int = 0
    @State private var isPeriodModeActive: Bool = false
    @State private var selectedDate: Date = Date()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // MARK: - Header: Hijri & Gregorian Date + Streak Badge
                    headerSection

                    // MARK: - Period Mode Alert Banner (if active)
                    if isPeriodModeActive {
                        periodModeBanner
                    }

                    // MARK: - Hero Next Prayer Countdown Card
                    countdownHeroCard

                    // MARK: - 5 Daily Prayers Checklist
                    prayerChecklistSection

                    // MARK: - Quick Navigation Hub
                    quickNavigationGrid
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("FivePrayer")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                QuranMiniPlayerView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AnalyticsView()
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundStyle(.green)
                    }
                }
            }
            .onAppear {
                reloadAllData()
            }
            .onChange(of: locationManager.userLocation) { _, _ in
                reloadAllData()
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(HijriCalendarHelper.formattedHijriString(for: selectedDate))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            NavigationLink {
                AnalyticsView()
            } label: {
                StreakBadgeView(streakCount: streakCount, isFrozen: isPeriodModeActive)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var periodModeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "snowflake")
                .font(.title3)
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("Period Mode Active")
                    .font(.subheadline.bold())
                Text("Streak is frozen. Daily prayers are excused.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Deactivate") {
                SwiftDataStore.shared.togglePeriodMode(isActive: false)
                reloadAllData()
            }
            .font(.caption.bold())
            .buttonStyle(.bordered)
            .tint(.cyan)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cyan.opacity(0.12))
        )
    }

    private var countdownHeroCard: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            if let schedule = todaySchedule {
                let next = PrayerTimeService.shared.nextPrayer(at: timeline.date, schedule: schedule, tomorrowSchedule: tomorrowSchedule)
                let countdown = PrayerTimeService.shared.formattedCountdown(at: timeline.date, schedule: schedule, tomorrowSchedule: tomorrowSchedule)
                let progress = PrayerTimeService.shared.currentPrayerWindowProgress(at: timeline.date, schedule: schedule, tomorrowSchedule: tomorrowSchedule)
                let current = PrayerTimeService.shared.currentPrayer(at: timeline.date, schedule: schedule)

                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(current != nil ? "CURRENT: \(current!.displayName.uppercased())" : "NEXT PRAYER")
                                .font(.caption.bold())
                                .foregroundStyle(Color.green)

                            HStack(spacing: 8) {
                                Text(next.prayer.displayName)
                                    .font(.system(size: 28, weight: .bold))

                                Text(next.prayer.arabicName)
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Countdown")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(countdown)
                                .font(.system(size: 26, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }

                    // Prayer Window Progress
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("Adhan: \(next.time.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if next.isTomorrow {
                                Text("Tomorrow")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.green.opacity(0.25), lineWidth: 1.5)
                        )
                )
            } else {
                ProgressView("Calculating prayer times...")
                    .frame(height: 120)
            }
        }
    }

    private var prayerChecklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Prayers")
                    .font(.title3.bold())

                Spacer()

                let completedCount = todayLogs.filter { $0.status.countsTowardStreak }.count
                Text("\(completedCount) of 5 completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let schedule = todaySchedule {
                let current = PrayerTimeService.shared.currentPrayer(schedule: schedule)

                ForEach(PrayerType.allCases) { prayer in
                    let prayerTime = schedule.time(for: prayer)
                    let log = todayLogs.first(where: { $0.prayer == prayer })
                    let status = log?.status ?? (isPeriodModeActive ? .excused : .pending)

                    PrayerCheckboxRow(
                        prayer: prayer,
                        scheduledTime: prayerTime,
                        status: status,
                        isCurrentPrayerWindow: (current == prayer)
                    ) { newStatus in
                        handlePrayerStatusChange(prayer: prayer, newStatus: newStatus)
                    }
                }
            }
        }
    }

    private var quickNavigationGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                NavigationLink {
                    ScreenTimePickerView()
                } label: {
                    HStack {
                        Image(systemName: "hourglass.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Blocker")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)

                            Text(screenTimeManager.isAuthorized ? "Active" : "Configure")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }

                NavigationLink {
                    AnalyticsView()
                } label: {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Analytics")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)

                            Text("Streak: \(streakCount) Days")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }
            }

            HStack(spacing: 12) {
                NavigationLink {
                    QuranSurahListView()
                } label: {
                    HStack {
                        Image(systemName: "book.pages.fill")
                            .font(.title2)
                            .foregroundStyle(.teal)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Noble Quran")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)

                            Text("114 Surahs • Audio")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }

                NavigationLink {
                    KnowledgeFeedView()
                } label: {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Knowledge")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)

                            Text("Khushu', Fiqh, Hadith")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                }
            }

            NavigationLink {
                CircleDashboardView()
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prayer Circles")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)

                        Text("Social Accountability & Nudges")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
            }
        }
    }

    // MARK: - Actions & Persistence

    private func handlePrayerStatusChange(prayer: PrayerType, newStatus: PrayerStatus) {
        SwiftDataStore.shared.updatePrayerStatus(
            prayer: prayer,
            on: selectedDate,
            status: newStatus,
            completedAt: newStatus.isLogged ? Date() : nil
        )

        // Instant Screen Time Unlocking
        if newStatus == .completedOnTime || newStatus == .completedLate {
            screenTimeManager.instantUnlock(for: prayer)
        }

        reloadAllData()
    }

    private func reloadAllData() {
        let settings = SwiftDataStore.shared.fetchSettings()
        self.isPeriodModeActive = settings.isPeriodModeActive

        let lat = locationManager.userLocation?.coordinate.latitude ?? (settings.lastKnownLatitude ?? 21.4225)
        let lon = locationManager.userLocation?.coordinate.longitude ?? (settings.lastKnownLongitude ?? 39.8262)

        let schedule = PrayerTimeService.shared.calculateSchedule(
            for: selectedDate,
            latitude: lat,
            longitude: lon,
            settings: settings
        )
        self.todaySchedule = schedule

        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            self.tomorrowSchedule = PrayerTimeService.shared.calculateSchedule(
                for: tomorrow,
                latitude: lat,
                longitude: lon,
                settings: settings
            )
        }

        let hijriStr = HijriCalendarHelper.formattedHijriString(for: selectedDate)
        self.todayLogs = SwiftDataStore.shared.ensureLogs(
            for: selectedDate,
            hijriDateString: hijriStr,
            timings: schedule.obligatoryPrayers
        )

        let streakSummary = StreakEngine.shared.calculateStreakSummary()
        self.streakCount = streakSummary.current
    }
}
