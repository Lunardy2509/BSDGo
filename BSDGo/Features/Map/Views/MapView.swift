import SwiftUI
import UIKit
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
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
    
    
    @ObservedObject var locationManager = LocationManager()
    @StateObject var viewModel = MapViewModel()
    
    @State private var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -6.3027, longitude: 106.6520)
    @State private var userHeading: CLLocationDirection = 0.0

    @State private var searchText: String = ""
    @State private var isSheetShown: Bool = true
    @State private var showDefaultSheet: Bool = true
    @State private var showStopDetailSheet: Bool = false
    @State private var showRouteDetailSheet: Bool = false
    
    @State private var presentationDetent: PresentationDetent = .fraction(0.40)
    @State private var selectedSheet: SheetType = .defaultView
    
    @State private var busStops: [BusStop] = loadBusStops()
    @State private var selectedBusStop: BusStop = BusStop()
    @State private var selectedBus: Bus = Bus()
    @State private var selectedBusName: String = ""
    @State private var selectedBusNumber: Int = 0
    
    var body: some View {
        ZStack {
            MapUIViewRepresentable(
                userLocation: $userLocation,
                userHeading: .constant(0.0)
            )
            .edgesIgnoringSafeArea(.all)
            
            mapView
                .onAppear {
                    if let location = locationManager.lastLocation {
                        userLocation = location.coordinate
                    }
                    userHeading = locationManager.userHeading
                }
            
                .onChange(of: locationManager.lastLocation) {
                    if let location = locationManager.lastLocation {
                        userLocation = location.coordinate
                        handleLocationUpdate()
                    }
                    userHeading = locationManager.userHeading
                }
            
                .onChange(of: locationManager.userHeading) {
                    userHeading = locationManager.userHeading
                }
            
                .highPriorityGesture(
                    TapGesture().onEnded {
                        resetSelection()
                    }
                )
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $isSheetShown, onDismiss: resetSheet) {
                    sheetContentView
                }
        }
    }
    
    private var mapView: some View {
        Map(position: $defaultPosition, bounds: mapBounds) {
            UserAnnotation()
            
            ForEach(busStops) { stop in
                Annotation(stop.name, coordinate: stop.coordinate) {
                    StopAnnotation(isSelected: selectedBusStop.id == stop.id)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            TapGesture().onEnded {
                                handleStopSelection(stop)
                            }
                        )
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
        }
    }
    
    @ViewBuilder
    private var sheetContentView: some View {
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
                viewModel: BusRouteViewModel(
                    name: selectedBusName,
                    busNumber: selectedBusNumber,
                    currentStopName: UserDefaults.standard.string(forKey: "userStopName") ?? ""
                ),
                currentBusStop: $selectedBusStop,
                showRouteDetailSheet: $showRouteDetailSheet,
                selectedSheet: $selectedSheet
            )
            .presentationDetents([.fraction(0.99)])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
        }
    }
    
    private func updateUserLocationIfNeeded(_ newLocation: CLLocation) {
        let distance = newLocation.distance(from: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude))
        if distance > 5 { // only update if moved more than 5 meters
            userLocation = newLocation.coordinate
        }
    }
    
    private func handleStopSelection(_ stop: BusStop) {
        let (newRegion, showDetailSheet, newDefaultSheet, newSheet, newDetent) = viewModel.handleTapGesture(
            on: stop,
            currentSelection: selectedBusStop
        )

        // Update selection state
        selectedBusStop = stop
        selectedSheet = newSheet
        showDefaultSheet = newDefaultSheet
        presentationDetent = newDetent

        // Animate map to center on the tapped annotation
        withAnimation(.easeInOut(duration: 0.5)) {
            defaultPosition = .region(newRegion)
            showStopDetailSheet = showDetailSheet
        }
    }
    
    private func handleLocationUpdate() {
        guard let location = locationManager.lastLocation else { return }
        viewModel.handleLocationUpdate(location: location, allStops: busStops, locationManager: locationManager)
    }
    
    private func resetSelection() {
        if selectedBusStop.id != UUID() {
            selectedBusStop = BusStop()
            selectedSheet = .defaultView
            showStopDetailSheet = false
            presentationDetent = .fraction(0.10)
            showDefaultSheet = true
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
