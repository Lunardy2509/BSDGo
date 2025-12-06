import SwiftUI
import SwiftData
import UserNotifications

@main
struct BSDGoApp: App {
    
    init() {
        // Initialize notification manager on app launch
        Task {
            await NotificationManager.shared.requestNotificationPermission()
        }
        
        // Initialize Live Activity Manager
        _ = LiveActivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}
