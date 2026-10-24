import SwiftUI
import SwiftData

@main
struct FivePrayerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var locationManager = LocationManager.shared
    private let sharedModelContainer = SharedContainer.sharedModelContainer

    var body: some Scene {
        WindowGroup {
            HomeDashboardView()
                .environmentObject(locationManager)
                .task {
                    // Request location & notification permissions on startup
                    locationManager.requestLocationAuthorization()
                    _ = await NotificationScheduler.shared.requestNotificationPermission()

                    // Automatically refresh notifications when location is determined
                    if let location = locationManager.userLocation {
                        let settings = await SwiftDataStore.shared.fetchSettings()
                        await NotificationScheduler.shared.rescheduleAllPrayerNotifications(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            settings: settings
                        )

                        if settings.isScreenTimeBlockerEnabled {
                            let schedule = PrayerTimeService.shared.calculateSchedule(
                                for: Date(),
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude,
                                settings: settings
                            )
                            ScreenTimeManager.shared.schedulePrayerBlocking(
                                dailySchedule: schedule,
                                durationMinutes: settings.screenTimeBlockDurationMinutes
                            )
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var screenTimeManager = ScreenTimeManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Prayer & Location") {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.green)
                        Text("City")
                        Spacer()
                        Text(locationManager.cityName)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "safari.fill")
                            .foregroundStyle(.green)
                        Text("Qibla Bearing")
                        Spacer()
                        Text("\(Int(locationManager.qiblaBearing))°")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Focus & Discipline") {
                    NavigationLink {
                        ScreenTimePickerView()
                    } label: {
                        HStack {
                            Image(systemName: "hourglass.badge.plus")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text("App Blocker (Screen Time)")
                                    .font(.headline)
                                Text(screenTimeManager.isAuthorized ? "Configured & Active" : "Authorization Required")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if screenTimeManager.isShieldCurrentlyActive {
                        Button {
                            screenTimeManager.instantUnlock(for: .dhuhr)
                        } label: {
                            Label("Mark Prayer Prayed & Unlock Apps", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("FivePrayer")
        }
    }
}
