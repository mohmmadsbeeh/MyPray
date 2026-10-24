import UIKit
import UserNotifications

public final class AppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Assign notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationScheduler.shared

        // Register action categories
        NotificationScheduler.shared.registerNotificationCategories()

        return true
    }

    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        #if DEBUG
        print("Device Token for APNs: \(token)")
        #endif
    }

    public func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("Failed to register for APNs: \(error.localizedDescription)")
        #endif
    }
}
