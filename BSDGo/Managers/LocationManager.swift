import Foundation
import WidgetKit
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    @Published var userHeading: CLLocationDirection = 0.0
    @Published var debouncedHeading: CLLocationDirection = 0.0
    
    private var cachedBusStops: [BusStop] = []
    private var lastWidgetUpdateLocation: CLLocation?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
//        Task.detached {
//            let stops = loadBusStops()
//            await MainActor.run {
//                self.cachedBusStops = stops
//            }
//        }
        
        $userHeading
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] heading in
                self?.debouncedHeading = heading
            }
            .store(in: &cancellables)
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
    
    // MARK: - Load Bus Stops
    func loadBusStops() {
        // Only fetch if we haven't already
        guard cachedBusStops.isEmpty else { return }
        
        FirestoreManager.shared.fetchStops { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let stops):
                    self?.cachedBusStops = stops
                    if self?.lastLocation != nil {
                        self?.updateWidgetWithClosestStops()
                    }
                case .failure(let error):
                    print("LocationManager failed to load stops: \(error)")
                }
            }
        }
    }
    
    // MARK: - Handle WidgetModel
    func updateWidgetWithClosestStops() {
        guard let currentLoc = lastLocation else { return }
        
        if let lastLoc = lastWidgetUpdateLocation {
            let distanceMoved = currentLoc.distance(from: lastLoc)
            // If we haven't moved 50m, stop here. Save resources.
            if distanceMoved < 50 { return }
        }
        
        let stops = self.cachedBusStops
        if stops.isEmpty { return }
        
        self.lastWidgetUpdateLocation = currentLoc
        
        Task { [weak self] in
            guard let self = self else { return }
            
            let widgetStops = self.convertToWidgetModel(from: stops, userLocation: currentLoc)
            
            // Save to shared UserDefaults
            if let data = try? JSONEncoder().encode(widgetStops) {
                let sharedDefaults = UserDefaults(suiteName: "group.com.lunardy.BSDGo")
                sharedDefaults?.set(data, forKey: "closestStops")
                
                // Trigger widget reload
                WidgetCenter.shared.reloadTimelines(ofKind: "FeatureWidget")
            }
        }
    }
    
    nonisolated func convertToWidgetModel(from stops: [BusStop], userLocation: CLLocation) -> [WidgetModel] {
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

// MARK: - Delegate Extension
extension LocationManager {
    
    // nonisolated: Let the system call this from any thread without crashing
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.locationStatus = status
            print("Auth status changed:", status)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.lastLocation = location
            self.updateWidgetWithClosestStops()
            print("Location updated:", location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        
        Task { @MainActor in
            self.userHeading = heading
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
}
