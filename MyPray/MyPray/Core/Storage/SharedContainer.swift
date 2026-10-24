import Foundation
import SwiftData

public final class SharedContainer {
    public static let appGroupIdentifier = "group.com.mypray.app"
    public static let databaseFilename = "MyPrayData.sqlite"

    public static let sharedModelContainer: ModelContainer = {
        do {
            return try makeContainer()
        } catch {
            fatalError("CRITICAL: Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }()

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            PrayerLog.self,
            UserSettings.self,
            BlockedAppSelection.self
        ])

        if inMemory {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [configuration])
        }

        let storeURL: URL
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            storeURL = appGroupURL.appendingPathComponent(databaseFilename)
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            storeURL = appSupport.appendingPathComponent(databaseFilename)
        }

        let configuration = ModelConfiguration(
            "MyPrayConfiguration",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        let container = try ModelContainer(for: schema, configurations: [configuration])
        ensureDefaultSettings(in: container)
        return container
    }

    private static func ensureDefaultSettings(in container: ModelContainer) {
        Task { @MainActor in
            let context = container.mainContext
            let descriptor = FetchDescriptor<UserSettings>()
            if let existing = try? context.fetch(descriptor), existing.isEmpty {
                let defaultSettings = UserSettings()
                context.insert(defaultSettings)
                try? context.save()
            }
        }
    }
}
