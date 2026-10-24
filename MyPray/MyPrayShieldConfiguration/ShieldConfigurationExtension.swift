import ManagedSettings
import ManagedSettingsUI
import UIKit

// MARK: - Shield Configuration Extension
// Target: PrayerShieldConfiguration

public final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private func createPrayerShieldConfiguration(for prayerName: String) -> ShieldConfiguration {
        let backgroundColor = UIColor(red: 16/255, green: 24/255, blue: 32/255, alpha: 1.0)
        let emeraldGreen = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0)
        let iconImage = UIImage(systemName: "moon.stars.fill")?.withTintColor(emeraldGreen, renderingMode: .alwaysOriginal)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: backgroundColor,
            icon: iconImage,
            title: ShieldConfiguration.Label(
                text: "Time for \(prayerName)",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Distracting apps are locked during prayer time. Pray first to unlock your phone and protect your Salah.",
                color: UIColor.lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open MyPray to Pray",
                color: .white
            ),
            primaryButtonBackgroundColor: emeraldGreen,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Dismiss",
                color: UIColor.systemGray
            )
        )
    }

    private var activePrayerName: String {
        return ScreenTimeAppGroupBridge.shared.getActiveBlockedPrayer() ?? "Prayer"
    }

    override public func configuration(shielding application: Application) -> ShieldConfiguration {
        return createPrayerShieldConfiguration(for: activePrayerName)
    }

    override public func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return createPrayerShieldConfiguration(for: activePrayerName)
    }

    override public func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createPrayerShieldConfiguration(for: activePrayerName)
    }

    override public func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return createPrayerShieldConfiguration(for: activePrayerName)
    }
}
