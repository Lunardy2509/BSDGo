import Foundation
import SwiftUI

class BusStopsManager: ObservableObject {
    @Published var busStops: [BusStop] = []
    
    init() {
        loadData()
    }
    
    private func loadData() {
        self.busStops = loadBusStops()
    }
}
