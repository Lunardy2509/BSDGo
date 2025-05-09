import MapKit
import SwiftUI

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
