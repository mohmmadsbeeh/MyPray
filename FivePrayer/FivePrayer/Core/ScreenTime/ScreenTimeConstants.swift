import Foundation
import DeviceActivity
import ManagedSettings

public enum ScreenTimeConstants {
    public static let appGroupSuiteName = "group.com.fiveprayer.app"
    public static let managedSettingsStoreName = ManagedSettingsStore.Name("FivePrayerShieldStore")

    // DeviceActivity Names for each prayer window
    public static let activityFajr = DeviceActivityName("com.fiveprayer.activity.fajr")
    public static let activityDhuhr = DeviceActivityName("com.fiveprayer.activity.dhuhr")
    public static let activityAsr = DeviceActivityName("com.fiveprayer.activity.asr")
    public static let activityMaghrib = DeviceActivityName("com.fiveprayer.activity.maghrib")
    public static let activityIsha = DeviceActivityName("com.fiveprayer.activity.isha")

    // App Group UserDefaults Keys
    public static let keyCurrentBlockedPrayer = "fiveprayer_current_blocked_prayer"
    public static let keyUnlockedPrayersPrefix = "fiveprayer_unlocked_"
    public static let keySavedSelectionData = "fiveprayer_saved_selection_data"
    public static let keyIsShieldActive = "fiveprayer_is_shield_active"
    public static let keyBlockDurationMinutes = "fiveprayer_block_duration_minutes"

    public static func activityName(for prayerName: String) -> DeviceActivityName {
        switch prayerName.lowercased() {
        case "fajr": return activityFajr
        case "dhuhr": return activityDhuhr
        case "asr": return activityAsr
        case "maghrib": return activityMaghrib
        case "isha": return activityIsha
        default: return DeviceActivityName("com.fiveprayer.activity.\(prayerName.lowercased())")
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
