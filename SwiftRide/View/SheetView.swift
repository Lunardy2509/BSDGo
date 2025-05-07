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

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var busStops: [BusStop]
    var onCancel: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search Bus Stop", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isTextFieldFocused)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .frame(height: 35)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if isTextFieldFocused || !searchText.isEmpty {
                    Button("Cancel") {
                        searchText = ""
                        isTextFieldFocused = false
                        onCancel()
                    }
                    .foregroundColor(.blue)
                    .padding(.leading, 4)
                    .transition(.move(edge: .trailing))
                    .animation(.default, value: searchText)
                }
            }
            .padding(.horizontal)
            .padding(.top, 25)
        }
    }
}


struct BusStopDetailView: View {
    @Binding var currentBusStop: BusStop
    @Binding var showRouteDetailSheet: Bool
    @Binding var showStopDetailSheet: Bool
    @Binding var selectedBusNumber: Int
    @Binding var selectedBusName: String
    @Binding var selectedSheet: SheetContentType

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

struct BusCard: View {
    @Binding var currentBusStop: BusStop
    @Binding var showRouteDetailSheet: Bool
    @Binding var selectedBusNumber: Int
    @Binding var selectedBusName: String
    @Binding var selectedSheet: SheetContentType
  
    @State var timerTick: Date = Date()

    private let buses: [Bus]

    init(currentBusStop: Binding<BusStop>, showRouteDetailSheet: Binding<Bool>, selectedBusNumber: Binding<Int>, selectedBusName: Binding<String>, selectedSheet: Binding<SheetContentType>) {
        self._currentBusStop = currentBusStop
        self._showRouteDetailSheet = showRouteDetailSheet
        self._selectedBusNumber = selectedBusNumber
        self._selectedBusName = selectedBusName
        self._selectedSheet = selectedSheet
        
        let rawBuses = loadBuses()
        let schedules = loadBusSchedules()
        self.buses = rawBuses.map { $0.assignSchedule(schedules: schedules) }
    }

    // Precomputed upcoming bus and ETA pairs
    private var upcomingBuses: [(bus: Bus, etaMinutes: Int)] {
        buses.compactMap { bus in
            guard let nextSchedule = nextSchedule(for: bus, now: timerTick),
                  let eta = bus.getClosestArrivalTime(from: nextSchedule.timeOfArrival) else {
                return nil
            }

            if eta <= 0 {
                return nil
            }
            return (bus, Int(eta / 60))
        }
        .sorted { $0.etaMinutes < $1.etaMinutes }
    }

    // Helper to get the next schedule for the current stop
    private func nextSchedule(for bus: Bus, now: Date) -> BusSchedule? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Safe default
        let calendar = Calendar.current

        let matchingSchedules = bus.schedule
            .filter { $0.busStopName == currentBusStop.name }
            .compactMap { schedule -> (BusSchedule, Date)? in
                guard let timeOnly = formatter.date(from: schedule.timeOfArrival) else {
                    return nil
                }

                // Merge "today" with the time from the schedule
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnly)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute

                guard let fullDate = calendar.date(from: components) else { return nil }

                return fullDate >= now ? (schedule, fullDate) : nil
            }
            .sorted { $0.1 < $1.1 }

        if let next = matchingSchedules.first?.0 { return next } else {
            return nil
        }
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if upcomingBuses.isEmpty {
                Text("No Bus Available For Now")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                ForEach(upcomingBuses, id: \.bus.id) { pair in
                    BusRow(bus: pair.bus, etaMinutes: pair.etaMinutes) { busNumber, busName in
                        selectedBusNumber = busNumber
                        selectedBusName = busName
                        UserDefaults.standard.set(currentBusStop.name, forKey: "userStopName")
                        selectedSheet = .routeDetailView
                        showRouteDetailSheet = true
                    }
                }
            }
        }
        .padding(.top, 0)
        .onAppear {
            if showRouteDetailSheet {
                selectedSheet = .routeDetailView
            }
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { now in
            timerTick = now
        }
    }
}

struct BusRow: View {
    let bus: Bus
    let etaMinutes: Int
    let onTap: (_ busNumber: Int, _ busName: String) -> Void
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
            HStack {
                Image(systemName: "bus")
                    .foregroundStyle(bus.color)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(bus.name)
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(Color(bus.color))
                    .cornerRadius(20)
                    .fixedSize()

                    Text("Will be arriving \(etaMinutes == 0 ? "soon" : "in \(etaMinutes) \(etaMinutes == 1 ? "minute" : "minutes" )")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap(bus.number, bus.name)
            }
        }
    }
}

struct TitleCard: View {
    @Binding var title: String
    
    var body: some View {
        Text(title)
            .font(.title.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}
