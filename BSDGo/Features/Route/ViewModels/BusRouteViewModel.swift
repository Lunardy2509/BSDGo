import SwiftUI
import Foundation
import UserNotifications

@MainActor
final class BusRouteViewModel: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published private var _selectedSessionIndex: Int = 0
    
    // Alert Timer Properties
    @Published var isAlertSet: Bool = false
    @Published var alertHours: Int = 0
    @Published var alertMinutes: Int = 5
    @Published var alertSeconds: Int = 0
    @Published var showAlertPicker: Bool = false
    @Published var remainingTime: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    
    // Live Activity Properties
    @Published var isLiveActivityEnabled: Bool = false
    @Published var liveActivityProgress: Double = 0.0
    
    private var alertTimer: Timer?
    private var liveActivityTimer: Timer?
    
    // Safe access to selectedSessionIndex with bounds checking
    var selectedSessionIndex: Int {
        get {
            return _selectedSessionIndex
        }
        set {
            // Ensure the new value is always within valid bounds
            let maxIndex = max(allSessions.count - 1, 0)
            _selectedSessionIndex = min(max(newValue, 0), maxIndex)
        }
    }
    
    // Method to safely update session index when switching between all/upcoming sessions
    func updateSessionIndexForArrayChange(newArrayCount: Int, showingAllSessions: Bool) {
        let maxValidIndex = max(newArrayCount - 1, 0)
        if _selectedSessionIndex >= newArrayCount {
                if newArrayCount == 0 {
                    _selectedSessionIndex = 0
                } else {
                    _selectedSessionIndex = min(max(mainSessionIndex, 0), maxValidIndex)
                }
            }
        }
    }
    
    @Published var animationProgress: CGFloat = 0.0
    private var timer: Timer?
    
    let name: String
    let busNumber: Int
    let currentStopName: String
    let busSchedule: [BusSchedule]
    let buses: [Bus]
    
    init(name: String, busNumber: Int, currentStopName: String) {
        self.name = name
        self.busNumber = busNumber
        self.currentStopName = currentStopName
        self.busSchedule = loadBusSchedules()
        self.buses = loadBuses()
    }
    
    struct SessionInfo {
        let session: Int
        let stops: [BusSchedule]
        let firstDate: Date
        let lastDate: Date
    }
    
    var sessionInfo: [SessionInfo] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        return Dictionary(grouping: busSchedule.filter { $0.busNumber == busNumber }, by: { $0.session })
            .compactMap { session, stops in
                let sorted = stops.sorted { $0.timeOfArrival < $1.timeOfArrival }
                let dates = sorted.compactMap { stop -> Date? in
                    guard let timer = formatter.date(from: stop.timeOfArrival) else { return nil }
                    var comps = calendar.dateComponents([.year, .month, .day], from: now)
                    let timeComps = calendar.dateComponents([.hour, .minute], from: timer)
                    comps.hour = timeComps.hour
                    comps.minute = timeComps.minute
                    return calendar.date(from: comps)
                }
                guard let first = dates.first, let last = dates.last, last >= now else {
                    return nil
                }
                return SessionInfo(session: session, stops: sorted, firstDate: first, lastDate: last)
            }
            .sorted { $0.firstDate < $1.firstDate }
    }
    
    var allSessions: [(session: Int, stops: [BusSchedule])] {
        Dictionary(grouping: busSchedule.filter { $0.busNumber == busNumber }, by: { $0.session })
            .map { (session, stops) in
                (session, stops.sorted { $0.timeOfArrival < $1.timeOfArrival })
            }
            .sorted { $0.0 < $1.0 }
    }
    
    var upcomingSessions: [(session: Int, stops: [BusSchedule])] {
        sessionInfo.map { ($0.session, $0.stops) }
    }
    
    var mainSessionIndex: Int {
        let now = Date()
        return sessionInfo.firstIndex(where: { now >= $0.firstDate && now <= $0.lastDate }) ?? 0
    }
    
    func stopStatus(for timeString: String) -> StopStatus {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let timer = formatter.date(from: timeString) else { return .upcoming }
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComps = calendar.dateComponents([.hour, .minute], from: timer)
        comps.hour = timeComps.hour
        comps.minute = timeComps.minute
        guard let stopDate = calendar.date(from: comps) else { return .upcoming }
        
        if calendar.isDate(stopDate, equalTo: now, toGranularity: .minute) {
            return .current
        } else if stopDate < now {
            return .passed
        } else {
            return .upcoming
        }
    }
    
    func startBusAnimation(from startTime: String, to endTime: String) {
        guard let start = parseTime(startTime),
              let end = parseTime(endTime) else { return }
        
        let totalDuration = end.timeIntervalSince(start)
        let startTimeStamp = Date()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            let elapsed = Date().timeIntervalSince(startTimeStamp)
            let progress = min(CGFloat(elapsed / totalDuration), 1.0)
            Task { @MainActor in
                guard let self = self else { return }
                self.animationProgress = progress
                if progress >= 1.0 {
                    self.timer?.invalidate()
                }
            }
        }
    }
    
    private func parseTime(_ time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: time)
    }
    
    // MARK: - Alert Timer Methods
    func startAlertTimer() {
        let totalSeconds = TimeInterval(alertHours * 3600 + alertMinutes * 60 + alertSeconds)
        guard totalSeconds > 0 else { return }
        
        remainingTime = totalSeconds
        isTimerRunning = true
        isAlertSet = true
        
        // Schedule push notification
        NotificationManager.shared.scheduleBusArrivalNotification(
            busName: name,
            stopName: currentStopName,
            timeInterval: totalSeconds
        )
        
        alertTimer?.invalidate()
        alertTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                } else {
                    self.stopAlertTimer()
                    self.triggerBusArrivalAlert()
                }
            }
        }
    }
    
    func stopAlertTimer() {
        alertTimer?.invalidate()
        alertTimer = nil
        isTimerRunning = false
        isAlertSet = false
        remainingTime = 0
        
        // Cancel pending notifications
        NotificationManager.shared.cancelNotifications(withIdentifierPrefix: "bus-arrival-")
    }
    
    private func triggerBusArrivalAlert() {
        // This will be called when the timer reaches zero
        // The push notification should already be triggered by the system
        print("🚌 Bus arrival alert triggered for \(name) at \(currentStopName)")
    }
    
    var formattedRemainingTime: String {
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    deinit {
        alertTimer?.invalidate()
        liveActivityTimer?.invalidate()
    }
    
    // MARK: - Live Activity Methods
    func startLiveActivity() {
        guard let currentBus = buses.first(where: { $0.number == busNumber }) else { return }
        
        let totalMinutes = alertHours * 60 + alertMinutes + (alertSeconds / 60)
        
        LiveActivityManager.shared.startTrackingFromBusRoute(
            bus: currentBus,
            destinationStop: currentStopName,
            estimatedMinutes: max(totalMinutes, 1) // At least 1 minute
        )
        
        isLiveActivityEnabled = true
        liveActivityProgress = 0.0
        
        // Start updating the Live Activity progress
        startLiveActivityProgressTimer(totalDuration: TimeInterval(totalMinutes * 60))
    }
    
    func stopLiveActivity() {
        LiveActivityManager.shared.endBusTracking()
        liveActivityTimer?.invalidate()
        liveActivityTimer = nil
        isLiveActivityEnabled = false
        liveActivityProgress = 0.0
    }
    
    private func startLiveActivityProgressTimer(totalDuration: TimeInterval) {
        let startTime = Date()
        
        liveActivityTimer?.invalidate()
        liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / totalDuration, 1.0)
                let remaining = max(totalDuration - elapsed, 0)
                
                self.liveActivityProgress = progress
                
                // Determine status based on progress
                let status: BusTrackingModel.ContentState.BusStatus = {
                    if progress >= 0.95 {
                        return .arriving
                    } else if progress >= 0.8 {
                        return .approaching
                    } else {
                        return .onTheWay
                    }
                }()
                
                LiveActivityManager.shared.updateBusProgress(
                    progress: progress,
                    remainingTime: remaining,
                    status: status
                )
                
                // End when complete
                if progress >= 1.0 {
                    self.stopLiveActivity()
                }
            }
        }
    }
}
