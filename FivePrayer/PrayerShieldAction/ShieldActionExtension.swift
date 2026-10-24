import ManagedSettings
import Foundation

// MARK: - Shield Action Extension
// Target: PrayerShieldAction

public final class ShieldActionExtension: ShieldActionDelegate {
    override public func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // User chose "Open FivePrayer to Pray" -> Close the shielded application
            completionHandler(.close)
        case .secondaryButtonPressed:
            // User chose "Dismiss" -> Close the shielded application
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override public func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed, .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override public func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed, .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }
}
