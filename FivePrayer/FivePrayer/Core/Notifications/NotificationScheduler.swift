import Foundation
import UserNotifications
import CoreLocation

public final class NotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()

    override private init() {
        super.init()
        center.delegate = self
        registerNotificationCategories()
    }

    // MARK: - Permissions & Setup

    public func requestNotificationPermission() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await center.requestAuthorization(options: options)
            if granted {
                registerNotificationCategories()
            }
            return granted
        } catch {
            return false
        }
    }

    public func registerNotificationCategories() {
        let markPrayedAction = UNNotificationAction(
            identifier: NotificationConstants.actionMarkPrayed,
            title: "Mark as Prayed",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: NotificationConstants.actionSnooze10,
            title: "Snooze 10 Min",
            options: []
        )

        let prayerCategory = UNNotificationCategory(
            identifier: NotificationConstants.categoryPrayerAlert,
            actions: [markPrayedAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let fajrCategory = UNNotificationCategory(
            identifier: NotificationConstants.categoryFajrWakeup,
            actions: [markPrayedAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let prePrayerCategory = UNNotificationCategory(
            identifier: NotificationConstants.categoryPrePrayer,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([prayerCategory, fajrCategory, prePrayerCategory])
    }

    // MARK: - Schedule Rolling Window (5 Days = 50 Requests max, staying well under iOS 64 limit)

    public func rescheduleAllPrayerNotifications(
        latitude: Double,
        longitude: Double,
        settings: UserSettings
    ) async {
        // Step 1: Check Period Mode
        if settings.isPeriodModeActive {
            cancelAllScheduledNotifications()
            return
        }

        // Step 2: Clear existing scheduled prayer alerts
        cancelAllScheduledNotifications()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysToSchedule = 5 // 5 days * (5 adhans + 5 pre-prayer) = max 50 notifications

        for dayOffset in 0..<daysToSchedule {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            let schedule = PrayerTimeService.shared.calculateSchedule(
                for: targetDate,
                latitude: latitude,
                longitude: longitude,
                settings: settings
            )

            for (prayer, prayerTime) in schedule.obligatoryPrayers {
                // If the prayer time is already in the past, skip it
                if prayerTime <= Date() {
                    continue
                }

                // 1. Schedule Pre-Prayer Warning Alert (if configured)
                let preMinutes = settings.prePrayerNotificationMinutes
                if preMinutes > 0 {
                    let prePrayerTime = prayerTime.addingTimeInterval(-Double(preMinutes * 60))
                    if prePrayerTime > Date() {
                        schedulePrePrayerAlert(
                            for: prayer,
                            at: prePrayerTime,
                            minutesRemaining: preMinutes
                        )
                    }
                }

                // 2. Schedule Primary Adhan Alert
                let voice = settings.voice(for: prayer)
                scheduleAdhanAlert(
                    for: prayer,
                    at: prayerTime,
                    voice: voice
                )
            }
        }
    }

    private func scheduleAdhanAlert(
        for prayer: PrayerType,
        at date: Date,
        voice: AdhanVoiceOption
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(prayer.displayName) Prayer Time"
        content.body = "It is now time for \(prayer.displayName) (\(prayer.arabicName)). Hayya 'ala-s-Salah."

        // Configure Category
        if prayer == .fajr {
            content.categoryIdentifier = NotificationConstants.categoryFajrWakeup
        } else {
            content.categoryIdentifier = NotificationConstants.categoryPrayerAlert
        }

        // Sound Payload
        if let soundFileName = voice.soundFileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundFileName))
        } else if voice != .silent {
            content.sound = .default
        }

        content.userInfo = [
            NotificationConstants.userInfoPrayerKey: prayer.rawValue,
            NotificationConstants.userInfoScheduledDateKey: ISO8601DateFormatter().string(from: date),
            NotificationConstants.userInfoIsPrePrayerKey: false
        ]

        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let identifier = "adhan_\(prayer.rawValue)_\(Int(date.timeIntervalSince1970))"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func schedulePrePrayerAlert(
        for prayer: PrayerType,
        at date: Date,
        minutesRemaining: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Prayer: \(prayer.displayName)"
        content.body = "\(prayer.displayName) begins in \(minutesRemaining) minutes. Prepare for Wudu."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("chime.caf"))
        content.categoryIdentifier = NotificationConstants.categoryPrePrayer
        content.userInfo = [
            NotificationConstants.userInfoPrayerKey: prayer.rawValue,
            NotificationConstants.userInfoScheduledDateKey: ISO8601DateFormatter().string(from: date),
            NotificationConstants.userInfoIsPrePrayerKey: true
        ]

        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let identifier = "pre_\(prayer.rawValue)_\(Int(date.timeIntervalSince1970))"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    public func scheduleSnoozeAlert(for prayer: PrayerType, delayMinutes: Int = 10) {
        let content = UNMutableNotificationContent()
        content.title = "Snooze Reminder: \(prayer.displayName)"
        content.body = "You snoozed \(prayer.displayName). It is time to pray now."
        content.sound = .default
        content.categoryIdentifier = NotificationConstants.categoryPrayerAlert
        content.userInfo = [
            NotificationConstants.userInfoPrayerKey: prayer.rawValue,
            NotificationConstants.userInfoScheduledDateKey: ISO8601DateFormatter().string(from: Date()),
            NotificationConstants.userInfoIsPrePrayerKey: false
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(delayMinutes * 60),
            repeats: false
        )
        let identifier = "snooze_\(prayer.rawValue)_\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    public func cancelAllScheduledNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is active
        completionHandler([.banner, .sound, .badge])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let prayerRaw = userInfo[NotificationConstants.userInfoPrayerKey] as? String,
              let prayer = PrayerType(rawValue: prayerRaw) else {
            completionHandler()
            return
        }

        switch response.actionIdentifier {
        case NotificationConstants.actionMarkPrayed:
            Task { @MainActor in
                SwiftDataStore.shared.updatePrayerStatus(
                    prayer: prayer,
                    on: Date(),
                    status: .completedOnTime,
                    completedAt: Date()
                )
            }
        case NotificationConstants.actionSnooze10:
            let snoozeMinutes = SwiftDataStore.shared.fetchSettings().snoozeIntervalMinutes
            scheduleSnoozeAlert(for: prayer, delayMinutes: snoozeMinutes > 0 ? snoozeMinutes : 10)
        default:
            break
        }

        completionHandler()
    }
}
