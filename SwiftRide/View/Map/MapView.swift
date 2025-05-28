import SwiftUI
import MapKit

enum SheetContentType {
    case defaultView
    case busStopDetailView
    case routeDetailView
}

struct MapView: View {
    @State private var defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.302793115915458, longitude: 106.65204508592274),
        latitudinalMeters: 1000,
        longitudinalMeters: 1000
    )
    
    @State private var defaultPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -6.302793115915458, longitude: 106.65204508592274),
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
    )
    
    @State private var mapBounds = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -6.302793115915458, longitude: 106.65204508592274),
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        ),
        minimumDistance: 1,
        maximumDistance: 50000
    )
    
    @StateObject var locationManager = LocationManager()
    @StateObject var viewModel = MapViewModel()
    
    var userLocation: CLLocation? {
        locationManager.lastLocation
    }
    
    @State private var searchText: String = ""
    @State private var isSheetShown: Bool = true
    @State private var showDefaultSheet: Bool = true
    @State private var showStopDetailSheet: Bool = false
    @State private var showRouteDetailSheet: Bool = false
    @State private var isSelected: Bool = false
    
    @State private var presentationDetent: PresentationDetent = .fraction(0.40)
    @State private var selectedSheet: SheetContentType = .defaultView
    
    @State private var busStops: [BusStop] = loadBusStops()
    @State private var selectedBusStop: BusStop = BusStop()
    @State private var selectedBus: Bus = Bus()
    @State private var selectedBusName: String = ""
    @State private var selectedBusNumber: Int = 0
    
    var body: some View {
        ZStack {
            Map(position: $defaultPosition, bounds: mapBounds) {
                UserAnnotation()
                
                ForEach(busStops) { stop in
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        StopAnnotation(isSelected: selectedBusStop.id == stop.id)
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture().onEnded {
                                    let (newStop, newSheet, newDefaultSheet, newDetent) = viewModel.handleAnnotationTap(
                                        on: stop,
                                        currentSelection: selectedBusStop
                                    )
                                    selectedBusStop = newStop
                                    selectedSheet = newSheet
                                    showDefaultSheet = newDefaultSheet
                                    presentationDetent = newDetent
                                    
                                    if newSheet == .busStopDetailView {
                                        let newRegion = MKCoordinateRegion(
                                            center: stop.coordinate,
                                            latitudinalMeters: 1000,
                                            longitudinalMeters: 1000
                                        )
                                        defaultPosition = .region(newRegion)
                                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                                            showStopDetailSheet = true
                                        }
                                    } else {
                                        showStopDetailSheet = false
                                    }
                                }
                            )
                    }
                }
            }
            .onAppear {
                presentationDetent = .fraction(0.40)
            }
            .mapControls {
                MapUserLocationButton()
            }
            .onChange(of: locationManager.lastLocation) {
                guard let location = locationManager.lastLocation else { return }
                viewModel.handleLocationUpdate(location: location, allStops: busStops, locationManager: locationManager)
            }
            .gesture(
                TapGesture().onEnded {
                    if selectedBusStop.id != UUID() {
                        selectedBusStop = BusStop()
                        selectedSheet = .defaultView
                        showStopDetailSheet = false
                        presentationDetent = .fraction(0.1)
                        showDefaultSheet = true
                    }
                }
            )
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isSheetShown, onDismiss: resetSheet) {
                switch selectedSheet {
                case .defaultView:
                    DefaultSheetView(
                        busStops: $busStops,
                        searchText: $searchText,
                        selectionDetent: $presentationDetent,
                        defaultPosition: $defaultPosition,
                        selectedSheet: $selectedSheet,
                        showDefaultSheet: $showDefaultSheet,
                        showStopDetailSheet: $showStopDetailSheet,
                        showRouteDetailSheet: $showRouteDetailSheet,
                        selectedBusStop: $selectedBusStop,
                        selectedBusNumber: $selectedBusNumber,
                        locationManager: locationManager,
                        onCancel: resetSheet
                    )
                    .presentationDetents(
                        [.fraction(0.10), .fraction(0.40), .medium, .fraction(0.99)],
                        selection: $presentationDetent
                    )
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
                    
                case .busStopDetailView:
                    BusStopDetailView(
                        currentBusStop: $selectedBusStop,
                        showRouteDetailSheet: $showRouteDetailSheet,
                        showStopDetailSheet: $showStopDetailSheet,
                        selectedBusNumber: $selectedBusNumber,
                        selectedBusName: $selectedBusName,
                        selectedSheet: $selectedSheet
                    )
                    .presentationDetents([.fraction(0.35), .medium, .fraction(0.99)])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                    
                case .routeDetailView:
                    BusRouteView(
                        name: selectedBusName,
                        busNumber: selectedBusNumber,
                        currentStopName: UserDefaults.standard.string(forKey: "userStopName") ?? "",
                        currentBusStop: $selectedBusStop,
                        showRouteDetailSheet: $showRouteDetailSheet,
                        selectedSheet: $selectedSheet
                    )
                    .presentationDetents([.fraction(0.99)])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                }
            }
        }
    }
    private func resetSheet() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSheetShown = true
            showDefaultSheet = true
            showStopDetailSheet = false
            showRouteDetailSheet = false
            presentationDetent = .fraction(0.40)
            selectedSheet = .defaultView
        }
    }
}

#Preview {
    MapView()
}
