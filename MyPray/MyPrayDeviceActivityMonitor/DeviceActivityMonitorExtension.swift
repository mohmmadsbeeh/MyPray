import DeviceActivity
import ManagedSettings
import Foundation

// MARK: - DeviceActivity Monitor Extension
// Target: PrayerDeviceActivityMonitor

public final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let managedSettingsStore = ManagedSettingsStore(named: ScreenTimeConstants.managedSettingsStoreName)

    override public func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let prayerName = ScreenTimeConstants.prayerName(from: activity)

        // 1. Verify if the user already prayed and unlocked this prayer window
        if ScreenTimeAppGroupBridge.shared.isPrayerUnlockedToday(prayerName) {
            #if DEBUG
            print("[DeviceActivityMonitor] Prayer \(prayerName) was already completed and unlocked today. Skipping shield.")
            #endif
            return
        }

        // 2. Load the user's selected applications and categories
        #if canImport(FamilyControls)
        let selection = ScreenTimeAppGroupBridge.shared.loadSelection()

        // 3. Set the active prayer key for ShieldConfiguration UI
        ScreenTimeAppGroupBridge.shared.setActiveBlockedPrayer(prayerName)

        // 4. Apply the application and category shields
        if !selection.applicationTokens.isEmpty {
            managedSettingsStore.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        }
        if !selection.webDomainTokens.isEmpty {
            managedSettingsStore.shield.webDomains = selection.webDomainTokens
        }

        #if DEBUG
        print("[DeviceActivityMonitor] Shield applied for \(prayerName) prayer window.")
        #endif
        #endif
    }

    override public func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let prayerName = ScreenTimeConstants.prayerName(from: activity)

        // Clear all shields at the expiration of the window
        managedSettingsStore.shield.applications = nil
        managedSettingsStore.shield.applicationCategories = nil
        managedSettingsStore.shield.webDomains = nil
        ScreenTimeAppGroupBridge.shared.setActiveBlockedPrayer(nil)

        #if DEBUG
        print("[DeviceActivityMonitor] Shield removed for \(prayerName) prayer window expiration.")
        #endif
    }
}
