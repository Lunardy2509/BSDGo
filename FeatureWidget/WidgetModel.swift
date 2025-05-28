import Foundation
import CoreLocation

var userLocation: CLLocation?
var busStops: [BusStop] = []

struct WidgetModel: Codable, Hashable {
    let name: String
    let distanceText: String
}

func formatDistance(_ meters: CLLocationDistance) -> String {
    if meters >= 1000 {
        let km = meters / 1000
        return String(format: "%.1f km", km)
    } else {
        return "\(Int(meters)) m"
    }
}

