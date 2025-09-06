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
        let kilometers = meters / 1000
        return String(format: "%.1f km", kilometers)
    } else {
        return "\(Int(meters)) m"
    }
}
