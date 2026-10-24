import Foundation
import SwiftData

#if canImport(FamilyControls)
import FamilyControls
#endif

@Model
public final class BlockedAppSelection {
    @Attribute(.unique) public var id: String
    public var rawData: Data?
    public var totalApplicationCount: Int
    public var totalCategoryCount: Int
    public var totalWebDomainCount: Int
    public var updatedAt: Date

    public init(
        id: String = "default_prayer_block_selection",
        rawData: Data? = nil,
        totalApplicationCount: Int = 0,
        totalCategoryCount: Int = 0,
        totalWebDomainCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.rawData = rawData
        self.totalApplicationCount = totalApplicationCount
        self.totalCategoryCount = totalCategoryCount
        self.totalWebDomainCount = totalWebDomainCount
        self.updatedAt = updatedAt
    }

    #if canImport(FamilyControls)
    public var activitySelection: FamilyActivitySelection {
        get {
            guard let rawData = rawData else {
                return FamilyActivitySelection()
            }
            let decoder = PropertyListDecoder()
            if let decoded = try? decoder.decode(FamilyActivitySelection.self, from: rawData) {
                return decoded
            }
            return FamilyActivitySelection()
        }
        set {
            let encoder = PropertyListEncoder()
            if let encoded = try? encoder.encode(newValue) {
                self.rawData = encoded
                self.totalApplicationCount = newValue.applicationTokens.count
                self.totalCategoryCount = newValue.categoryTokens.count
                self.totalWebDomainCount = newValue.webDomainTokens.count
                self.updatedAt = Date()
            }
        }
    }
    #endif
}
