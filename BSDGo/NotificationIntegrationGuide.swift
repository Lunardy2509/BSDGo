import Foundation
import CoreLocation

// MARK: - Supporting Types
struct BusStopCoordinate {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Integration Guide for Enhanced Notification System

/// Enhanced Notification System Integration
/// 
/// This guide shows how to use the enhanced NotificationManager with location-based notifications
/// and the Live Activity system for bus tracking.
/// 
/// **Key Features Added:**
/// 
/// 1. **Location-Based Notifications**: 
///    - Proximity notifications when user is within 100m of bus stops
///    - Uses the same formatDistance logic as SheetViewModel
/// 
/// 2. **Time-Based Bus Arrival Notifications**:
///    - 10 minutes before arrival
///    - 5 minutes before arrival  
///    - "Now" notification when bus arrives
/// 
/// 3. **Live Activity Integration**:
///    - Coordinated notifications with Live Activities
///    - Location-based progress updates
///    - Automatic cleanup when arrived
internal class NotificationIntegrationGuide {}

// MARK: - Usage Example 1: Basic Proximity Notifications
final class LocationBasedNotificationExample {
    
    func setupProximityMonitoring(userLocation: CLLocation, busStops: [BusStopCoordinate]) {
        
        // Enhanced NotificationManager automatically checks for 100m proximity
        NotificationManager.shared.checkProximityNotifications(
            userLocation: userLocation,
            stopCoordinates: busStops
        )
        
        // This will trigger notifications like:
        // "📍 Nearby Bus Stop"
        // "You're near Bundaran HI - 85 m Away From You"
    }
}

// MARK: - Usage Example 2: Bus Arrival Notifications
final class BusArrivalNotificationExample {
    
    func scheduleBusNotifications() {
        let estimatedArrival = Date().addingTimeInterval(12 * 60) // 12 minutes from now
        
        NotificationManager.shared.scheduleBusArrivalNotifications(
            busName: "TransJakarta 1A",
            stopName: "Bundaran HI", 
            estimatedArrival: estimatedArrival,
            busNumber: 1
        )
        
        // This will automatically schedule 3 notifications:
        // 1. "🕒 Bus Alert - 10 minutes" (in 2 minutes from now)
        // 2. "🕒 Bus Alert - 5 minutes" (in 7 minutes from now) 
        // 3. "🚌 Bus Arriving!" (in 12 minutes from now)
    }
}

// MARK: - Usage Example 3: Integration with Live Activity
final class LiveActivityIntegrationExample {
    
    func startIntegratedBusTracking(userLocation: CLLocation) {
        
        // 1. Start Live Activity with notifications
        let config = BusTrackingConfig(
            busName: "TransJakarta 1A",
            busNumber: 1,
            licensePlate: "B 1234 ABC", 
            destinationStop: "Bundaran HI",
            busColor: "#FF6B35",
            estimatedArrival: Date().addingTimeInterval(15 * 60),
            totalDuration: 15 * 60
        )
        
        // This will start both Live Activity AND schedule notifications
        LiveActivityManager.shared.startBusTracking(config: config)
        
        // 2. Update based on location
        let destinationCoordinate = CLLocationCoordinate2D(latitude: -6.1944, longitude: 106.8229)
        LiveActivityManager.shared.updateLocationBasedProgress(
            userLocation: userLocation,
            destinationCoordinate: destinationCoordinate
        )
        
        // 3. Check proximity notifications
        let busStops = [
            BusStopCoordinate(id: UUID(), name: "Monas", coordinate: CLLocationCoordinate2D(latitude: -6.1753, longitude: 106.8271)),
            BusStopCoordinate(id: UUID(), name: "Bundaran HI", coordinate: destinationCoordinate)
        ]
        
        LiveActivityManager.shared.checkProximityNotifications(
            userLocation: userLocation,
            busStops: busStops
        )
    }
}

// MARK: - Integration with Existing Map/Location Updates
final class MapViewIntegrationExample {
    
    /**
     Add this to your existing MapView location update handler:
     */
    
    func handleLocationUpdate(newLocation: CLLocation, allBusStops: [BusStop]) {
        
        // Convert BusStop to the format needed for notifications
        let stopCoordinates = allBusStops.map { stop in
            BusStopCoordinate(id: stop.id, name: stop.name, coordinate: stop.coordinate)
        }
        
        // Check proximity notifications
        NotificationManager.shared.checkProximityNotifications(
            userLocation: newLocation,
            stopCoordinates: stopCoordinates
        )
        
        // Update live activity if active
        if LiveActivityManager.shared.hasActiveActivity {
            // You would get the destination from the current activity
            let destinationCoordinate = CLLocationCoordinate2D(latitude: -6.1944, longitude: 106.8229) // Example
            
            LiveActivityManager.shared.updateLocationBasedProgress(
                userLocation: newLocation,
                destinationCoordinate: destinationCoordinate
            )
        }
    }
}

// MARK: - BusStop Protocol Extension for Compatibility
extension BusStop {
    
    /**
     Helper method to convert to notification-compatible format
     */
    func toNotificationFormat() -> BusStopCoordinate {
        return BusStopCoordinate(id: id, name: name, coordinate: coordinate)
    }
}

/// Widget Destination Issue Resolution and Testing Guide
/// 
/// The main issue with widget destination functionality was the App Group identifier mismatch:
/// - LocationManager was using "group.com.lunardy.SwiftRide" 
/// - Other components were using "group.com.lunardy.BSDGo"
/// 
/// **Fixed by:**
/// 1. Updated LocationManager to use "group.com.lunardy.BSDGo" consistently
/// 2. This ensures proper data sharing between main app and widget extension
/// 
/// ## Testing the Implementation
/// 
/// 1. **Test Widget Destination**: 
///    - Open the widget
///    - Check if it shows nearby bus stops with distances
///    - Verify distances update as you move
/// 
/// 2. **Test Proximity Notifications**:
///    - Walk within 100m of a bus stop
///    - Should receive "Nearby Bus Stop" notification
/// 
/// 3. **Test Bus Arrival Notifications**:
///    - Schedule a bus trip
///    - Should receive notifications at 10 min, 5 min, and arrival times
/// 
/// 4. **Test Live Activity Integration**:
///    - Start bus tracking
///    - Live Activity should show on lock screen and Dynamic Island
///    - Progress should update based on location
internal class TestingGuide {}

// MARK: - BusStop Model Definition (for reference)
struct BusStop: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    var distanceFromUser: CLLocationDistance?
    
    init() {
        self.id = UUID()
        self.name = ""
        self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0) 
        self.distanceFromUser = nil
    }
}
