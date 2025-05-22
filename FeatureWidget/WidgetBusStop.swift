import Foundation

struct WidgetBusStop: Codable, Hashable {
    let name: String
    let distanceText: String
}

//var closestStops: [(stop: BusStop, distance: CLLocationDistance)] {
//    guard let userLocation = userLocation else { return [] }
//
//    return busStops
//        .map { ($0, CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: userLocation)) }
//        .sorted { $0.1 < $1.1 }
//        .prefix(5)
//        .map { ($0.0, $0.1) }
//}
//
//func updateDistances(from userLocation: CLLocation) {
//    busStops = busStops.map { stop in
//        var updated = stops
//        let stopLoc = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
//        updated.distanceFromUser = userLocation.distance(from: stopLoc)
//        return updated
//    }
//}
//
//func formatDistance(_ meters: CLLocationDistance) -> String {
//    if meters >= 1000 {
//        let km = meters / 1000
//        return String(format: "%.1f km away from You", km)
//    } else {
//        return "\(Int(meters)) m away from You"
//    }
//}
