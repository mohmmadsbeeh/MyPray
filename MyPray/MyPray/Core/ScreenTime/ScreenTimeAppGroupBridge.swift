import Foundation
#if canImport(FamilyControls)
import FamilyControls
#endif

public final class ScreenTimeAppGroupBridge {
    public static let shared = ScreenTimeAppGroupBridge()

    private let userDefaults: UserDefaults?

    private init() {
        self.userDefaults = UserDefaults(suiteName: ScreenTimeConstants.appGroupSuiteName)
    }

    // MARK: - Active Blocked Prayer Tracking

    public func setActiveBlockedPrayer(_ prayerName: String?) {
        userDefaults?.set(prayerName, forKey: ScreenTimeConstants.keyCurrentBlockedPrayer)
        userDefaults?.set(prayerName != nil, forKey: ScreenTimeConstants.keyIsShieldActive)
        userDefaults?.synchronize()
    }

    public func getActiveBlockedPrayer() -> String? {
        return userDefaults?.string(forKey: ScreenTimeConstants.keyCurrentBlockedPrayer)
    }

    public func isShieldActive() -> Bool {
        return userDefaults?.bool(forKey: ScreenTimeConstants.keyIsShieldActive) ?? false
    }

    // MARK: - Daily Prayer Unlocks

    private func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    public func markPrayerUnlocked(_ prayerName: String, date: Date = Date()) {
        let key = "\(ScreenTimeConstants.keyUnlockedPrayersPrefix)\(dayKey(for: date))_\(prayerName.lowercased())"
        userDefaults?.set(true, forKey: key)
        userDefaults?.synchronize()
    }

    public func isPrayerUnlockedToday(_ prayerName: String, date: Date = Date()) -> Bool {
        let key = "\(ScreenTimeConstants.keyUnlockedPrayersPrefix)\(dayKey(for: date))_\(prayerName.lowercased())"
        return userDefaults?.bool(forKey: key) ?? false
    }

    // MARK: - Blocked App Selection Data Persistence

    #if canImport(FamilyControls)
    public func saveSelection(_ selection: FamilyActivitySelection) {
        let encoder = PropertyListEncoder()
        if let data = try? encoder.encode(selection) {
            userDefaults?.set(data, forKey: ScreenTimeConstants.keySavedSelectionData)
            userDefaults?.synchronize()
        }
    }

    public func loadSelection() -> FamilyActivitySelection {
        guard let data = userDefaults?.data(forKey: ScreenTimeConstants.keySavedSelectionData) else {
            return FamilyActivitySelection()
        }
        let decoder = PropertyListDecoder()
        return (try? decoder.decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
    }
    #endif

    public func setBlockDurationMinutes(_ minutes: Int) {
        userDefaults?.set(minutes, forKey: ScreenTimeConstants.keyBlockDurationMinutes)
        userDefaults?.synchronize()
    }

    public func getBlockDurationMinutes() -> Int {
        let val = userDefaults?.integer(forKey: ScreenTimeConstants.keyBlockDurationMinutes) ?? 0
        return val > 0 ? val : 30
    }
}
