import Foundation
import SwiftUI
import CoreLocation
import ActivityKit

// MARK: - Bus Tracking Configuration
struct BusTrackingConfig {
    let busName: String
    let busNumber: Int
    let licensePlate: String
    let destinationStop: String
    let busColor: String
    let estimatedArrival: Date
    let totalDuration: TimeInterval
}

@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<BusTrackingModel>?
    @Published var isLiveActivitySupported = false
    
    private let notificationManager = NotificationManager.shared
    
    private init() {
        checkLiveActivitySupport()
    }
    
    private func checkLiveActivitySupport() {
        isLiveActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    func startBusTracking(config: BusTrackingConfig) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = BusTrackingModel(
            busName: config.busName,
            busNumber: config.busNumber,
            licensePlate: config.licensePlate,
            destinationStop: config.destinationStop,
            busColor: config.busColor,
            startTime: Date()
        )
        
        let initialState = BusTrackingModel.ContentState(
            estimatedArrival: config.estimatedArrival,
            currentProgress: 0.0,
            remainingTime: config.totalDuration,
            busStatus: .onTheWay,
            isOnTheWay: true
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            // Schedule coordinated notifications
            notificationManager.scheduleBusArrivalNotifications(
                busName: config.busName,
                stopName: config.destinationStop,
                estimatedArrival: config.estimatedArrival,
                busNumber: config.busNumber
            )
            
            print("🚌 Live Activity and notifications started for Bus \(config.busNumber)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
        #endif
    }
    
    func updateBusProgress(
        progress: Double,
        remainingTime: TimeInterval,
        status: BusTrackingModel.ContentState.BusStatus = .onTheWay
    ) {
        guard let activity = currentActivity else { return }
        
        let updatedState = BusTrackingModel.ContentState(
            estimatedArrival: activity.content.state.estimatedArrival,
            currentProgress: min(max(progress, 0.0), 1.0), // Clamp between 0 and 1
            remainingTime: max(remainingTime, 0),
            busStatus: status,
            isOnTheWay: remainingTime > 0
        )
        
        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }
    
    func endBusTracking() {
        guard let activity = currentActivity else { return }
        
        let finalState = BusTrackingModel.ContentState(
            estimatedArrival: activity.content.state.estimatedArrival,
            currentProgress: 1.0,
            remainingTime: 0,
            busStatus: .arrived,
            isOnTheWay: false
        )
        
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            currentActivity = nil
            print("🏁 Live Activity ended")
        }
    }

    func endAllActivities() {
        Task {
            for activity in Activity<BusTrackingModel>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
            print("🛑 All Live Activities ended")
        }
    }
    
    var hasActiveActivity: Bool {
        return currentActivity != nil
    }
    
    // MARK: - Location-Based Integration
    
    /// Update live activity based on user location relative to destination
    func updateLocationBasedProgress(userLocation: CLLocation, destinationCoordinate: CLLocationCoordinate2D) {
        guard hasActiveActivity else { return }
        
        let destinationLocation = CLLocation(
            latitude: destinationCoordinate.latitude,
            longitude: destinationCoordinate.longitude
        )
        let distance = userLocation.distance(from: destinationLocation)
        
        // Calculate progress based on proximity (closer = higher progress)
        let maxDistance: CLLocationDistance = 2000 // 2km max distance for progress calculation
        let progress = max(0.0, min(1.0, (maxDistance - distance) / maxDistance))
        
        // Calculate remaining time based on distance (rough estimation)
        let estimatedSpeed: CLLocationDistance = 10 // 10 m/s average bus speed
        let remainingTime = max(0, distance / estimatedSpeed)
        
        updateBusProgress(progress: progress, remainingTime: remainingTime)
        
        // Check for arrival
        if distance <= 50 { // Within 50 meters = arrived
            endBusTracking()
        }
    }
    
    /// Check proximity to bus stops and trigger notifications
    func checkProximityNotifications(
        userLocation: CLLocation,
        busStops: [BusStopCoordinate]
    ) {
        notificationManager.checkProximityNotifications(
            userLocation: userLocation,
            stopCoordinates: busStops
        )
    }
    
    /// Clean up all tracking and notifications
    func cleanup() {
        endBusTracking()
        endAllActivities()
        notificationManager.cancelAllNotifications()
    }
}

// MARK: - Extension for easy bus data conversion
extension LiveActivityManager {
    func startTrackingFromBusRoute(
        bus: Bus,
        destinationStop: String,
        estimatedMinutes: Int
    ) {
        let estimatedArrival = Date().addingTimeInterval(TimeInterval(estimatedMinutes * 60))
        let totalDuration = TimeInterval(estimatedMinutes * 60)
        
        let config = BusTrackingConfig(
            busName: bus.name,
            busNumber: bus.number,
            licensePlate: bus.licensePlate,
            destinationStop: destinationStop,
            busColor: bus.color.toHexString(),
            estimatedArrival: estimatedArrival,
            totalDuration: totalDuration
        )
        
        startBusTracking(config: config)
    }
}

// MARK: - Color to Hex Extension
extension Color {
    func toHex() -> String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }
        
        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(red * 255),
                     lroundf(green * 255),
                     lroundf(blue * 255))
    }
}

// MARK: - AdaptiveColor Extension  
extension AdaptiveColor {
    func toHexString() -> String {
        return light.toHex() ?? "#FF6B35"
    }
}
