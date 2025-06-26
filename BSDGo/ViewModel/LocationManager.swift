import Foundation
import WidgetKit
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    var statusString: String {
        guard let status = locationStatus else { return "Unknown" }
        
        switch status {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedWhenInUse: return "Authorized When In Use"
        case .authorizedAlways: return "Authorized Always"
        @unknown default:
            return "Unknown"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        print(#function, statusString)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        print(#function, location)
        
        // Automatically update the widget with new data
        updateWidgetWithClosestStops()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
    
    // MARK: - Handle WidgetModel
    func updateWidgetWithClosestStops() {
        // Load stops (ensure this file is in the app bundle)
        let stops = loadBusStops()
        
        guard let userLocation = lastLocation else { return }

        let widgetStops = convertToWidgetModel(from: stops, userLocation: userLocation)

        // Save to shared UserDefaults
        if let data = try? JSONEncoder().encode(widgetStops) {
            let sharedDefaults = UserDefaults(suiteName: "group.com.lunardy.SwiftRide")
            sharedDefaults?.set(data, forKey: "closestStops")

            // Trigger widget reload
            WidgetCenter.shared.reloadTimelines(ofKind: "FeatureWidget")
        }
    }
    
    func convertToWidgetModel(from stops: [BusStop], userLocation: CLLocation) -> [WidgetModel] {
        return stops
            .map { stop in
                let distance = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
                    .distance(from: userLocation)
                return (stop, distance)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(5)
            .map { (stop, distance) in
                WidgetModel(
                    name: stop.name,
                    distanceText: formatDistance(distance)
                )
            }
    }

}
