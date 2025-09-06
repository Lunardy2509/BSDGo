import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.302793115915458, longitude: 106.65204508592274),
        latitudinalMeters: 1000,
        longitudinalMeters: 1000
    )

    @State var defaultPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -6.302793115915458, longitude: 106.65204508592274),
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
    )

    @State var mapBounds = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -6.302793115915458, longitude: 106.65204508592274),
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        ),
        minimumDistance: 1,
        maximumDistance: 50000
    )

    @EnvironmentObject var locationManager: LocationManager
    @StateObject var viewModel = MapViewModel()
    @StateObject var busStopsManager = BusStopsManager()
    
    var isIpad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }

    @State var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -6.3027, longitude: 106.6520)
    @State var userHeading: CLLocationDirection = 0.0
    
    @State var searchText: String = ""
    @State var isSheetShown: Bool = true
    @State var showDefaultSheet: Bool = true
    @State var showStopDetailSheet: Bool = false
    @State var showRouteDetailSheet: Bool = false
    @State var shouldRecenter = false

    @State var presentationDetent: PresentationDetent = .fraction(0.40)
    @State var selectedSheet: SheetType = .defaultView

    @State var selectedBusStop: BusStop = BusStop()
    @State var selectedBus: Bus = Bus()
    @State var selectedBusName: String = ""
    @State var selectedBusNumber: Int = 0

    @Query(sort: \RecentBusStop.timestamp, order: .reverse) var recentSearches: [RecentBusStop]

    var body: some View {
        if isIpad {
            iPadLayoutView
        } else {
            iPhoneLayoutView
        }
    }
}
