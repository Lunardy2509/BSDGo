import MapKit
import SwiftUI

struct DefaultSheetView: View {
    @Binding var busStops: [BusStop]
    @Binding var searchText: String
    @Binding var selectionDetent: PresentationDetent
    @Binding var defaultPosition: MapCameraPosition

    @Binding var selectedSheet: SheetType
    @Binding var showDefaultSheet: Bool
    @Binding var showStopDetailSheet: Bool
    @Binding var showRouteDetailSheet: Bool

    @Binding var selectedBusStop: BusStop
    @Binding var selectedBusNumber: Int

    @ObservedObject var locationManager = LocationManager()
    @StateObject var viewModel = SheetViewModel()

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
            viewModel.updateClosestStops(from: busStops, userLocation: locationManager.lastLocation)
            busStops = viewModel.updateDistances(for: busStops, from: locationManager.lastLocation)
        }
        .onChange(of: locationManager.lastLocation) {
            guard let newLocation = locationManager.lastLocation else { return }
            viewModel.updateClosestStops(from: busStops, userLocation: newLocation)
            busStops = viewModel.updateDistances(for: busStops, from: newLocation)
            locationManager.updateWidgetWithClosestStops()
        }

    }
}

private extension DefaultSheetView {
    func closestStopsSection() -> some View {
        Group {
            if searchText.isEmpty, !viewModel.closestStops.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Closest Bus Stops")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.closestStops.enumerated()), id: \.element.stop.id) { index, entry in
                            Button(action: {
                                handleBusStopSelection(entry.stop)
                            }) {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.primary)
                                        .font(.system(size: 30))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.stop.name)
                                            .font(.body)
                                        Text(viewModel.formatDistance(entry.distance))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain) 
                            if index < viewModel.closestStops.count - 1 {
                                Divider()
                                    .padding(.leading, 58)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(UIColor.separator).opacity(0.1), lineWidth: 0)
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 15)
            }
        }
    }

    func filteredStopsSection() -> some View {
        Group {
            var filteredStops: [BusStop] {
                searchText.isEmpty
                ? busStops
                : busStops.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            }

            if filteredStops.isEmpty {
                Text("No matching bus stops.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 10) {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredStops.enumerated()), id: \.element.id) { index, stop in
                            if stop.name.localizedCaseInsensitiveContains(searchText) || filteredStops.isEmpty {
                                VStack(spacing: 0) {
                                    SearchRow(stop: stop) {
                                        handleBusStopSelection(stop)
                                    }
                                }
                                if index < filteredStops.count - 1 {
                                    Divider()
                                        .padding(.leading, 46)
                                }
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 10)
            }
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

    struct SearchRow: View {
        let stop: BusStop
        let onTap: () -> Void

        var body: some View {
            Button(action: onTap) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))

                    VStack(alignment: .leading) {
                        Text(stop.name)
                            .font(.body)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }
}
