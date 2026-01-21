//
//  BusViewModel.swift
//  BSDGo
//
//  Created by Ferdinand Lunardy on 20/01/2026.
//

import Foundation
import Combine

final class BusViewModel: ObservableObject {
    
    @Published var buses: [Bus] = []
    @Published var stops: [BusStop] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchAllData() {
            self.isLoading = true
            self.errorMessage = nil
            
            var tempBuses: [Bus] = []
            var tempSchedules: [BusSchedule] = []
            var tempStops: [BusStop] = []
            
            let group = DispatchGroup()
            
            group.enter()
            FirestoreManager.shared.fetchBuses { result in
                switch result {
                case .success(let fetchedBuses):
                    tempBuses = fetchedBuses
                case .failure(let error):
                    print("Error fetching buses: \(error)")
                    self.errorMessage = error.localizedDescription
                }
                group.leave()
            }
            
            group.enter()
            FirestoreManager.shared.fetchSchedules { result in
                switch result {
                case .success(let fetchedSchedules):
                    tempSchedules = fetchedSchedules
                case .failure(let error):
                    print("Error fetching schedules: \(error)")
                }
                group.leave()
            }
            
            group.enter()
            FirestoreManager.shared.fetchStops { result in
                switch result {
                case .success(let fetchedStops):
                    tempStops = fetchedStops
                case .failure(let error):
                    print("Error fetching stops: \(error)")
                }
                group.leave()
            }
            
            group.notify(queue: .main) {
                self.buses = tempBuses.map { bus in
                    return bus.assignSchedule(schedules: tempSchedules)
                }
                
                self.stops = tempStops
                self.isLoading = false
            }
        }
}
