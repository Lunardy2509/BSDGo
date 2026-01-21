import Foundation
import SwiftUI

@MainActor
final class BusStopsManager: ObservableObject {
    @Published var busStops: [BusStop] = []
    
    init() {
        FirestoreManager.shared.fetchStops { [weak self] result in
            Task { @MainActor in
                if case .success(let stops) = result {
                    self?.busStops = stops
                }
            }
        }
    }
//    init() {
//        Task {
//            await loadData()
//        }
//    }
//    
//    private func loadData() async {
//        let stops = await Task.detached(priority: .userInitiated) {
//            return loadBusStops()
//        }.value
//        
//        await MainActor.run {
//            self.busStops = stops
//        }
//    }
}
