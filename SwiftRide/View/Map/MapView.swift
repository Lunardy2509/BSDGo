import SwiftUI
import SwiftData
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
            latitudinalMeters: 10 * 1000,
            longitudinalMeters: 10 * 1000
        ),
        minimumDistance: 1,
        maximumDistance: 50 * 1000
    )
    
    @StateObject private var locationManager = LocationManager()
    
    @State var searchText: String = ""
    @State var isSheetShown: Bool = true
    @State var isSelected: Bool = false
    @State var showDefaultSheet: Bool = true

    @State var showStopDetailSheet: Bool = false
    @State var showRouteDetailSheet: Bool = false
  
    @State var presentationDetent: PresentationDetent = .fraction(0.40)
    @State var selectedSheet: SheetContentType = .defaultView
    
    @State var busStops: [BusStop] = loadBusStops()
    @State var selectedBus: Bus = Bus()
    @State var selectedBusStop: BusStop = BusStop()
    @State var selectedBusName: String = ""
    @State var selectedBusNumber: Int = 0
    
    var body: some View {
        ZStack {
            Map(position: $defaultPosition, bounds: mapBounds) {
                UserAnnotation()
                ForEach(busStops) { stop in
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        StopAnnotation(isSelected: selectedBusStop.id == stop.id)
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture()
                                    .onEnded {
                                        if selectedBusStop.id == stop.id {
                                            selectedBusStop = BusStop()
                                            selectedSheet = .defaultView
                                            showStopDetailSheet = false
                                            presentationDetent = .fraction(0.1)
                                            showDefaultSheet = true
                                        } else {
                                            selectedBusStop = stop
                                            let newRegion = MKCoordinateRegion(
                                                center: stop.coordinate,
                                                latitudinalMeters: 1000,
                                                longitudinalMeters: 1000
                                            )
                                            defaultPosition = .region(newRegion)
                                            showDefaultSheet = false
                                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                                                selectedSheet = .busStopDetailView
                                                showStopDetailSheet = true
                                                presentationDetent = .medium
                                            }
                                        }
                                    }
                            )

                    }
                }
            }
            .onAppear {
                CLLocationManager().requestWhenInUseAuthorization()
                presentationDetent = .fraction(0.40)
            }
            .mapControls {
                MapUserLocationButton()
            }
            .toolbar(.hidden, for: .navigationBar)
            // Tap catcher for deselection
            .gesture(
                TapGesture()
                    .onEnded {
                        // Deselect if a stop is selected
                        if selectedBusStop.id != UUID() {
                            selectedBusStop = BusStop()
                            selectedSheet = .defaultView
                            showStopDetailSheet = false
                            presentationDetent = .fraction(0.1)
                            showDefaultSheet = true
                        }
                    }
            )
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
                        userLocation: locationManager.lastLocation,
                        onCancel: resetSheet
                    )
                    .presentationDetents([.fraction(0.10), .fraction(0.40), .medium, .fraction(0.99)], selection: $presentationDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
                    
                case .busStopDetailView:
                    BusStopDetailView(currentBusStop: $selectedBusStop, showRouteDetailSheet: $showRouteDetailSheet, showStopDetailSheet: $showStopDetailSheet,
                                      selectedBusNumber: $selectedBusNumber,
                                      selectedBusName: $selectedBusName,
                                      selectedSheet: $selectedSheet
                    )
                    .presentationDetents([.fraction(0.35), .medium, .fraction(0.99)])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                    
                case .routeDetailView:
                    BusRouteView(name: selectedBusName,
                                 busNumber: selectedBusNumber,
                                 currentStopName: UserDefaults.standard.string(forKey: "userStopName") ?? "",
                                 currentBusStop: $selectedBusStop,
                                 showRouteDetailSheet: $showRouteDetailSheet,
                                 selectedSheet: $selectedSheet)
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
