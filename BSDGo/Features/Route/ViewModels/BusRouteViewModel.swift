import SwiftUI
import Foundation

class BusRouteViewModel: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var selectedSessionIndex: Int = 0
    
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

    var sessionInfo: [(session: Int, stops: [BusSchedule], firstDate: Date, lastDate: Date)] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return Dictionary(grouping: busSchedule.filter { $0.busNumber == busNumber }, by: { $0.session })
            .compactMap { session, stops in
                let sorted = stops.sorted { $0.timeOfArrival < $1.timeOfArrival }
                let dates = sorted.compactMap { stop -> Date? in
                    guard let t = formatter.date(from: stop.timeOfArrival) else { return nil }
                    var comps = calendar.dateComponents([.year, .month, .day], from: now)
                    let timeComps = calendar.dateComponents([.hour, .minute], from: t)
                    comps.hour = timeComps.hour
                    comps.minute = timeComps.minute
                    return calendar.date(from: comps)
                }
                guard let first = dates.first, let last = dates.last, last >= now else {
                    return nil
                }
                return (session, sorted, first, last)
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

        guard let t = formatter.date(from: timeString) else { return .upcoming }
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        let tc = calendar.dateComponents([.hour, .minute], from: t)
        comps.hour = tc.hour
        comps.minute = tc.minute
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
            DispatchQueue.main.async {
                self?.animationProgress = progress
            }
            if progress >= 1.0 {
                self?.timer?.invalidate()
            }
        }
    }

    private func parseTime(_ time: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: time)
    }
}
