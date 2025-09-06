import MapKit
import SwiftUI
import SwiftData

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
    
    @EnvironmentObject var locationManager: LocationManager
    @StateObject var viewModel = SheetViewModel()
    
    @Environment(\.modelContext) private var context
    
    var onCancel: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SearchBar(
                    searchText: $searchText,
                    busStops: $busStops,
                    onCancel: onCancel
                )
                defaultSection
                filteredStopsSection
            }
        }
        .onAppear {
            viewModel.refreshStops(from: busStops, userLocation: locationManager.lastLocation)
            busStops = viewModel.updateDistances(for: busStops, from: locationManager.lastLocation)
            viewModel.fetchRecentSearches(context)
        }
        .onChange(of: locationManager.lastLocation) {
            guard let newLocation = locationManager.lastLocation else { return }
            viewModel.refreshStops(from: busStops, userLocation: newLocation)
            busStops = viewModel.updateDistances(for: busStops, from: newLocation)
            locationManager.updateWidgetWithClosestStops()
        }
    }
    
    private var defaultSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                if searchText.isEmpty, !viewModel.closestStops.isEmpty {
                    viewModel.closestStopsList { handleBusStopSelection($0) }
                } else {
                    Text("Closest Bus Stops")
                        .font(.title2.bold())
                        .padding(.horizontal)
                }
            }
            .padding(.top, 15)
            
            VStack(alignment: .leading, spacing: 8) {
                if searchText.isEmpty && !viewModel.recentSearches.isEmpty {
                    viewModel.recentSearchList(recentSearches: viewModel.recentSearches) { handleBusStopSelection($0)
                    }
                } else {
                    Text("Bus Stops List")
                        .font(.title2.bold())
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 15)
        }
    }
    
    private var filteredStopsSection: some View {
        let filtered = viewModel.filteredStops(from: busStops, searchText: searchText)
        
        return Group {
            if filtered.isEmpty {
                Text("No results.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 10) {
                    viewModel.filteredStopsList(filtered: filtered) { handleBusStopSelection($0) }
                }
                .padding(.top, 10)
            }
        }
    }
    
    private func handleBusStopSelection(_ stop: BusStop) {
        selectedBusStop = stop

        Task {
            let recent = RecentBusStop(
                id: stop.id,
                name: stop.name,
                latitude: stop.coordinate.latitude,
                longitude: stop.coordinate.longitude,
                timestamp: Date()
            )

            context.insert(recent)

            do {
                try context.save()
                viewModel.fetchRecentSearches(context)
            } catch {
                print("Failed to save recent stop: \(error.localizedDescription)")
            }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.7)) {
                    selectedSheet = .busStopDetailView
                    showStopDetailSheet = true
                    selectionDetent = .medium
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showDefaultSheet = false
                    defaultPosition = .region(
                        MKCoordinateRegion(
                            center: stop.coordinate,
                            latitudinalMeters: 1000,
                            longitudinalMeters: 1000
                        )
                    )
                }
            }
        }
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
        .buttonStyle(DefaultButtonStyle())
        .tint(.primary)
        .padding(.horizontal)
    }
}
