import Foundation
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

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
    
    @Published var currentActivity: Activity<BusTrackingAttributes>?
    @Published var isLiveActivitySupported = false
    
    private init() {
        checkLiveActivitySupport()
    }
    
    private func checkLiveActivitySupport() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            isLiveActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
        }
        #endif
    }
    
    func startBusTracking(config: BusTrackingConfig) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = BusTrackingAttributes(
            busName: config.busName,
            busNumber: config.busNumber,
            licensePlate: config.licensePlate,
            destinationStop: config.destinationStop,
            busColor: config.busColor,
            startTime: Date()
        )
        
        let initialState = BusTrackingAttributes.ContentState(
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
            print("🚌 Live Activity started for Bus \(config.busNumber)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
        #endif
    }
    
    func updateBusProgress(
        progress: Double,
        remainingTime: TimeInterval,
        status: BusTrackingAttributes.ContentState.BusStatus = .onTheWay
    ) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard let activity = currentActivity else { return }
        
        let updatedState = BusTrackingAttributes.ContentState(
            estimatedArrival: activity.content.state.estimatedArrival,
            currentProgress: min(max(progress, 0.0), 1.0), // Clamp between 0 and 1
            remainingTime: max(remainingTime, 0),
            busStatus: status,
            isOnTheWay: remainingTime > 0
        )
        
        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
        #endif
    }
    
    func endBusTracking() {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard let activity = currentActivity else { return }
        
        let finalState = BusTrackingAttributes.ContentState(
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
        #endif
    }
    
    func endAllActivities() {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        
        Task {
            for activity in Activity<BusTrackingAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
            print("🛑 All Live Activities ended")
        }
        #endif
    }
    
    var hasActiveActivity: Bool {
        return currentActivity != nil
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
