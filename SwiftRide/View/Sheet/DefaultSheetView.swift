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
    
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(
                searchText: $searchText,
                busStops: $busStops,
                onCancel: onCancel
            )

            if filteredStops.isEmpty {
                Text("No matching bus stops.")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredStops, id: \.id) { stop in
                            BusStopRow(stop: stop) {
                                handleBusStopSelection(stop)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }

    private var filteredStops: [BusStop] {
        searchText.isEmpty
            ? busStops
            : busStops.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func handleBusStopSelection(_ stop: BusStop) {
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
}

private extension DefaultSheetView {
    struct BusStopRow: View {
        let stop: BusStop
        let onTap: () -> Void

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))

                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading) {
                        Text(stop.name)
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
