import Foundation
import DeviceActivity
import ManagedSettings

public enum ScreenTimeConstants {
    public static let appGroupSuiteName = "group.com.mypray.app"
    public static let managedSettingsStoreName = ManagedSettingsStore.Name("MyPrayShieldStore")

    // DeviceActivity Names for each prayer window
    public static let activityFajr = DeviceActivityName("com.mypray.activity.fajr")
    public static let activityDhuhr = DeviceActivityName("com.mypray.activity.dhuhr")
    public static let activityAsr = DeviceActivityName("com.mypray.activity.asr")
    public static let activityMaghrib = DeviceActivityName("com.mypray.activity.maghrib")
    public static let activityIsha = DeviceActivityName("com.mypray.activity.isha")

    // App Group UserDefaults Keys
    public static let keyCurrentBlockedPrayer = "mypray_current_blocked_prayer"
    public static let keyUnlockedPrayersPrefix = "mypray_unlocked_"
    public static let keySavedSelectionData = "mypray_saved_selection_data"
    public static let keyIsShieldActive = "mypray_is_shield_active"
    public static let keyBlockDurationMinutes = "mypray_block_duration_minutes"

    public static func activityName(for prayerName: String) -> DeviceActivityName {
        switch prayerName.lowercased() {
        case "fajr": return activityFajr
        case "dhuhr": return activityDhuhr
        case "asr": return activityAsr
        case "maghrib": return activityMaghrib
        case "isha": return activityIsha
        default: return DeviceActivityName("com.mypray.activity.\(prayerName.lowercased())")
        }
    }

    public static func prayerName(from activity: DeviceActivityName) -> String {
        switch activity {
        case activityFajr: return "Fajr"
        case activityDhuhr: return "Dhuhr"
        case activityAsr: return "Asr"
        case activityMaghrib: return "Maghrib"
        case activityIsha: return "Isha"
        default:
            let raw = activity.rawValue
            if let lastPart = raw.components(separatedBy: ".").last {
                return lastPart.capitalized
            }
            return "Prayer"
        }
    }
}
