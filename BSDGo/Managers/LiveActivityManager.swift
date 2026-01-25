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
    
    // MARK: - Tracking State
    private var initialDistance: CLLocationDistance?
    private var averageTripSpeed: CLLocationSpeed?
    
    // MARK: - Throttling State
    private var lastUpdateTime: Date?
    private var lastPublishedStatus: BusTrackingModel.ContentState.BusStatus?
    private var lastPublishedProgress: Double = 0.0
    
    private var currentUpdateTask: Task<Void, Never>?
    
    private init() {
        checkLiveActivitySupport()
    }
    
    private func checkLiveActivitySupport() {
        isLiveActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    func startBusTracking(config: BusTrackingConfig) {
        initialDistance = nil
        averageTripSpeed = nil
        lastUpdateTime = nil
        lastPublishedStatus = nil
        lastPublishedProgress = 0.0
        
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
        
        currentUpdateTask?.cancel()
        
        currentUpdateTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            if Task.isCancelled { return }
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }
    
    func endBusTracking() {
        guard let activity = currentActivity else { return }
        
        currentActivity = nil
        
        let finalState = BusTrackingModel.ContentState(
            estimatedArrival: activity.content.state.estimatedArrival,
            currentProgress: 1.0,
            remainingTime: 0,
            busStatus: .arrived,
            isOnTheWay: false
        )
        
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
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
    
    // MARK: - Safe, Throttled Location Updates
    func updateLocationBasedProgress(userLocation: CLLocation, destinationCoordinate: CLLocationCoordinate2D) {
        guard let activity = currentActivity else { return }
        
        let destinationLocation = CLLocation(
            latitude: destinationCoordinate.latitude,
            longitude: destinationCoordinate.longitude
        )
        
        // 1. Calculate Distances
        let currentDistance = userLocation.distance(from: destinationLocation)
        
        // Initialize Baseline if needed
        if initialDistance == nil {
            initialDistance = currentDistance
            let scheduledDuration = activity.content.state.remainingTime
            if scheduledDuration > 0 {
                averageTripSpeed = currentDistance / scheduledDuration
            } else {
                averageTripSpeed = 10
            }
        }
        
        guard let startDist = initialDistance,
              let speed = averageTripSpeed,
              startDist > 0 else { return }
        
        // 2. Calculate New State
        let rawProgress = (startDist - currentDistance) / startDist
        let clampedProgress = min(max(rawProgress, 0.0), 1.0)
        let newRemainingTime = currentDistance / speed
        
        // Determine Status
        var newStatus: BusTrackingModel.ContentState.BusStatus = .onTheWay
        if currentDistance <= 50 {
            newStatus = .arrived
        } else if currentDistance <= 200 {
            newStatus = .approaching
        } else if currentDistance <= 500 {
            newStatus = .arriving
        }
        
        // 3. THROTTLING LOGIC (The Fix for the Crash)
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime ?? .distantPast)
        let progressChange = abs(clampedProgress - lastPublishedProgress)
        
        let isStatusChange = newStatus != lastPublishedStatus
        let isArrival = newStatus == .arrived
        let isSignificantChange = progressChange > 0.02 && timeSinceLastUpdate > 2.0
        let isHeartbeat = timeSinceLastUpdate > 15.0
        
        if lastUpdateTime == nil || isStatusChange || isArrival || isSignificantChange || isHeartbeat {
            
            // Update State
            lastUpdateTime = now
            lastPublishedStatus = newStatus
            lastPublishedProgress = clampedProgress
            
            print("🚀 Updating Live Activity: \(Int(clampedProgress * 100))% - \(newStatus.rawValue)")
            
            updateBusProgress(
                progress: clampedProgress,
                remainingTime: newRemainingTime,
                status: newStatus
            )
            
            // End immediately if arrived
            if isArrival {
                endBusTracking()
            }
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
