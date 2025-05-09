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
        SearchBar(searchText: $searchText, busStops: $busStops, onCancel: onCancel)
        ScrollView {
            switch searchText {
            case "":
//                Text("Nearest Bus Stops...?")
//                Text("Still cooking... 🍳")
                Text("")

            default:
                VStack(spacing: 10) {
                    ForEach(busStops) { stop in
                        if stop.name.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                HStack {
                                    Image(systemName: "bus")
                                        .frame(width: 30, height: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(stop.name)
                                    }
                                    Spacer()
                                }
                                .padding(5)
                            }
                            .padding(.horizontal)
                            .onTapGesture {
                                selectedBusStop = stop
                                defaultPosition = .region(
                                    MKCoordinateRegion(
                                        center: stop.coordinate,
                                        latitudinalMeters: 1000,
                                        longitudinalMeters: 1000
                                    )
                                )

                                showDefaultSheet = false
                                withAnimation(.easeInOut(duration: 0.7)){
                                    selectedSheet = .busStopDetailView
                                    showStopDetailSheet = true
                                    selectionDetent = .medium
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
}
