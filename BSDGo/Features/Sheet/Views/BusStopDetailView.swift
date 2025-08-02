import SwiftUI
import MapKit

struct BusStopDetailView: View {
    @Binding var currentBusStop: BusStop
    @Binding var showRouteDetailSheet: Bool
    @Binding var showStopDetailSheet: Bool
    @Binding var selectedBusNumber: Int
    @Binding var selectedBusName: String
    @Binding var selectedSheet: SheetType

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                TitleCard(title: $currentBusStop.name)
                Spacer()
                Button {
                    selectedSheet = .defaultView
                    currentBusStop = BusStop()
                    showStopDetailSheet = false
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            Text("Available Buses")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            ScrollView {
                BusCard(
                    currentBusStop: $currentBusStop,
                    showRouteDetailSheet: $showRouteDetailSheet,
                    selectedBusNumber: $selectedBusNumber,
                    selectedBusName: $selectedBusName,
                    selectedSheet: $selectedSheet
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 0)
        }
        .padding(.top, 20)
    }
}
