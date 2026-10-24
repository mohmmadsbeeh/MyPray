import Foundation
import Combine
import DeviceActivity
import ManagedSettings

#if canImport(FamilyControls)
import FamilyControls
#endif

@MainActor
public final class ScreenTimeManager: ObservableObject {
    public static let shared = ScreenTimeManager()

    @Published public private(set) var isAuthorized: Bool = false
    @Published public private(set) var authorizationError: String?
    @Published public var activitySelection = FamilyActivitySelection()
    @Published public var isShieldCurrentlyActive: Bool = false

    private let deviceActivityCenter = DeviceActivityCenter()
    private let managedSettingsStore = ManagedSettingsStore(named: ScreenTimeConstants.managedSettingsStoreName)

    private init() {
        checkAuthorizationStatus()
        loadSavedSelection()
        self.isShieldCurrentlyActive = ScreenTimeAppGroupBridge.shared.isShieldActive()
    }

    // MARK: - Authorization

    public func checkAuthorizationStatus() {
        #if canImport(FamilyControls)
        let status = AuthorizationCenter.shared.authorizationStatus
        self.isAuthorized = (status == .approved)
        #endif
    }

    public func requestAuthorization() async {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.isAuthorized = (AuthorizationCenter.shared.authorizationStatus == .approved)
            self.authorizationError = nil
        } catch {
            self.isAuthorized = false
            self.authorizationError = error.localizedDescription
        }
        #endif
    }

    // MARK: - Selection Persistence

    public func loadSavedSelection() {
        #if canImport(FamilyControls)
        let loaded = ScreenTimeAppGroupBridge.shared.loadSelection()
        self.activitySelection = loaded
        #endif
    }

    public func updateSelection(_ newSelection: FamilyActivitySelection) {
        #if canImport(FamilyControls)
        self.activitySelection = newSelection
        ScreenTimeAppGroupBridge.shared.saveSelection(newSelection)

        // Also persist in SwiftData model
        let storedSelection = SwiftDataStore.shared.fetchBlockedAppSelection()
        storedSelection.activitySelection = newSelection
        try? SwiftDataStore.shared.context.save()
        #endif
    }

    // MARK: - Scheduling Device Activity Prayer Windows

    public func schedulePrayerBlocking(
        dailySchedule: DailyPrayerSchedule,
        durationMinutes: Int
    ) {
        guard isAuthorized else { return }

        ScreenTimeAppGroupBridge.shared.setBlockDurationMinutes(durationMinutes)
        let calendar = Calendar.current

        for (prayer, prayerTime) in dailySchedule.obligatoryPrayers {
            let activityName = ScreenTimeConstants.activityName(for: prayer.displayName)
            let endTime = prayerTime.addingTimeInterval(Double(durationMinutes * 60))

            let startComponents = calendar.dateComponents([.hour, .minute], from: prayerTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

            let schedule = DeviceActivitySchedule(
                intervalStart: startComponents,
                intervalEnd: endComponents,
                repeats: true,
                warningTime: DateComponents(minute: 5)
            )

            do {
                try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            } catch {
                #if DEBUG
                print("Failed to schedule DeviceActivity for \(prayer.displayName): \(error.localizedDescription)")
                #endif
            }
        }
    }

    public func stopAllPrayerMonitoring() {
        deviceActivityCenter.stopMonitoring()
        clearShields()
    }

    // MARK: - Instant Unlock Functionality

    public func instantUnlock(for prayer: PrayerType) {
        // 1. Clear ManagedSettings shield
        clearShields()

        // 2. Mark this prayer as unlocked for the rest of today
        ScreenTimeAppGroupBridge.shared.markPrayerUnlocked(prayer.displayName, date: Date())
        ScreenTimeAppGroupBridge.shared.setActiveBlockedPrayer(nil)
        self.isShieldCurrentlyActive = false

        // 3. Mark prayer completed in SwiftData
        SwiftDataStore.shared.updatePrayerStatus(
            prayer: prayer,
            on: Date(),
            status: .completedOnTime,
            completedAt: Date()
        )
    }

    public func clearShields() {
        managedSettingsStore.shield.applications = nil
        managedSettingsStore.shield.applicationCategories = nil
        managedSettingsStore.shield.webDomains = nil
        ScreenTimeAppGroupBridge.shared.setActiveBlockedPrayer(nil)
        self.isShieldCurrentlyActive = false
    }

    // MARK: - Immediate Shield Testing

    public func applyImmediateShield(for prayerName: String = "Dhuhr") {
        #if canImport(FamilyControls)
        guard isAuthorized else { return }
        let selection = activitySelection

        if !selection.applicationTokens.isEmpty {
            managedSettingsStore.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        }
        if !selection.webDomainTokens.isEmpty {
            managedSettingsStore.shield.webDomains = selection.webDomainTokens
        }

        ScreenTimeAppGroupBridge.shared.setActiveBlockedPrayer(prayerName)
        self.isShieldCurrentlyActive = true
        #endif
    }
}
