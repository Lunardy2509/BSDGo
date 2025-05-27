import Foundation
import CoreLocation

var userLocation: CLLocation?
var busStops: [BusStop] = []

struct WidgetBusStop: Codable, Hashable {
    let name: String
    let distanceText: String
}

var closestStops: [(stop: BusStop, distance: CLLocationDistance)] {
    guard let userLocation = userLocation else {
        print("❌ userLocation is nil")
        return []
    }

    print("📍 Calculating closest stops from location: \(userLocation.coordinate)")

    let results = busStops
        .map { stop in
            let distance = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude).distance(from: userLocation)
            print("➡️ Stop: \(stop.name), Distance: \(distance)")
            return (stop, distance)
        }
        .sorted { $0.1 < $1.1 }
        .prefix(5)
        .map { ($0.0, $0.1) }

    print("✅ Top \(results.count) closest stops calculated")
    return results
}


func updateDistances(from userLocation: CLLocation) {
    busStops = busStops.map { stop in
        var updated = stop
        let stopLoc = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
        updated.distanceFromUser = userLocation.distance(from: stopLoc)
        return updated
    }
}

func formatDistance(_ meters: CLLocationDistance) -> String {
    if meters >= 1000 {
        let km = meters / 1000
        return String(format: "%.1f km away from You", km)
    } else {
        return "\(Int(meters)) m away from You"
    }
}


func convertToWidgetBusStops(from stops: [BusStop], userLocation: CLLocation?) -> [WidgetBusStop] {
    guard let userLocation = userLocation else {
        print("❌ userLocation is nil")
        return []
    }

    return stops
        .map { stop in
            let distance = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
                .distance(from: userLocation)
            print("📍 Calculated distance for \(stop.name): \(distance)")

            return (stop, distance)
        }
        .sorted { $0.1 < $1.1 }
        .prefix(5)
        .map { (stop, distance) in
            WidgetBusStop(
                name: stop.name,
                distanceText: formatDistance(distance)
            )
        }
}

