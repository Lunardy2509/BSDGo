import SwiftUI
import UserNotifications
import ActivityKit
import FirebaseCore

@main
struct BSDGoApp: App {
    
    init() {
        
        FirebaseApp.configure()
        
        Task {
            await NotificationManager.shared.requestNotificationPermission()
        }
        
        _ = LiveActivityManager.shared
        
        Task {
            for activity in Activity<BusTrackingModel>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}
