import UserNotifications
import SwiftUI

// MARK: - NotificationManager
@MainActor
class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published var permissionGranted: Bool = false
    @Published var lastCheckInResponse: CheckInAction? = nil

    // MARK: - Setup
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task { await refreshPermissionStatus() }
    }

    func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionGranted = settings.authorizationStatus == .authorized
    }

    // MARK: - Request Permission
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
            if granted { registerCategories() }
        } catch {
            permissionGranted = false
        }
    }

    // MARK: - Register interactive categories (reply actions)
    private func registerCategories() {
        // Check-in actions
        let okay    = UNNotificationAction(identifier: CheckInAction.feelingOkay.rawValue,
                                           title: "I'm okay 🌿",
                                           options: [])
        let heavy   = UNNotificationAction(identifier: CheckInAction.feelingHeavy.rawValue,
                                           title: "A little heavy",
                                           options: [])
        let struggle = UNNotificationAction(identifier: CheckInAction.feelingStruggle.rawValue,
                                            title: "Struggling today",
                                            options: [])
        let later   = UNNotificationAction(identifier: CheckInAction.remindLater.rawValue,
                                           title: "Remind me in 30 min",
                                           options: [])

        let checkInCat = UNNotificationCategory(
            identifier: HavenNotificationCategory.checkIn.rawValue,
            actions: [okay, heavy, struggle, later],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Nudge actions
        let tryNow  = UNNotificationAction(identifier: "TRY_NOW",   title: "I'll try one 🌱", options: [])
        let notNow  = UNNotificationAction(identifier: "NOT_NOW",   title: "Maybe later",      options: [])
        let nudgeCat = UNNotificationCategory(
            identifier: HavenNotificationCategory.gentleNudge.rawValue,
            actions: [tryNow, notNow],
            intentIdentifiers: [],
            options: []
        )

        // Future self actions
        let rest   = UNNotificationAction(identifier: "WILL_REST",  title: "I'll rest 🌙",  options: [])
        let keep   = UNNotificationAction(identifier: "KEEP_GOING", title: "Keep going",     options: [])
        let futureCat = UNNotificationCategory(
            identifier: HavenNotificationCategory.futureself.rawValue,
            actions: [rest, keep],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([checkInCat, nudgeCat, futureCat])
    }

    // MARK: - Schedule: Daily check-in
    func scheduleDailyCheckIn(hour: Int, minute: Int) {
        removeNotifications(withPrefix: "checkin")

        var comps = DateComponents()
        comps.hour   = hour
        comps.minute = minute

        let msgs = HavenMessages.checkIns
        let msg  = msgs[Calendar.current.component(.weekday, from: Date()) % msgs.count]

        schedule(
            id:       "checkin-daily",
            title:    msg.title,
            body:     msg.body,
            category: .checkIn,
            trigger:  UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        )
    }

    // MARK: - Schedule: Pattern-aware (morning + afternoon)
    func schedulePatternReminders() {
        removeNotifications(withPrefix: "pattern")

        let slots: [(hour: Int, minute: Int)] = [(9, 0), (14, 0), (20, 30)]
        for (i, slot) in slots.enumerated() {
            let msg = HavenMessages.patternMessage(hour: slot.hour)
            var comps = DateComponents()
            comps.hour   = slot.hour
            comps.minute = slot.minute
            schedule(
                id:       "pattern-\(i)",
                title:    msg.title,
                body:     msg.body,
                category: .checkIn,
                trigger:  UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            )
        }
    }

    // MARK: - Schedule: Gentle seed nudge
    func scheduleNudge(hour: Int = 10, minute: Int = 0) {
        removeNotifications(withPrefix: "nudge")
        var comps = DateComponents()
        comps.hour   = hour
        comps.minute = minute
        let msg = HavenMessages.nudges.randomElement()!
        schedule(
            id:       "nudge-daily",
            title:    msg.title,
            body:     msg.body,
            category: .gentleNudge,
            trigger:  UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        )
    }

    // MARK: - Schedule: Future self (evening)
    func scheduleFutureSelf(hour: Int = 21, minute: Int = 0) {
        removeNotifications(withPrefix: "future")
        var comps = DateComponents()
        comps.hour   = hour
        comps.minute = minute
        let msg = HavenMessages.futureself.randomElement()!
        schedule(
            id:       "future-daily",
            title:    msg.title,
            body:     msg.body,
            category: .futureself,
            trigger:  UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        )
    }

    // MARK: - One-off "remind me later" (30 min)
    func remindLater() {
        let msg = HavenMessages.checkIns.randomElement()!
        schedule(
            id:       "remind-later-\(Date().timeIntervalSince1970)",
            title:    msg.title,
            body:     msg.body,
            category: .checkIn,
            trigger:  UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
        )
    }

    // MARK: - Cancel all
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Private helpers
    private func schedule(id: String, title: String, body: String,
                          category: HavenNotificationCategory,
                          trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title    = title
        content.body     = body
        content.sound    = .default
        content.categoryIdentifier = category.rawValue
        // Thread identifier groups Haven notifications in Notification Center
        content.threadIdentifier = "haven"

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Haven notification error: \(error)") }
        }
    }

    private func removeNotifications(withPrefix prefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {

    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    // Handle tap / action response
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let actionId = response.actionIdentifier

        switch actionId {
        case CheckInAction.feelingOkay.rawValue:
            lastCheckInResponse = .feelingOkay
        case CheckInAction.feelingHeavy.rawValue:
            lastCheckInResponse = .feelingHeavy
        case CheckInAction.feelingStruggle.rawValue:
            lastCheckInResponse = .feelingStruggle
        case CheckInAction.remindLater.rawValue:
            remindLater()
        default:
            break
        }
    }
}
