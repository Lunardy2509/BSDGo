import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        Task {
            await requestNotificationPermission()
        }
    }
    
    func requestNotificationPermission() async {
        do {
            let result = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = result
        } catch {
            print("Failed to request notification permission: \(error)")
            isAuthorized = false
        }
    }
    
    func scheduleBusArrivalNotification(busName: String, stopName: String, timeInterval: TimeInterval) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Bus Arrival"
        content.body = "\(busName) is arriving at \(stopName) now!"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "bus-arrival-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Bus arrival notification scheduled for \(timeInterval) seconds")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(withIdentifierPrefix prefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
}
