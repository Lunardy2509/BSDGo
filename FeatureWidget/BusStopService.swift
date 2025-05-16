import Foundation
import CoreLocation
import WidgetKit

struct BusStopService {
    let busStops: [BusStop]
    var userLocation: CLLocation?
    var updated: [BusStop]
    
    init(userLocation: CLLocation?) {
        self.busStops = loadBusStops()
        self.userLocation = userLocation
        
        if let location = userLocation {
            self.updated = BusStopService.updateDistances(busStops: self.busStops, from: location)
        } else {
            self.updated = self.busStops
        }
    }
    
    static func updateDistances(busStops: [BusStop], from userLocation: CLLocation) -> [BusStop] {
        return busStops.map { stop in
            var updated = stop
            let stopLoc = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
            updated.distanceFromUser = userLocation.distance(from: stopLoc)
            return updated
        }
    }

    static func closestStops(
        from busStops: [BusStop],
        maxCount: Int = 3
    ) -> [(stop: BusStop, distance: CLLocationDistance)] {
        let filtered: [(BusStop, CLLocationDistance)] = busStops.compactMap { stop in
            guard let distance = stop.distanceFromUser else { return nil }
            return (stop, distance)
        }

        return filtered
            .sorted(by: { $0.1 < $1.1 })
            .prefix(maxCount)
            .map { (stop, dist) in (stop: stop, distance: dist) }
    }


    static func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km away from You", meters / 1000)
        } else {
            return "\(Int(meters)) m away from You"
        }
    }

    static func saveClosestStopsToWidget(_ closestStops: [(stop: BusStop, distance: CLLocationDistance)], suiteName: String) {
        let topStops = closestStops.map { entry in
            WidgetBusStop(
                name: entry.stop.name,
                distanceText: formatDistance(entry.distance)
            )
        }

        if let data = try? JSONEncoder().encode(topStops) {
            let defaults = UserDefaults(suiteName: suiteName)
            defaults?.set(data, forKey: "closestStops")
            print("Widget stops saved: \(topStops.map { $0.name })")
        }
    }
} 
