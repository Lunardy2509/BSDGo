import MapKit
import SwiftUI

struct DefaultSheetView: View {
    @Binding var busStops: [BusStop]
    @Binding var searchText: String
    @Binding var selectionDetent: PresentationDetent
    @Binding var defaultPosition: MapCameraPosition

    @Binding var selectedSheet: SheetContentType
    @Binding var showDefaultSheet: Bool
    @Binding var showStopDetailSheet: Bool
    @Binding var showRouteDetailSheet: Bool

    @Binding var selectedBusStop: BusStop
    @Binding var selectedBusNumber: Int

    @ObservedObject var locationManager = LocationManager()

    var userLocation: CLLocation?
    var onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SearchBar(
                    searchText: $searchText,
                    busStops: $busStops,
                    onCancel: onCancel
                )
                closestStopsSection()
                filteredStopsSection()
            }
        }
        .onAppear {
            if let userLocation = locationManager.lastLocation {
                updateDistances(from: userLocation)
            }
        }
        .onChange(of: locationManager.lastLocation) {
            if let location = locationManager.lastLocation {
                updateDistances(from: location)
            }
        }
    }
}

private extension DefaultSheetView {
    @ViewBuilder
    func closestStopsSection() -> some View {
        if searchText.isEmpty, !closestStops.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Closest Bus Stops")
                    .font(.title2.bold())
                    .padding(.horizontal)
                VStack(spacing: 0) {
                    ForEach(closestStops, id: \.stop.id) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.primary)
                                .font(.system(size: 30))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.stop.name)
                                    .font(.body)
                                Text(formatDistance(entry.distance))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        if entry.stop.id != closestStops.last?.stop.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
            }
            .padding(.top, 15)
        }
    }


    @ViewBuilder
    func filteredStopsSection() -> some View {
        if filteredStops.isEmpty {
            Text("No matching bus stops.")
                .foregroundColor(.secondary)
                .padding()
        } else {
            VStack(spacing: 10) {
                ForEach(filteredStops, id: \.id) { stop in
                    if stop.name.localizedCaseInsensitiveContains(searchText) || filteredStops.isEmpty {
                        BusStopRow(stop: stop) {
                            handleBusStopSelection(stop)
                        }
                    }
                }
            }
            .padding(.top, 10)
        }
    }
    
    var filteredStops: [BusStop] {
        searchText.isEmpty
            ? busStops
            : busStops.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var closestStops: [(stop: BusStop, distance: CLLocationDistance)] {
        guard let userLocation = userLocation else { return [] }

        return busStops
            .map { ($0, CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: userLocation)) }
            .sorted { $0.1 < $1.1 }
            .prefix(5)
            .map { ($0.0, $0.1) }
    }

    func updateDistances(from userLocation: CLLocation) {
        busStops = busStops.map { stop in
            var updated = stop
            let stopLoc = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
            updated.distanceFromUser = userLocation.distance(from: stopLoc)
            return updated
        }
    }

    func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 {
            let km = meters / 1000
            return String(format: "%.1f km away from You", km)
        } else {
            return "\(Int(meters)) m away from You"
        }
    }

    func handleBusStopSelection(_ stop: BusStop) {
        selectedBusStop = stop
        defaultPosition = .region(
            MKCoordinateRegion(
                center: stop.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
        )
        showDefaultSheet = false
        withAnimation(.easeInOut(duration: 0.7)) {
            selectedSheet = .busStopDetailView
            showStopDetailSheet = true
            selectionDetent = .medium
        }
    }

    struct BusStopRow: View {
        let stop: BusStop
        let onTap: () -> Void

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))

                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))

                    VStack(alignment: .leading) {
                        Text(stop.name)
                            .font(.body)
                    }

                    Spacer()
                }
                .padding(5)
            }
            .padding(.horizontal)
            .onTapGesture(perform: onTap)
        }
    }
}
