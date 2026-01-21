//
//  BusCardViewModel.swift
//  BSDGo
//
//  Created by Ferdinand Lunardy on 21/01/2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class BusCardViewModel: ObservableObject {
    @Published var buses: [Bus] = []
    @Published var isLoading: Bool = false
    
    private var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // MARK: Fetch Data
    func fetchData() {
        self.isLoading = true
        let group = DispatchGroup()
        
        var fetchedBuses: [Bus] = []
        var fetchedSchedules: [BusSchedule] = []
        
        group.enter()
        FirestoreManager.shared.fetchBuses { result in
            if case .success(let buses) = result { fetchedBuses = buses }
            group.leave()
        }
        
        group.enter()
        FirestoreManager.shared.fetchSchedules { result in
            if case .success(let schedules) = result { fetchedSchedules = schedules }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.buses = fetchedBuses.map { bus in
                return bus.assignSchedule(schedules: fetchedSchedules)
            }
            self?.isLoading = false
        }
    }
    
    // MARK: Logic Helpers
    // Precomputed upcoming bus and ETA pairs
    func getUpcomingBuses(for stop: BusStop, currentTime: Date) -> [(bus: Bus, etaMinutes: Int)] {
        return buses.compactMap { bus in
            guard let nextSchedule = nextSchedule(for: bus, stopName: stop.name, now: currentTime),
                  let eta = bus.getClosestArrivalTime(from: nextSchedule.timeOfArrival) else {
                return nil
            }
            
            if eta <= 0 { return nil }
            return (bus, Int(eta / 60))
        }
        .sorted { $0.etaMinutes < $1.etaMinutes }
    }
    
    // Helper to get the next schedule for the current stop
    private func nextSchedule(for bus: Bus, stopName: String, now: Date) -> BusSchedule? {
        let calendar = Calendar.current
        
        let matchingSchedules = bus.schedule
            .filter { $0.busStopName == stopName }
            .compactMap { schedule -> (BusSchedule, Date)? in
                guard let timeOnly = formatter.date(from: schedule.timeOfArrival) else { return nil }
                
                // Merge "today" with the time from the schedule
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnly)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                
                guard let fullDate = calendar.date(from: components) else { return nil }
                
                return fullDate >= now ? (schedule, fullDate) : nil
            }
            .sorted { $0.1 < $1.1 }
        
        return matchingSchedules.first?.0
    }
}
