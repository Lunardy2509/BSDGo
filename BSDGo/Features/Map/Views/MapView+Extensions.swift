import SwiftUI
import MapKit
import SwiftData

// MARK: - MapView Layout Extensions
extension MapView {
    @ViewBuilder
    var iPadLayoutView: some View {
        HStack(spacing: 0) {
            // Sidebar for iPad
            if isSheetShown {
                VStack {
                    sheetContentView
                }
                .frame(width: 375)
                .background(Color(.systemBackground))
                .transition(.move(edge: .leading))
            }
            
            // Map view
            mapContainerView
        }
        .animation(.easeInOut(duration: 0.3), value: isSheetShown)
    }
    
    @ViewBuilder
    var iPhoneLayoutView: some View {
        ZStack {
            MapUIViewRepresentable(
                userLocation: $userLocation,
                userHeading: $userHeading,
                shouldRecenter: $shouldRecenter
            )
            .edgesIgnoringSafeArea(.all)

            mapView
                .onAppear(perform: setupInitialLocation)
                .onChange(of: locationManager.lastLocation) {
                    handleLocationChange()
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
    
    @ViewBuilder
    var mapContainerView: some View {
        ZStack {
            MapUIViewRepresentable(
                userLocation: $userLocation,
                userHeading: $userHeading,
                shouldRecenter: $shouldRecenter
            )
            .edgesIgnoringSafeArea(.all)

            mapView
                .onAppear(perform: setupInitialLocation)
                .onChange(of: locationManager.lastLocation) {
                    handleLocationChange()
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
        }
    }

    @ViewBuilder
    var mapView: some View {
        Map(position: $defaultPosition, bounds: mapBounds) {
            UserAnnotation()

            ForEach(busStopsManager.busStops) { stop in
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
            MapCompass()
            MapScaleView()
        }
    }
}

// MARK: - Sheet Content Extension
extension MapView {
    
    @ViewBuilder
    var sheetContentView: some View {
        switch selectedSheet {
        case .defaultView:
            DefaultSheetView(
                busStops: $busStopsManager.busStops,
                searchText: $searchText,
                selectionDetent: $presentationDetent,
                defaultPosition: $defaultPosition,
                selectedSheet: $selectedSheet,
                showDefaultSheet: $showDefaultSheet,
                showStopDetailSheet: $showStopDetailSheet,
                showRouteDetailSheet: $showRouteDetailSheet,
                selectedBusStop: $selectedBusStop,
                selectedBusNumber: $selectedBusNumber,
                onCancel: resetSheet
            )
            .environmentObject(locationManager)
            .if(!isIpad) { view in
                view
                    .presentationDetents(
                        [.fraction(0.10), .fraction(0.40), .medium, .fraction(0.99)],
                        selection: $presentationDetent
                    )
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
            }

        case .busStopDetailView:
            BusStopDetailView(
                currentBusStop: $selectedBusStop,
                showRouteDetailSheet: $showRouteDetailSheet,
                showStopDetailSheet: $showStopDetailSheet,
                selectedBusNumber: $selectedBusNumber,
                selectedBusName: $selectedBusName,
                selectedSheet: $selectedSheet
            )
            .if(!isIpad) { view in
                view
                    .presentationDetents([.fraction(0.35), .medium, .fraction(0.99)])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
            }

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
            .if(!isIpad) { view in
                view
                    .presentationDetents([.fraction(0.99)])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
            }
        }
    }
}

// MARK: - Helper Methods
extension MapView {
    func updateUserLocationIfNeeded(_ newLocation: CLLocation) {
        let distance = newLocation.distance(from: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude))
        if distance > 5 {
            userLocation = newLocation.coordinate
        }
    }
    
    func setupInitialLocation() {
        if let location = locationManager.lastLocation {
            userLocation = location.coordinate
        }
        userHeading = locationManager.userHeading
    }
    
    func handleLocationChange() {
        if let location = locationManager.lastLocation {
            userLocation = location.coordinate
            handleLocationUpdate()
        }
        userHeading = locationManager.userHeading
    }

    func handleStopSelection(_ stop: BusStop) {
        let result = viewModel.handleTapGesture(
            on: stop,
            currentSelection: selectedBusStop
        )

        selectedBusStop = stop
        selectedSheet = result.sheetType
        showDefaultSheet = result.showDefaultSheet
        presentationDetent = result.detent

        withAnimation(.easeInOut(duration: 0.5)) {
            defaultPosition = .region(result.region)
            showStopDetailSheet = result.showDetailSheet
        }
    }

    func handleLocationUpdate() {
        guard let location = locationManager.lastLocation else { return }
        viewModel.handleLocationUpdate(location: location, allStops: busStopsManager.busStops, locationManager: locationManager)
    }

    func resetSelection() {
        if selectedBusStop.id != UUID() {
            selectedBusStop = BusStop()
            selectedSheet = .defaultView
            showStopDetailSheet = false
            
            if isIpad {
                // On iPad, keep the sidebar open and show default view
                showDefaultSheet = true
            } else {
                // On iPhone, collapse the sheet to minimum
                presentationDetent = .fraction(0.10)
                showDefaultSheet = true
            }
        }
    }

    func resetSheet() {
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

// MARK: - Helper Extension
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
