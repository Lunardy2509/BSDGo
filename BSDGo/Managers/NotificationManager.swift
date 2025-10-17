import Foundation
import UserNotifications
import CoreLocation

// MARK: - Supporting Types
struct BusStopCoordinate {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
}

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    // Track scheduled notifications to avoid duplicates
    private var scheduledNotifications: Set<String> = []
    
    // Notification timing intervals (in seconds)
    private let notificationIntervals: [(String, TimeInterval)] = [
        ("10 minutes", 10 * 60),
        ("5 minutes", 5 * 60),
        ("now", 0)
    ]
    
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
    
    // MARK: - Location-Based Notifications
    
    /// Check if user is within 100m of any bus stops and send proximity notifications
    func checkProximityNotifications<T: Identifiable>(
        userLocation: CLLocation,
        busStops: [T]
    ) where T.ID == UUID {
        guard isAuthorized else { return }
        
        for stop in busStops {
            // Use reflection to get the coordinate and name properties
            let mirror = Mirror(reflecting: stop)
            
            guard let coordinate = mirror.children.first(where: { $0.label == "coordinate" })?.value as? CLLocationCoordinate2D,
                  let name = mirror.children.first(where: { $0.label == "name" })?.value as? String else {
                continue
            }
            
            let stopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = userLocation.distance(from: stopLocation)
            
            // Check if user is within 100m range
            if distance <= 100 {
                let notificationId = "proximity-\(stop.id.uuidString)"
                
                // Avoid duplicate notifications
                guard !scheduledNotifications.contains(notificationId) else { continue }
                
                scheduleProximityNotification(
                    stopName: name,
                    distance: distance,
                    identifier: notificationId
                )
                
                scheduledNotifications.insert(notificationId)
            }
        }
    }
    
    /// Overloaded method with direct parameters for easier usage
    func checkProximityNotifications(
        userLocation: CLLocation,
        stopCoordinates: [BusStopCoordinate]
    ) {
        guard isAuthorized else { return }
        
        for stop in stopCoordinates {
            let stopLocation = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
            let distance = userLocation.distance(from: stopLocation)
            
            // Check if user is within 100m range
            if distance <= 100 {
                let notificationId = "proximity-\(stop.id.uuidString)"
                
                // Avoid duplicate notifications
                guard !scheduledNotifications.contains(notificationId) else { continue }
                
                scheduleProximityNotification(
                    stopName: stop.name,
                    distance: distance,
                    identifier: notificationId
                )
                
                scheduledNotifications.insert(notificationId)
            }
        }
    }
    
    /// Schedule notifications for bus arrivals based on estimated time
    func scheduleBusArrivalNotifications(
        busName: String,
        stopName: String,
        estimatedArrival: Date,
        busNumber: Int
    ) {
        guard isAuthorized else { return }
        
        let currentDate = Date()
        
        for (timeLabel, intervalBefore) in notificationIntervals {
            let notificationTime = estimatedArrival.addingTimeInterval(-intervalBefore)
            
            // Only schedule if the notification time is in the future
            guard notificationTime > currentDate else { continue }
            
            let identifier = "bus-arrival-\(busNumber)-\(timeLabel)-\(UUID().uuidString)"
            let timeInterval = notificationTime.timeIntervalSince(currentDate)
            
            let content = UNMutableNotificationContent()
            
            if timeLabel == "now" {
                content.title = "🚌 Bus Arriving!"
                content.body = "\(busName) is arriving at \(stopName) now!"
                content.sound = .default
            } else {
                content.title = "🕒 Bus Alert - \(timeLabel)"
                content.body = "\(busName) will arrive at \(stopName) in \(timeLabel)"
                content.sound = .default
            }
            
            content.badge = 1
            content.categoryIdentifier = "BUS_ARRIVAL"
            content.userInfo = [
                "busName": busName,
                "stopName": stopName,
                "busNumber": busNumber,
                "arrivalTime": estimatedArrival.timeIntervalSince1970
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule bus arrival notification: \(error)")
                } else {
                    print("Scheduled bus arrival notification for \(timeLabel): \(busName) at \(stopName)")
                }
            }
        }
    }
    
    /// Format distance using the same logic as SheetViewModel
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        return meters >= 1000
            ? String(format: "%.1f km Away From You", meters / 1000)
            : "\(Int(meters)) m Away From You"
    }
    
    /// Schedule proximity notification for nearby bus stops
    private func scheduleProximityNotification(stopName: String, distance: CLLocationDistance, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "📍 Nearby Bus Stop"
        content.body = "You're near \(stopName) - \(formatDistance(distance))"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "BUS_PROXIMITY"
        content.userInfo = [
            "stopName": stopName,
            "distance": distance
        ]
        
        // Send notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule proximity notification: \(error)")
            } else {
                print("Proximity notification scheduled for \(stopName)")
            }
        }
        
        // Clean up notification ID after some time to allow re-triggering
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { // 5 minutes
            self.scheduledNotifications.remove(identifier)
        }
    }
    
    /// Clean up expired notification identifiers
    func cleanupExpiredNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            Task { @MainActor in
                let currentTime = Date().timeIntervalSince1970
                
                for request in requests {
                    if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger,
                       let nextTriggerDate = trigger.nextTriggerDate(),
                       nextTriggerDate.timeIntervalSince1970 < currentTime {
                        
                        self.scheduledNotifications.remove(request.identifier)
                    }
                }
            }
        }
    }
}
