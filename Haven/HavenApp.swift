import SwiftUI
import UserNotifications

@main
struct HavenApp: App {
    @StateObject private var notifManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(notifManager)
                .task {
                    // Re-check permission status on each launch
                    await notifManager.refreshPermissionStatus()
                }
        }
    }
}
