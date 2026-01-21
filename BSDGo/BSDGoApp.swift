import SwiftUI
import UserNotifications
import FirebaseCore

@main
struct BSDGoApp: App {
    
    init() {
        
        FirebaseApp.configure()
        
        Task {
            await NotificationManager.shared.requestNotificationPermission()
        }
        
        _ = LiveActivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}
