import Foundation
import CoreLocation
import MapKit

@MainActor
class SheetViewModel: ObservableObject {
    @Published var closestStops: [(stop: BusStop, distance: CLLocationDistance)] = []

    func updateClosestStops(from stops: [BusStop], userLocation: CLLocation?) {
        guard let location = userLocation else {
            closestStops = []
            return
        }

        let calculated = stops
            .map { stop in
                let distance = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
                    .distance(from: location)
                return (stop, distance)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(5)

        closestStops = Array(calculated)
    }

    func updateDistances(for stops: [BusStop], from userLocation: CLLocation?) -> [BusStop] {
        guard let location = userLocation else { return stops }

        return stops.map { stop in
            var updated = stop
            let stopLoc = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
            updated.distanceFromUser = location.distance(from: stopLoc)
            return updated
        }
    }

    func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 {
            let km = meters / 1000
            return String(format: "%.1f km Away From You", km)
        } else {
            return "\(Int(meters)) m Away From You"
        }
    }
} 
